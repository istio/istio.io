---
title: 揭开 Istio Sidecar 注入模型的神秘面纱
description: 揭秘 Istio 是如何将其数据平面组件添加到现有 deployment。
publishdate: 2019-01-31
subtitle:
attribution: Manish Chugtu
twitter: chugtum
keywords: [kubernetes,sidecar-injection, traffic-management]
target_release: 1.0
---
Istio 服务网格体系结构的简单概述总是从控制平面和数据平面开始。

从 [Istio 的文档](/zh/docs/ops/deployment/architecture/) :

{{< quote >}}
Istio 服务网格在逻辑上分为数据平面和控制平面。

数据平面由一组部署为 sidecar 的智能代理（Envoy）组成。这些代理与 Mixer、通用策略和遥测中心协调并控制微服务之间的所有网络通信。

控制平面管理并配置从代理到路由的流量。此外，控制平面配置 Mixer 以执行策略和收集遥测数据。
{{< /quote >}}

{{< image width="40%"
    link="./arch-2.svg"
    alt="基于 Istio 的应用程序的总体架构。"
    caption="Istio Architecture"
    >}}

重要的是要理解向应用程序 pod 中注入边车是自动进行的，尽管也可以手动注入。流量从应用服务流向 sidecar，而开发人员无需关心它。一旦将应用程序连接到 Istio 服务网格，开发者便可以开始使用并获得服务网格中的所有效益。但是，数据平面管道是如何发生的，以及无缝迁移工作的真正要求是什么？在本文中，我们将深入研究 Sidecar 注入模型的细节，以非常清楚地理解 Sidecar 注入的工作原理。

## Sidecar 注入{#sidecar-injection}

简单来说，Sidecar 注入会将额外容器的配置添加到 Pod 模板中。Istio 服务网格目前所需的容器有：

`istio-init`
[init 容器](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/init-containers/) 用于设置 iptables 规则，以便将入站/出站流量通过 sidecar 代理。初始化容器与应用程序容器在以下方面有所不同：

- 它在启动应用容器之前运行，并一直运行直至完成。
- 如果有多个初始化容器，则每个容器都应在启动下一个容器之前成功完成。

因此，您可以看到，对于不需要成为实际应用容器一部分的设置或初始化作业来说，这种容器是多么的完美。在这种情况下，`istio-init` 就是这样做并设置了 `iptables` 规则。

`istio-proxy`
这个容器是真正的 sidecar 代理（基于 Envoy）。

### 手动注入{#manual-injection}

在手动注入方法中，可以使用 [`istioctl`](/zh/docs/reference/commands/istioctl) 修改容器模板并添加前面提到的两个容器的配置。不论是手动注入还是自动注入，Istio 都从 `istio-sidecar-injector` 和的 `istio` 两个 Configmap 对象中获取配置。

我们先来看看 `istio-sidecar-injector` Configmap 的配置，了解一下其中的内容。

{{< text bash yaml>}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}'
以下代码片段来自 output：

policy: enabled
template: |-
  initContainers:
  - name: istio-init
    image: docker.io/istio/proxy_init:1.0.2
    args:
    - "-p"
    - [[ .MeshConfig.ProxyListenPort ]]
    - "-u"
    - 1337
    .....
    imagePullPolicy: IfNotPresent
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
    restartPolicy: Always

  containers:
  - name: istio-proxy
    image: [[ if (isset .ObjectMeta.Annotations "sidecar.istio.io/proxyImage") -]]
    "[[ index .ObjectMeta.Annotations "sidecar.istio.io/proxyImage" ]]"
    [[ else -]]
    docker.io/istio/proxyv2:1.0.2
    [[ end -]]
    args:
    - proxy
    - sidecar
    .....
    env:
    .....
    - name: ISTIO_META_INTERCEPTION_MODE
      value: [[ or (index .ObjectMeta.Annotations "sidecar.istio.io/interceptionMode") .ProxyConfig.InterceptionMode.String ]]
    imagePullPolicy: IfNotPresent
    securityContext:
      readOnlyRootFilesystem: true
      [[ if eq (or (index .ObjectMeta.Annotations "sidecar.istio.io/interceptionMode") .ProxyConfig.InterceptionMode.String) "TPROXY" -]]
      capabilities:
        add:
        - NET_ADMIN
    restartPolicy: Always
    .....
{{< /text >}}

如您所见，configmap 包含了 `istio-init` 初始化容器和 `istio-proxy` 代理容器的配置。该配置包括容器镜像的名称以及拦截模式，权限要求等参数。

从安全的角度来看，重要的是要注意 `istio-init` 需要 `NET_ADMIN` 权限来修改 pod 命名空间中的 `iptables`，如果 `istio-proxy` 是 `TPROXY` 模式，也需要这一权限。由于该仅限于 pod 的命名空间，因此应该没有问题。但是，我们注意到最近的 open-shift 版本可能会出现一些问题，因此需要一种解决方法。本文结尾处提到了一个这样的选择。

要修改当前的 Pod 模板以进行 sidecar 注入，您可以：

{{< text bash >}}
$ istioctl kube-inject -f demo-red.yaml | kubectl apply -f -
{{< /text >}}

或者

要使用修改后的 Configmap 或本地 Configmap：

- 从 configmap 创建 `inject-config.yaml` 和 `mesh-config.yaml`

    {{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
    {{< /text >}}

- 修改现有的 pod 模板，在这个例子中是，`demo-red.yaml`：

    {{< text bash >}}
$ istioctl kube-inject --injectConfigFile inject-config.yaml --meshConfigFile mesh-config.yaml --filename demo-red.yaml --output demo-red-injected.yaml
    {{< /text >}}

- 提交 `demo-red-injected.yaml`

    {{< text bash >}}
$ kubectl apply -f demo-red-injected.yaml
    {{< /text >}}

如上所示，我们使用 `sidecar-injector` 和网格配置创建了一个新模板，然后使用 `kubectl` 应用该新模板。如果我们查看注入后的 YAML 文件，它具有 Istio 特定容器的配置，如上所述。一旦我们应用注入后的 YAML 文件，我们将看到两个容器正在运行。其中一个是实际的应用程序容器，另一个是 `istio-proxy` sidecar。

{{< text bash >}}
    $ kubectl get pods | grep demo-red
    demo-red-pod-8b5df99cc-pgnl7   2/2       Running   0          3d
{{< /text >}}

这里没有 3 个 Pod，因为 `istio-init` 容器是一个 init 类型的容器，它在完成应做的操作后退出，其用于在 pod 中设置 `iptable` 规则。为了确认 init 容器已退出，让我们看一下 `kubectl describe` 的输出：

{{< text bash yaml>}}
$ kubectl describe pod demo-red-pod-8b5df99cc-pgnl7
以下代码片段来自 output：

Name:               demo-red-pod-8b5df99cc-pgnl7
Namespace:          default
.....
Labels:             app=demo-red
                    pod-template-hash=8b5df99cc
                    version=version-red
Annotations:        sidecar.istio.io/status={"version":"3c0b8d11844e85232bc77ad85365487638ee3134c91edda28def191c086dc23e","initContainers":["istio-init"],"containers":["istio-proxy"],"volumes":["istio-envoy","istio-certs...
Status:             Running
IP:                 10.32.0.6
Controlled By:      ReplicaSet/demo-red-pod-8b5df99cc
Init Containers:
  istio-init:
    Container ID:  docker://bef731eae1eb3b6c9d926cacb497bb39a7d9796db49cd14a63014fc1a177d95b
    Image:         docker.io/istio/proxy_init:1.0.2
    Image ID:      docker-pullable://docker.io/istio/proxy_init@sha256:e16a0746f46cd45a9f63c27b9e09daff5432e33a2d80c8cc0956d7d63e2f9185
    .....
    State:          Terminated
      Reason:       Completed
    .....
    Ready:          True
Containers:
  demo-red:
    Container ID:   docker://8cd9957955ff7e534376eb6f28b56462099af6dfb8b9bc37aaf06e516175495e
    Image:          chugtum/blue-green-image:v3
    Image ID:       docker-pullable://docker.io/chugtum/blue-green-image@sha256:274756dbc215a6b2bd089c10de24fcece296f4c940067ac1a9b4aea67cf815db
    State:          Running
      Started:      Sun, 09 Dec 2018 18:12:31 -0800
    Ready:          True
  istio-proxy:
    Container ID:  docker://ca5d690be8cd6557419cc19ec4e76163c14aed2336eaad7ebf17dd46ca188b4a
    Image:         docker.io/istio/proxyv2:1.0.2
    Image ID:      docker-pullable://docker.io/istio/proxyv2@sha256:54e206530ba6ca9b3820254454e01b7592e9f986d27a5640b6c03704b3b68332
    Args:
      proxy
      sidecar
      .....
    State:          Running
      Started:      Sun, 09 Dec 2018 18:12:31 -0800
    Ready:          True
    .....
{{< /text >}}

从输出中可以看出，`istio-init` 容器的 `State` 为 `Terminated`，而 `Reason` 是 `Completed`。只有两个容器是运行的，主应用程序 `demo-red` 容器和 `istio-proxy` 容器。

### 自动注入{#automatic-injection}

在大多数情况下，您不想在每次部署应用程序时都使用 [`istioctl`](/zh/docs/reference/commands/istioctl) 命令手动注入边车，而是希望 Istio 自动将 sidecar 注入到您的 pod 中。这是推荐的方法，要使自动注入生效，您只需要用 `istio-injection=enabled` 标记想部署应用程序的命名空间。

贴上标签后，Istio 会自动为您在该命名空间中部署的所有 pod 注入 sidecar。下面的例子里，`istio-dev` 命名空间中部署的 pod 被自动注入了 sidecar：

{{< text bash >}}
$ kubectl get namespaces --show-labels
NAME           STATUS    AGE       LABELS
default        Active    40d       <none>
istio-dev      Active    19d       istio-injection=enabled
istio-system   Active    24d       <none>
kube-public    Active    40d       <none>
kube-system    Active    40d       <none>
{{< /text >}}

但它是如何工作的呢？要深入了解这一点，我们需要理解 Kubernetes 准入控制器。

[来自 Kubernetes 文档：](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/admission-controllers/)

{{< tip >}}
准入控制器是一段代码，用于在对象持久化之前但请求已经过身份验证和授权之后，拦截对 Kubernetes API 服务器的请求。您可以定义两种类型的 Admission Webhook：Validating 和 Mutating。Validating 类型的 Webhook 可以根据自定义的准入策略决定是否拒绝请求；Mutating 类型的 Webhook 可以根据自定义配置来对请求进行编辑。
{{< /tip >}}

对于 sidecar 自动注入，Istio 依赖于 `Mutating Admission Webhook`。让我们来看看 `istio-sidecar-injector` 中的配置详情。

{{< text bash yaml >}}
$ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml
以下代码片段来自 output：

apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"admissionregistration.k8s.io/v1beta1","kind":"MutatingWebhookConfiguration","metadata":{"annotations":{},"labels":{"app":"istio-sidecar-injector","chart":"sidecarInjectorWebhook-1.0.1","heritage":"Tiller","release":"istio-remote"},"name":"istio-sidecar-injector","namespace":""},"webhooks":[{"clientConfig":{"caBundle":"","service":{"name":"istio-sidecar-injector","namespace":"istio-system","path":"/inject"}},"failurePolicy":"Fail","name":"sidecar-injector.istio.io","namespaceSelector":{"matchLabels":{"istio-injection":"enabled"}},"rules":[{"apiGroups":[""],"apiVersions":["v1"],"operations":["CREATE"],"resources":["pods"]}]}]}
  creationTimestamp: 2018-12-10T08:40:15Z
  generation: 2
  labels:
    app: istio-sidecar-injector
    chart: sidecarInjectorWebhook-1.0.1
    heritage: Tiller
    release: istio-remote
  name: istio-sidecar-injector
  .....
webhooks:
- clientConfig:
    service:
      name: istio-sidecar-injector
      namespace: istio-system
      path: /inject
  name: sidecar-injector.istio.io
  namespaceSelector:
    matchLabels:
      istio-injection: enabled
  rules:
  - apiGroups:
    - ""
    apiVersions:
    - v1
    operations:
    - CREATE
    resources:
    - pods
{{< /text >}}

在这里，您可以看到与标签 `istio-injection:enabled` 相匹配的 webhook `namespaceSelector` 标签。在这种情况下，您还会看到在创建容器时要完成的操作和资源。当 `apiserver` 接收到与其中一个规则匹配的请求时，`apiserver` 会根据 `clientconfig` 配置中指定的 `name: istio-sidecar-injector` 键值对，向 webhook 服务发送准入审查请求。我们应该能够看到该服务正在 `istio-system` 命名空间中运行。

{{< text bash >}}
$ kubectl get svc --namespace=istio-system | grep sidecar-injector
istio-sidecar-injector   ClusterIP   10.102.70.184   <none>        443/TCP             24d
{{< /text >}}

最终，该配置与手动注入中的配置几乎相同。只是它是在 pod 创建过程中自动完成的，因此您不会看到部署中的更改。您需要使用 `kubectl describe` 来查看 sidecar 代理和 init 代理。

sidecar 自动注入不仅取决于 webhook 的 `namespaceSelector` 机制，还取决于默认注入策略和每个 pod 自身注解。

如果你再次查看 `istio-sidecar-injector` ConfigMap，它将定义默认的注入策略。在这个示例中，它是默认启用的。

{{< text bash yaml>}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}'
以下代码片段来自 output：

policy: enabled
template: |-
  initContainers:
  - name: istio-init
    image: "gcr.io/istio-release/proxy_init:1.0.2"
    args:
    - "-p"
    - [[ .MeshConfig.ProxyListenPort ]]
{{< /text >}}

您还可以在 pod 模板中使用注解 `sidecar.istio.io/inject` 覆盖默认策略。以下示例展示如何为 `Deployment` 中的 pod 禁用 sidecar 自动注入。

{{< text yaml>}}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ignored
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - name: ignored
        image: tutum/curl
        command: ["/bin/sleep","infinity"]

{{< /text >}}

此示例显示了许多变量，这取决于是否在命名空间、ConfigMap 和 pod 中控制 sidecar 自动注入，它们是：

- webhook `namespaceSelector`（`istio-injection: enabled`）
- 默认策略（在 ConfigMap `istio-sidecar-injector` 中配置）
- 每个 pod 的重载注解（`sidecar.istio.io/inject`）

[注入状态表](/zh/docs/ops/common-problems/injection/)根据上述变量的值清晰显示了最终注入状态。

## 从应用容器到 Sidecar 代理的流量{#traffic-flow-from-application-container-to-sidecar-proxy}

既然我们已经清楚了如何将 sidecar 容器和 init 容器注入到应用清单中，那么 sidecar 代理如何捕获容器之间的入站和出站流量？我们曾简要提到过，这是通过在 pod 命名空间中设置 `iptable` 规则来完成的，而规则又是由 `istio-init` 容器完成的。现在，是时候验证命名空间中实际更新的内容了。

让我们进入上一节中部署的应用程序 pod 命名空间，并查看已配置的 iptables。我们将展示一个使用 `nsenter` 的例子。或者，您也可以通过特权模式进入容器并查看相同的信息。对于无法访问节点的人来说，使用 `exec` 进入 sidecar 并运行 `iptables` 更实用。

{{< text bash >}}
$ docker inspect b8de099d3510 --format '{{ .State.Pid }}'
4125
{{< /text  >}}

{{< text bash >}}
$ nsenter -t 4215 -n iptables -t nat -S
-P PREROUTING ACCEPT
-P INPUT ACCEPT
-P OUTPUT ACCEPT
-P POSTROUTING ACCEPT
-N ISTIO_INBOUND
-N ISTIO_IN_REDIRECT
-N ISTIO_OUTPUT
-N ISTIO_REDIRECT
-A PREROUTING -p tcp -j ISTIO_INBOUND
-A OUTPUT -p tcp -j ISTIO_OUTPUT
-A ISTIO_INBOUND -p tcp -m tcp --dport 80 -j ISTIO_IN_REDIRECT
-A ISTIO_IN_REDIRECT -p tcp -j REDIRECT --to-ports 15001
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -j ISTIO_REDIRECT
-A ISTIO_OUTPUT -m owner --uid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -m owner --gid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
-A ISTIO_REDIRECT -p tcp -j REDIRECT --to-ports 15001
{{< /text >}}

上面的输出清楚地表明，端口 80 的所有入站流量（即我们的 `red-demo` 应用正在监听的端口）现在已被 `REDIRECTED` 到端口 15001，即 `istio-proxy` 的端口，一个 Envoy 代理正在监听的端口。对于出站流量也是如此。

本文已经快结束了。我们希望本文有助于您弄清 Istio 是如何将 Sidecar 代理注入到现有部署中以及 Istio 是如何将流量路由到代理。

{{< idea >}}
更新：现在似乎可以选择使用新的 CNI 来代替 `istio-init`，其移除了对 init 容器和相关特权的要求。[`istio-cni`](https://github.com/istio/cni) 插件设置了 pod 的网络来满足此要求，以代替 Istio 当前通过 `istio-init` 注入 pod 的方法。
{{< /idea >}}

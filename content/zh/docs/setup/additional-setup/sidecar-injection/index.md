---
title: 设置 Sidecar
description: 在应用程序 Pod 中使用 sidecar injector webhook 自动安装或使用 istioctl CLI 手动安装 Istio sidecar。
weight: 45
keywords: [kubernetes,sidecar,sidecar-injection]
aliases:
    - /zh/docs/setup/kubernetes/automatic-sidecar-inject.html
    - /zh/docs/setup/kubernetes/sidecar-injection/
    - /zh/docs/setup/kubernetes/additional-setup/sidecar-injection/
---

## 注入{#injection}

为了充分利用 Istio 的所有特性，网格中的 pod 必须运行一个 Istio sidecar 代理。

下面的章节描述了向 pod 中注入 Istio sidecar 的两种方法：使用 [`istioctl`](/zh/docs/reference/commands/istioctl) 手动注入或使用 Istio sidecar 注入器自动注入。

手动注入直接修改配置，如 deployment，并将代理配置注入其中。

使用准入控制器在 pod 创建时自动注入。

通过应用 `istio-sidecar-injector` ConfigMap 中定义的模版进行注入。

### 手动注入 sidecar{#manual-sidecar-injection}

要手动注入 deployment，请使用 [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject)：

{{< text bash >}}
$ istioctl kube-inject -f @samples/sleep/sleep.yaml@ | kubectl apply -f -
{{< /text >}}

默认情况下将使用集群内的配置，或者使用该配置的本地副本来完成注入。

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.values}' > inject-values.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
{{< /text >}}

指定输入文件，运行 `kube-inject` 并部署。

{{< text bash >}}
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --valuesFile inject-values.yaml \
    --filename @samples/sleep/sleep.yaml@ \
    | kubectl apply -f -
{{< /text >}}

验证 sidecar 已经被注入到 READY 列下 `2/2` 的 sleep pod 中。

{{< text bash >}}
$ kubectl get pod  -l app=sleep
NAME                     READY   STATUS    RESTARTS   AGE
sleep-64c6f57bc8-f5n4x   2/2     Running   0          24s
{{< /text >}}

### 自动注入 sidecar{#automatic-sidecar-injection}

使用 Istio 提供的[准入控制器变更 webhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)，可以将 sidecar 自动添加到可用的 Kubernetes pod 中。

{{< tip >}}
虽然准入控制器默认情况下是启动的，但一些 Kubernetes 发行版会禁用他们。如果出现这种情况，根据说明来[启用准入控制器](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#how-do-i-turn-on-an-admission-controller)。
{{< /tip >}}

当注入 webhook 被启用后，任何新的 pod 都有将在创建时自动添加 sidecar。

请注意，区别于手动注入，自动注入发生在 pod 层面。你将看不到 deployment 本身有任何更改。取而代之，需要检查单独的 pod（使用 `kubectl describe`）来查询被注入的代理。

#### 禁用或更新注入 webhook{#disabling-or-updating-the-webhook}

Sidecar 注入 webhook 是默认启用的。如果你希望禁用 webhook，可以使用 [Helm](/zh/docs/setup/install/helm/) 将 `sidecarInjectorWebhook.enabled` 设置为 `false`。

还有很多[其他选项](/zh/docs/reference/config/installation-options/#sidecar-injector-webhook-options)可以配置。

#### 部署应用{#deploying-an-app}

部署 sleep 应用。验证 deployment 和 pod 只有一个容器。

{{< text bash >}}
$ kubectl apply -f @samples/sleep/sleep.yaml@
$ kubectl get deployment -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES       SELECTOR
sleep     1         1         1            1           12m       sleep        tutum/curl   app=sleep
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Running       0          4
{{< /text >}}

将 `default` namespace 标记为 `istio-injection=enabled`。

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl get namespace -L istio-injection
NAME           STATUS    AGE       ISTIO-INJECTION
default        Active    1h        enabled
istio-system   Active    1h
kube-public    Active    1h
kube-system    Active    1h
{{< /text >}}

注入发生在 pod 创建时。杀死正在运行的 pod 并验证新创建的 pod 是否注入 sidecar。原来的 pod 具有 READY 为 1&#47;1 的容器，注入 sidecar 后的 pod 则具有 READY 为 2&#47;2 的容器。

{{< text bash >}}
$ kubectl delete pod -l app=sleep
$ kubectl get pod -l app=sleep
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Terminating   0          1m
sleep-776b7bcdcd-bhn9m   2/2       Running       0          7s
{{< /text >}}

查看已注入 pod 的详细状态。你应该看到被注入的 `istio-proxy` 容器和对应的卷。请确保使用状态为 `Running` pod 的名称替换以下命令。

{{< text bash >}}
$ kubectl describe pod -l app=sleep
{{< /text >}}

禁用 `default` namespace 注入，并确认新的 pod 在创建时没有 sidecar。

{{< text bash >}}
$ kubectl label namespace default istio-injection-
$ kubectl delete pod -l app=sleep
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-bhn9m   2/2       Terminating   0          2m
sleep-776b7bcdcd-gmvnr   1/1       Running       0          2s
{{< /text >}}

#### 理解原理{#understanding-what-happened}

当 Kubernetes 调用 webhook 时，[`admissionregistration`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#mutatingwebhookconfiguration-v1beta1-admissionregistration-k8s-io) 配置被应用。默认配置将 sidecar 注入到所有拥有 `istio-injection=enabled` 标签的 namespace 下的 pod 中。 `istio-sidecar-injector` 配置字典指定了注入 sidecar 的配置。如需更改指定哪些 namespace 被注入，你可以使用以下命令编辑 `MutatingWebhookConfiguration`：

{{< text bash >}}
$ kubectl edit mutatingwebhookconfiguration istio-sidecar-injector
{{< /text >}}

{{< warning >}}
修改 `MutatingWebhookConfiguration` 之后，您应该重启 sidecar 注入器的 pod。
{{< /warning >}}

例如，你可以修改 `MutatingWebhookConfiguration` 使 sidecar 注入到所有不具有某个标签的 namespace 中。编辑这项配置是更高阶的操作。更多有关信息，请参考 Kubernetes 的 [`MutatingWebhookConfiguration` API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10/#mutatingwebhookconfiguration-v1beta1-admissionregistration-k8s-io) 文档。

##### _**策略**_{#policy}

`disabled` - 默认情况下不会将 sidecar 注入到 pod 中。在 pod 模板规范中添加 `sidecar.istio.io/inject` 的值为 true 来覆盖默认值并启用注入。

`enabled` - Sidecar 将默认注入到 pod 中。在 pod 模板规范中添加 `sidecar.istio.io/inject` 的值为 false 来覆盖默认值并禁用注入。

下面的示例使用 `sidecar.istio.io/inject` 注解来禁用 sidecar 注入。

{{< text yaml >}}
apiVersion: apps/v1
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

##### _**模版**_{#template}

Sidecar 注入模板使用 [https://golang.org/pkg/text/template](https://golang.org/pkg/text/template)，当解析和执行时，将解码成下面的结构体，包含需要注入到 pod 中的容器和卷。

{{< text go >}}
type SidecarInjectionSpec struct {
      RewriteAppHTTPProbe bool                          `yaml:"rewriteAppHTTPProbe"`
      InitContainers      []corev1.Container            `yaml:"initContainers"`
      Containers          []corev1.Container            `yaml:"containers"`
      Volumes             []corev1.Volume               `yaml:"volumes"`
      DNSConfig           *corev1.PodDNSConfig          `yaml:"dnsConfig"`
      ImagePullSecrets    []corev1.LocalObjectReference `yaml:"imagePullSecrets"`
}
{{< /text >}}

该模板在运行时应用于以下数据结构。

{{< text go >}}
type SidecarTemplateData struct {
    DeploymentMeta *metav1.ObjectMeta
    ObjectMeta     *metav1.ObjectMeta
    Spec           *corev1.PodSpec
    ProxyConfig    *meshconfig.ProxyConfig  // Defined by https://istio.io/docs/reference/config/service-mesh.html#proxyconfig
    MeshConfig     *meshconfig.MeshConfig   // Defined by https://istio.io/docs/reference/config/service-mesh.html#meshconfig
}
{{< /text >}}

`ObjectMeta` 和 `Spec` 来源于 pod。 `ProxyConfig` 和 `MeshConfig` 来源于 `istio-system` namespace 下 `istio` 的 ConfigMap。模版可以使用这些数据有条件地定义被注入的卷和容器。

例如下面的模版。

{{< text plain >}}
containers:
- name: istio-proxy
  image: istio.io/proxy:0.5.0
  args:
  - proxy
  - sidecar
  - --configPath
  - {{ .ProxyConfig.ConfigPath }}
  - --binaryPath
  - {{ .ProxyConfig.BinaryPath }}
  - --serviceCluster
  {{ if ne "" (index .ObjectMeta.Labels "app") -}}
  - {{ index .ObjectMeta.Labels "app" }}
  {{ else -}}
  - "istio-proxy"
  {{ end -}}
{{< /text >}}

将在使用模版 [`samples/sleep/sleep.yaml`]({{< github_tree >}}/samples/sleep/sleep.yaml) 定义的 pod 被应用时变为

{{< text yaml >}}
containers:
- name: istio-proxy
  image: istio.io/proxy:0.5.0
  args:
  - proxy
  - sidecar
  - --configPath
  - /etc/istio/proxy
  - --binaryPath
  - /usr/local/bin/envoy
  - --serviceCluster
  - sleep
{{< /text >}}

#### 更多控制：添加例外{#more-control-adding-exceptions}

有些情况下用户无法控制 pod 的创建，例如，这些用户是被其他人创建的。因此他们无法在 pod 中添加 `sidecar.istio.io/inject` 注解，来明确是否安装 sidecar。

考虑在部署应用程序时创建辅助 pod 作为中间步骤。例如 [OpenShift Builds](https://docs.okd.io/latest/dev_guide/builds/index.html)，创建这样的 pod 用于构建应用程序的源代码。构建二进制工件后，应用程序 pod 就可以运行了，而用于辅助的 pod 则被丢弃。这些中间 pod 不应该有 Istio sidecar，即使策略被设置为 `enabled`，并且名称空间被正确标记为自动注入。

对于这种情况，你可以根据 pod 上的标签，指示 Istio **不要**在那些 pod 中注入 sidecar。可以通过编辑 `istio-sidecar-injector` 的 ConfigMap 并添加 `neverInjectSelector` 条目来实现。它是一个 Kubernetes 标签选择器数组，使用 `OR'd`，在第一次匹配成功后则停止。看一个例子：

{{< text yaml >}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio-sidecar-injector
data:
  config: |-
    policy: enabled
    neverInjectSelector:
      - matchExpressions:
        - {key: openshift.io/build.name, operator: Exists}
      - matchExpressions:
        - {key: openshift.io/deployer-pod-for.name, operator: Exists}
    template: |-
      initContainers:
...
{{< /text >}}

上面声明的意思是：永远不要注入带有 `openshift.io/build.name` **或者** `openshift.io/deployer-pod-for.name` 标签的 pod —— 标签的值无关紧要，我们只检查键是否存在。添加了这个规则之后，就涵盖了上面所说的 OpenShift 的构建用例，也就是说辅助 pod 不会被注入 sidecar（因为 source-to-image 工具产生的辅助 pod **明确**包含这些标签）。

完整起见，您还可以使用一个名为 `alwaysInjectSelector` 的字段，它具有类似的语法，总是将 sidecar 注入匹配标签选择器的 pod 中，而忽略全局策略。

使用标签选择器的方法在表达这些例外时提供了很大的灵活性。查看[这些文档](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#resources-that-support-set-based-requirements)看看可以用它们来做什么！

{{< tip >}}
值得注意的是，pod 中的注解具有比标签选择器更高的优先级。如果一个 pod 有 `sidecar.istio.io/inject: "true/false"` 的标记那么它将先被履行。因此，优先级的顺序为:

`Pod Annotations → NeverInjectSelector → AlwaysInjectSelector → Default Policy`
{{< /tip >}}

#### 卸载 sidecar 自动注入器{#uninstalling-the-automatic-sidecar-injector}

{{< text bash >}}
$ kubectl delete mutatingwebhookconfiguration istio-sidecar-injector
$ kubectl -n istio-system delete service istio-sidecar-injector
$ kubectl -n istio-system delete deployment istio-sidecar-injector
$ kubectl -n istio-system delete serviceaccount istio-sidecar-injector-service-account
$ kubectl delete clusterrole istio-sidecar-injector-istio-system
$ kubectl delete clusterrolebinding istio-sidecar-injector-admin-role-binding-istio-system
{{< /text >}}

上面的命令不会从 pod 中移除注入的 sidecar。需要进行滚动更新或者直接删除 pod，并强制 deployment 创建它们。

此外，还可以清理在此任务中修改过的其他资源。

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}

---
title: 安装 Sidecar
description: 在应用程序 Pod 中使用 Sidecar Injector Webhook 自动安装或使用 Istioctl CLI 手动安装 Istio Sidecar。
weight: 45
keywords: [kubernetes,sidecar,sidecar-injection]
aliases:
    - /zh/docs/setup/kubernetes/automatic-sidecar-inject.html
    - /zh/docs/setup/kubernetes/sidecar-injection/
    - /zh/docs/setup/kubernetes/additional-setup/sidecar-injection/
owner: istio/wg-environments-maintainers
test: no
---

## 注入{#injection}

为了充分利用 Istio 的所有特性，网格中的 Pod 必须运行一个 Istio Sidecar 代理。

下面的章节描述了向 Pod 中注入 Istio Sidecar 的两种方法：使用 [`istioctl`](/zh/docs/reference/commands/istioctl) 手动注入或启用 Pod 所属命名空间的 Istio sidecar 注入器自动注入。

当 Pod 所属命名空间启用自动注入后，自动注入器会使用准入控制器在创建 Pod 时自动注入代理配置。

手动注入直接修改配置，如 Deployment，并将代理配置注入其中。

如果您不确定使用哪一种方法，建议使用自动注入。

### 自动注入 Sidecar{#automatic-sidecar-injection}

使用 Istio 提供的[准入控制器变更 Webhook](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/admission-controllers/)，可以将 Sidecar 自动添加到可用的 Kubernetes Pod 中。

{{< tip >}}
虽然准入控制器默认情况下是启用的，但一些 Kubernetes 发行版会禁用这些控制器。
如果出现这种情况，根据指示说明来[启用准入控制器](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/admission-controllers/#how-do-i-turn-on-an-admission-controller)。
{{< /tip >}}

当您在一个命名空间中设置了 `istio-injection=enabled` 标签，且 Injection webhook 被启用后，任何新的 Pod 都有将在创建时自动添加 Sidecar。

请注意，区别于手动注入，自动注入发生在 Pod 层面。您将看不到 Deployment 本身有任何更改。取而代之，需要检查单独的 Pod（使用 `kubectl describe`）来查询被注入的代理。

#### 部署应用{#deploying-an-app}

部署 sleep 应用。验证 Deployment 和 Pod 只有一个容器。

{{< text bash >}}
$ kubectl apply -f @samples/sleep/sleep.yaml@
$ kubectl get deployment -o wide
NAME    READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
sleep   1/1     1            1           12s   sleep        curlimages/curl           app=sleep
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                    READY   STATUS    RESTARTS   AGE
sleep-8f795f47d-hdcgs   1/1     Running   0          42s
{{< /text >}}

将 `default` 命名空间标记为 `istio-injection=enabled`。

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled --overwrite
$ kubectl get namespace -L istio-injection
NAME                 STATUS   AGE     ISTIO-INJECTION
default              Active   5m9s    enabled
...
{{< /text >}}

注入发生在 Pod 创建时。杀死正在运行的 Pod 并验证新创建的 Pod 是否注入 Sidecar。
原来的 Pod 具有 `1/1 READY` 个容器，注入 Sidecar 后的 Pod 则具有 READY 为 `2/2 READY` 个容器。

{{< text bash >}}
$ kubectl delete pod -l app=sleep
$ kubectl get pod -l app=sleep
pod "sleep-776b7bcdcd-7hpnk" deleted
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Terminating   0          1m
sleep-776b7bcdcd-bhn9m   2/2       Running       0          7s
{{< /text >}}

查看已注入 Pod 的详细状态。您应该看到被注入的 `istio-proxy` 容器和对应的卷。

{{< text bash >}}
$ kubectl describe pod -l app=sleep
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  ...
  Normal  Created    11s   kubelet            Created container istio-init
  Normal  Started    11s   kubelet            Started container istio-init
  ...
  Normal  Created    10s   kubelet            Created container sleep
  Normal  Started    10s   kubelet            Started container sleep
  ...
  Normal  Created    9s    kubelet            Created container istio-proxy
  Normal  Started    8s    kubelet            Started container istio-proxy
{{< /text >}}

禁用 `default` 命名空间的注入，并确认新的 Pod 在创建时没有 Sidecar。

{{< text bash >}}
$ kubectl label namespace default istio-injection-
$ kubectl delete pod -l app=sleep
$ kubectl get pod
namespace/default labeled
pod "sleep-776b7bcdcd-bhn9m" deleted
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-bhn9m   2/2       Terminating   0          2m
sleep-776b7bcdcd-gmvnr   1/1       Running       0          2s
{{< /text >}}

#### 控制注入策略{#controlling-the-injection-policy}

在上面例子中，您在命名空间层级启用和禁用了注入。
注入也可以通过配置 Pod 上的 `sidecar.istio.io/inject` 标签，在每个 Pod 的基础上进行控制。

| 资源 | 标签 | 启用的值 | 禁用的值 |
| -------- | ----- | ------------- | -------------- |
| Namespace | `istio-injection` | `enabled` | `disabled` |
| Pod | `sidecar.istio.io/inject` | `"true"` | `"false"` |

如果您正在使用[控制平面修订版](/zh/docs/setup/upgrade/canary/)，将通过匹配 `istio.io/rev` 标签来转为使用特定修订版的标签。
例如，对于名为 `canary` 的修订版：

| 资源 | 启用的标签 | 禁用的标签 |
| -------- | ------------- | -------------- |
| Namespace | `istio.io/rev=canary` | `istio-injection=disabled` |
| Pod | `istio.io/rev=canary` | `sidecar.istio.io/inject="false"` |

如果 `istio-injection` 标签和 `istio.io/rev` 标签在同一个命名空间中，则优先使用 `istio-injection` 标签。

按照以下逻辑配置注入器：

1. 如果禁用其中一个标签，则不注入 Pod
1. 如果启用其中一个标签，则注入 Pod
1. 如果两个标签都没有设置，且启用了 `.values.sidecarInjectorWebhook.enableNamespacesByDefault`，则会注入 Pod。这在默认情况下是不启用的，所以 Pod 通常不会被注入。

### 手动注入 Sidecar{#manual-sidecar-injection}

要手动注入 Deployment，请使用 [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject)：

{{< text bash >}}
$ istioctl kube-inject -f @samples/sleep/sleep.yaml@ | kubectl apply -f -
serviceaccount/sleep created
service/sleep created
deployment.apps/sleep created
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
serviceaccount/sleep created
service/sleep created
deployment.apps/sleep created
{{< /text >}}

验证 Sidecar 是否已经被注入到 READY 列下 `2/2` 的 Sleep Pod 中。

{{< text bash >}}
$ kubectl get pod  -l app=sleep
NAME                     READY   STATUS    RESTARTS   AGE
sleep-64c6f57bc8-f5n4x   2/2     Running   0          24s
{{< /text >}}

## 自定义注入{#customizing-injection}

通常，Pod 的注入是基于 Sidecar 注入模板，在 `istio-sidecar-injector` Configmap 中配置。每个 Pod 的配置可用于覆盖各个 Pod 上的选项。可通过在 Pod 中添加一个 `istio-proxy` 容器来完成。Sidecar 注入将会把自定义的任何配置视为默认注入模板的覆盖。

自定义这些设置时，需格外小心，因为允许完全自定义生成的 Pod，包括进行一些更改而导致 Sidecar 容器无法正常运行。

例如，以下配置可自定义各种设置，包括降低 CPU 请求，添加 Volume 挂载，和添加 `preStop` Hook：

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
  containers:
  - name: hello
    image: alpine
  - name: istio-proxy
    image: auto
    resources:
      requests:
        cpu: "100m"
    volumeMounts:
    - mountPath: /etc/certs
      name: certs
    lifecycle:
      preStop:
        exec:
          command: ["sleep", "10"]
  volumes:
  - name: certs
    secret:
      secretName: istio-certs
{{< /text >}}

通常，可以设置 Pod 中的任何字段。但是必须注意某些字段：

* Kubernetes 要求在注入运行之前配置 `image`。虽然可以您可以设置一个指定的 Image 来覆盖默认的 `image` 配置，但建议将 `image` 设置为 `auto`，可使 Sidecar 注入自动选择要使用的 Image。

* `Pod` 中一些字段取决于相关设置。例如，CPU 请求必须小于 CPU 限制。如果两个字段没有一起配置， Pod 可能会无法启动。

另外，某些字段可通过在 Pod 上的[注解](/zh/docs/reference/config/annotations/)进行配置，但是不建议使用上述方法进行自定义设置。必须特别注意某些注解：

* 如果设置了 `sidecar.istio.io/proxyCPU`，则务必显式设置 `sidecar.istio.io/proxyCPULimit`。否则该 Sidecar 的 `cpu` 限制将被设置为 unlimited。

* 如果设置了 `sidecar.istio.io/proxyMemory`，则务必显式设置 `sidecar.istio.io/proxyMemoryLimit`。否则该 Sidecar 的 `memory` 限制将被设置为 unlimited。

例如，参见以下不完整的资源注解配置和相应注入的资源设置：

{{< text yaml >}}
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/proxyCPU: "200m"
        sidecar.istio.io/proxyMemoryLimit: "5Gi"
{{< /text >}}

{{< text yaml >}}
spec:
  containers:
  - name: istio-proxy
    resources:
      limits:
        memory: 5Gi
      requests:
        cpu: 200m
        memory: 5Gi
      securityContext:
        allowPrivilegeEscalation: false
{{< /text >}}

### 自定义模板（试验特性）{#custom-templates-experimental}

{{< warning >}}
此功能为试验特性功能，可随时更改或删除。
{{< /warning >}}

可以在安装时定义一个完全自定义的模板。
例如，定义一个自定义模板，将 `GREETING` 环境变量注入到 `istio-proxy` 容器中：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
spec:
  values:
    sidecarInjectorWebhook:
      templates:
        custom: |
          spec:
            containers:
            - name: istio-proxy
              env:
              - name: GREETING
                value: hello-world
{{< /text >}}

默认情况下，`istio` 会使用自动创建的 `sidecar` 模板对 Pod 进行注入。
这可通过 `inject.istio.io/templates` 注解来替换。
例如要应用默认模板和自定义模板，您可以设置 `inject.istio.io/templates=sidecar,custom`。

除了 `sidecar` 之外，默认还会提供 `gateway` 模板以支持将代理注入到 Gateway Deployment 中。

---
title: 注入 Istio sidecar
description: 介绍两种将 Istio sidecar 注入应用 Pod 的方法：使用 Sidecar 注入 Webhook 自动完成，或使用 istioctl 客户端工具手工完成。
weight: 50
keywords: [kubernetes,sidecar,sidecar-injection]
---

## 对 Pod 的要求

要成为服务网格的一部分，Kubernetes 集群中的每个 Pod 都必须满足如下要求：

1. **具备关联服务**：Pod 必须属于**单一的** [Kubernetes 服务](https://kubernetes.io/docs/concepts/services-networking/service/)，Istio 目前还不支持一个 Pod 对应多个服务的情况。

1. **需要给端口正确命名**：服务端口必须进行命名。端口名称只允许是`<协议>[-<后缀>-]`模式，其中`<协议>`部分可选择范围包括 `http`、`http2`、`grpc`、`mongo` 以及 `redis`，Istio 可以通过对这些协议的支持来提供路由能力。例如 `name: http2-foo` 和 `name: http` 都是有效的端口名，但 `name: http2foo` 就是无效的。如果没有给端口进行命名，或者命名没有使用指定前缀，那么这一端口的流量就会被视为普通 TCP 流量（除非显式的用 `Protocol: UDP` 声明该端口是 UDP 端口）。

1. **Deployment 应带有 `app` 标签**：在使用 Kubernetes `Deployment` 进行 Pod 部署的时候，建议显式的为 Deployment 加上 `app` 标签。每个 Deployment 都应该有一个有意义的 `app` 标签。`app` 标签在分布式跟踪的过程中会被用来加入上下文信息。

1. **网格中的每个 Pod 都应该带有 Sidecar**：最后，网格中的每个 Pod 都必须运行有一个 Istio 兼容的 Sidecar。后续内容中将会描述两种将 Sidecar 注入 Pod 中的方式：使用 `istioctl` 客户端工具手工注入；或者使用 Istio sidecar 注入器进行自动注入。注意，同一 Pod 内不同容器之间的通信是不受 Sidecar 支持的。

## 注入

手工注入过程会修改控制器（例如 Deployment）的配置。这种注入方法通过修改 Pod template 的手段，把 Sidecar 注入到目标控制器生成的所有 Pod 之中。要加入、更新或者移除 Sidecar，就需要修改整个控制器。

自动注入过程会在 Pod 的生成过程中进行注入，这种方法不会更改控制器的配置。手工删除 Pod 或者使用滚动更新都可以选择性的对 Sidecar 进行更新。

手工或自动注入都会从 `istio-system` 命名空间的 `istio-sidecar-injector` 以及 `istio` ConfigMap 中获取配置信息。手工注入方式还可以从本地文件中读取配置。

### 手工注入 Sidecar

使用集群内置配置将 Sidecar 注入到 Deployment 中：

{{< text bash >}}
$ istioctl kube-inject -f @samples/sleep/sleep.yaml@ | kubectl apply -f -
{{< /text >}}

此外还可以使用本地的配置信息来进行注入。

> `kube-inject` 操作不具备幂等性，因此 `istioctl kube-inject` 的输出内容是无法再次进行注入的。要进行更新的话，建议保留原本的未经注入的 `yaml` 文件，这样数据平面的 Sidecar 就可以被更新了。

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
{{< /text >}}

对输入文件运行 `kube-inject`，并进行部署：

{{< text bash >}}
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --filename samples/sleep/sleep.yaml \
    --output sleep-injected.yaml | kubectl apply -f -
{{< /text >}}

检查被注入到 Deployment 中的 Sidecar：

{{< text bash >}}
$ kubectl get deployment sleep -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS          IMAGES                             SELECTOR
sleep     1         1         1            1           2h        sleep,istio-proxy   tutum/curl,unknown/proxy:unknown   app=sleep
{{< /text >}}

### Sidecar 的自动注入

使用 Kubernetes 的 [mutating webhook admission controller](https://kubernetes.io/docs/admin/admission-controllers/)，可以进行 Sidecar 的自动注入。Kubernetes 1.9 以后的版本才具备这一能力。使用这一功能之前首先要检查 kube-apiserver 的进程，是否具备 `admission-control` 参数，并且这个参数的值中需要包含 `MutatingAdmissionWebhook` 以及 `ValidatingAdmissionWebhook` 两项，并且按照正确的顺序加载，这样才能启用 `admissionregistration` API：

{{< text bash >}}
$ kubectl api-versions | grep admissionregistration
admissionregistration.k8s.io/v1alpha1
admissionregistration.k8s.io/v1beta1
{{< /text >}}

在 [Kubernetes 快速开始](/zh/docs/setup/kubernetes/quick-start/) 中介绍了 Kubernetes 1.9 以上版本的安装。

注意，跟手工注入不同的是，自动注入过程是发生在 Pod 级别的。因此是不会看到 Deployment 本身发生什么变化的。但是可以使用 `kubectl describe` 来观察单独的 Pod，在其中能看到注入 Sidecar 的相关信息。

#### Webhook 的禁用或升级

缺省情况下，用于 Sidecar 注入的 Webhook 是启用的。如果想要禁用它，可以用 [Helm](/zh/docs/setup/kubernetes/helm-install/) ，将 `sidecarInjectorWebhook.enabled` 参数设为 `false`，生成一个 `istio.yaml` 进行更新。也就是：

{{< text bash >}}
$ helm template --namespace=istio-system --set sidecarInjectorWebhook.enabled=false install/kubernetes/helm/istio > istio.yaml
$ kubectl create ns istio-system
$ kubectl apply -n istio-system -f istio.yaml
{{< /text >}}

另外这个 Webhook 在 `values.yaml` 中还有一些其他的配置参数。可以覆盖这些缺省值来对安装过程进行定义。

#### 应用部署

部署 `sleep` 应用，检查一下是不是只产生了一个容器。

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml
$ kubectl get deployment -o wide
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES       SELECTOR
sleep     1         1         1            1           12m       sleep        tutum/curl   app=sleep
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Running       0          4
{{< /text >}}

给 `default` 命名空间设置标签：`istio-injection=enabled`：

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl get namespace -L istio-injection
NAME           STATUS    AGE       ISTIO-INJECTION
default        Active    1h        enabled
istio-system   Active    1h
kube-public    Active    1h
kube-system    Active    1h
{{< /text >}}

这样就会在 Pod 创建时触发 Sidecar 的注入过程了。删掉运行的 Pod，会产生一个新的 Pod，新 Pod 会被注入 Sidecar。原有的 Pod 只有一个容器，而被注入 Sidecar 的 Pod 会有两个容器：

{{< text bash >}}
$ kubectl delete pod sleep-776b7bcdcd-7hpnk
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-7hpnk   1/1       Terminating   0          1m
sleep-776b7bcdcd-bhn9m   2/2       Running       0          7s
{{< /text >}}

查看被注入的 Pod 的细节。不难发现多出了一个 `istio-proxy` 容器及其对应的存储卷。注意用正确的 Pod 名称来执行下面的命令：

{{< text bash >}}
$ kubectl describe pod sleep-776b7bcdcd-bhn9m
{{< /text >}}

禁用 `default` 命名空间的自动注入功能，然后检查新建 Pod 是不是就不带有 Sidecar 容器了：

{{< text bash >}}
$ kubectl label namespace default istio-injection-
$ kubectl delete pod sleep-776b7bcdcd-bhn9m
$ kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
sleep-776b7bcdcd-bhn9m   2/2       Terminating   0          2m
sleep-776b7bcdcd-gmvnr   1/1       Running       0          2s
{{< /text >}}

#### 了解发生了什么

被 Kubernetes 调用时，[admissionregistration.k8s.io/v1beta1#MutatingWebhookConfiguration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.10) 会进行配置。Istio 提供的缺省配置，会在带有 `istio-injection=enabled` 标签的命名空间中选择 Pod。使用 `kubectl edit mutatingwebhookconfiguration istio-sidecar-injector` 命令可以编辑目标命名空间的范围。

> {{< warning_icon >}} 修改 mutatingwebhookconfiguration 之后，应该重新启动已经被注入 Sidecar 的 Pod。

`istio-system` 命名空间中的 ConfigMap `istio-sidecar-injector` 中包含了缺省的注入策略以及 Sidecar 的注入模板。

##### **策略**

`disabled` - Sidecar 注入器缺省不会向 Pod 进行注入。在 Pod 模板中加入 `sidecar.istio.io/inject` 注解并赋值为 `true` 才能启用注入。

`enabled` - Sidecar 注入器缺省会对 Pod 进行注入。在 Pod 模板中加入 `sidecar.istio.io/inject` 注解并赋值为 `false` 就会阻止对这一 Pod 的注入。

下面的例子用 `sidecar.istio.io/inject` 注解来禁用 Sidecar 注入：

{{< text yaml >}}
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

##### **模板**

Sidecar 注入模板使用的是 [golang 模板](https://golang.org/pkg/text/template)，当解析和执行时，会解码为下面的结构，其中包含了将要注入到 Pod 中的容器和卷。

{{< text go >}}
type SidecarInjectionSpec struct {
      InitContainers   []v1.Container `yaml:"initContainers"`
      Containers       []v1.Container `yaml:"containers"`
      Volumes          []v1.Volume    `yaml:"volumes"`
      ImagePullSecrets []corev1.LocalObjectReference `yaml:"imagePullSecrets"`
}
{{< /text >}}

在运行时，这个模板会形成如下的数据结构：

{{< text go >}}
type SidecarTemplateData struct {
    ObjectMeta  *metav1.ObjectMeta
    Spec        *v1.PodSpec
    ProxyConfig *meshconfig.ProxyConfig  // 定义来自于 https://istio.io/docs/reference/config/service-mesh.html#proxyconfig
    MeshConfig  *meshconfig.MeshConfig   // 定义来自于  https://istio.io/docs/reference/config/service-mesh.html#meshconfig
}
{{< /text >}}

`ObjectMeta` 和 `Spec` 都来自于 Pod。`ProxyConfig` 和 `MeshConfig` 来自 `istio-system` 命名空间中的 `istio` ConfigMap。模板可以使用这些数据，有条件对将要注入的容器和卷进行定义。

例如下面的模板代码段来自于 `install/kubernetes/istio-sidecar-injector-configmap-release.yaml`

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

会在部署 [Sleep 应用]({{< github_tree >}}/samples/sleep/sleep.yaml)时应用到 Pod 上，并扩展为：

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

#### 删除 Sidecar 注入器

{{< text bash >}}
$ kubectl delete mutatingwebhookconfiguration istio-sidecar-injector
$ kubectl -n istio-system delete service istio-sidecar-injector
$ kubectl -n istio-system delete deployment istio-sidecar-injector
$ kubectl -n istio-system delete serviceaccount istio-sidecar-injector-service-account
$ kubectl delete clusterrole istio-sidecar-injector-istio-system
$ kubectl delete clusterrolebinding istio-sidecar-injector-admin-role-binding-istio-system
{{< /text >}}

上面的命令不会从 Pod 中移除已经注入的 Sidecar。可以用一次滚动更新，或者简单的删除原有 Pod 迫使 Deployment 重新创建都可以移除 Sidecar。

除此以外，还可以删除我们在本任务中做出的其它更改：

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}

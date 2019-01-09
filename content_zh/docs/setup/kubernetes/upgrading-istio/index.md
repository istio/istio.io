---
title: 升级 Istio
description: 演示如何独立升级 Istio 控制平面和数据平面。
weight: 70
keywords: [kubernetes,upgrading]
---

本页介绍如何将现有的 Istio 部署（包括控制平面和 sidecar 代理）升级到新版本。
升级过程可能涉及新的二进制文件以及配置和 API schemas 等其他更改。升级过程可能导致一些服务停机。为了最大限度地减少停机时间，请使用多副本以保证 Istio 控制平面组件和应用程序具有高可用性。

在下面的步骤中，我们假设 Istio 组件在  `istio-system` namespace 中安装和升级。

## 升级步骤

1. [下载新的 Istio 版本](/zh/docs/setup/kubernetes/download-release/)并将目录更改为新版本目录。

1. 升级 Istio 的[自定义资源定义](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
通过 `kubectl apply` ，等待几秒钟，让 CRD 在 kube-apiserver 中提交：

{{< text bash >}}
$ kubectl apply -f @install/kubernetes/helm/istio/templates/crds.yaml@ -n istio-system
{{< /text >}}

### 控制平面升级

Istio 控制平面组件包括：Citadel、Ingress 网关、Egress 网关、Pilot、Policy、Telemetry 和 Sidecar 注入器。我们可以使用 Kubernetes 的滚动更新机制来升级控制平面组件。

#### 用 Helm 升级

如果你用 [Helm](/zh/docs/setup/kubernetes/helm-install/#选项2-通过-helm-和-tiller-的-helm-install-安装-istio) 安装了 Istio，那么首选升级方式是让 Helm 负责升级：

{{< text bash >}}
$ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system
{{< /text >}}

#### Kubernetes 滚动更新

如果没有使用 Helm 安装 Istio 的话。您还可以使用 Kubernetes 的滚动更新机制来升级控制平面组件。

首先，生成 Istio 控制平面需要的 yaml 文件，例如：

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio \
    --namespace istio-system > install/kubernetes/istio.yaml
{{< /text >}}

或者

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio \
    --namespace istio-system --set global.mtls.enabled=true > install/kubernetes/istio-auth.yaml
{{< /text >}}

如果使用 1.9 之前的 Kubernetes 版本，则应添加 `--set sidecarInjectorWebhook.enabled=false`。

接下来，只需直接应用 Istio 控制平面所需的 yaml 文件的新版本，例如，

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio.yaml
{{< /text >}}

或者

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-auth.yaml
{{< /text >}}

滚动更新过程会将所有 deployment 和 configmap 升级到新版本。完成此过程后，您的 Istio 控制面应该会更新为新版本。使用 Envoy v1 和 v1alpha1 路由规则（route rule）的现有应用程序应该可以继续正常工作而无需任何修改。如果新控制平面存在任何关键问题，您都可以通过应用旧版本的 yaml 文件来回滚更改。

### Sidecar 升级

控制平面升级后，已经运行 Istio 的应用程序仍将使用旧版本的 sidecar。要想升级 sidecar，您需要重新注入它。

如果您使用自动 sidecar 注入（automatic sidecar injection），您可以通过对所有 pod 进行滚动升级来升级 sidecar，这样新版本的 sidecar 将被自动重新注入。一些技巧可以重新加载所有 pod。例如，有一个 [bash 脚本](https://gist.github.com/jmound/ff6fa539385d1a057c82fa9fa739492e) 可以通过 patch 优雅结束时长（grace termination period）来触发滚动更新。

如果您使用手动注入，可以通过执行以下命令来升级 sidecar：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}

如果 sidecar 以前被注入了一些定制的注入配置文件，您需要将配置文件中的版本标签更改为新文件版本并像下面这样重新注入 sidecar：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject \
     --injectConfigFile inject-config.yaml \
     --filename $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}

## 迁移到新的网络 API

一旦升级了控制平面和 sidecar，您就可以逐步更新 deployment 以使用新的 Envoy sidecar。你可以通过以下选项之一使用来做到这一点:

- 添加以下内容到您的 deployment 的 pod annotation 中：

    {{< text yaml >}}
    kind: Deployment
    ...
    spec:
      template:
        metadata:
          annotations:
            sidecar.istio.io/proxyImage: docker.io/istio/proxyv2:0.8.0
    {{< /text >}}

    然后将您的 deployment 替换为更新的应用 yaml 文件：

    {{< text bash >}}
    $ kubectl replace -f $UPDATED_DEPLOYMENT_YAML
    {{< /text >}}

或者

- 使用将 `docker.io/istio/proxyv2:0.8.0` 作为代理镜像的 `injectConfigFile`。如果没有 `injectConfigFile`，您可以 [生成一个](/zh/docs/setup/kubernetes/sidecar-injection/#手工注入-sidecar)。如果需要在多个 deployment 定义中添加 `sidecar.istio.io/proxyImage` annotation，推荐使用 `injectConfigFile`。

    {{< text bash >}}
    $ kubectl replace -f <(istioctl kube-inject --injectConfigFile inject-config.yaml -f $ORIGINAL_DEPLOYMENT_YAML)
    {{< /text >}}

接下来，使用 `istioctl experimental convert-networking-config` 来转换现有的 ingress 或路由规则：

1. 如果您的 yaml 文件包含比 ingress 定义（如 deployment 或 service 定义）更多的定义，请将 ingress 定义移出到单独的 yaml 文件中，以供 `istioctl experimental convert-networking-config` 工具处理。

1. 执行以下命令以生成新的网络配置文件，将其中的 FILE* 替换为 ingress 文件或弃用的路由规则文件。
*提示：请确保使用 `-f` 来为一个或多个 deployment 提供所有文件。*

    {{< text bash >}}
    $ istioctl experimental convert-networking-configuration-f FILE1.yaml -f FILE2.yaml -f FILE3.yaml > UPDATED_NETWORK_CONFIG.yaml
    {{< /text >}}

1. 编辑 `UPDATED_NETWORK_CONFIG.yaml` 以更新所有 namespace 引用为您需要的 namespace。`convert-networking-config` 工具有一个已知问题，导致 `istio-system` namespace 的使用不正确。此外，请确保 `hosts` 值的正确性。

1. 部署更新的网络配置文件。

    {{< text bash >}}
    $ kubectl replace -f UPDATED_NETWORK_CONFIG.yaml
    {{< /text >}}

当您的所有应用程序都已迁移并经过测试后，您可以重复 Istio 升级过程，删除
 `--set global.proxy.image = proxy` 选项。这会将所有后来注入的 sidecar 的默认代理设置为`docker.io/istio/proxyv2`。

## 通过 annotation 将身份验证策略迁移为启用 per-service 双向 TLS

如果使用 service annotation 覆盖 service 的全局双向 TLS，则需要将其替换为 [认证策略](/zh/docs/concepts/security/#认证策略) 和 [目的规则](/zh/docs/concepts/traffic-management/)。

例如，如果您在启用双向 TLS 的情况下安装 Istio，并使用如下所示的 service annotation 对 service `foo` 禁用它：

{{< text yaml >}}
kind: Service
metadata:
  name: foo
  namespace: bar
  annotations:
    auth.istio.io/8000: NONE
{{< /text >}}

您需要用此身份验证策略和目标规则替换它（删除旧 annotation 是可选的）

{{< text yaml >}}
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "disable-mTLS-foo"
  namespace: bar
spec:
  targets:
  - name: foo
    ports:
    - number: 8000
  peers:
---
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "disable-mTLS-foo"
  namespace: "bar"
spec:
  host: "foo"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
    portLevelSettings:
    - port:
        number: 8000
      tls:
        mode: DISABLE
{{< /text >}}

如果您已经有 `foo` 的目标规则，则必须编辑该规则而不是创建新规则。
创建新的目标规则时，请确保包含其他设置，如`load balancer`、`connection pool` 和 `outlier detection`（如有必要）。
最后，如果 `foo` 没有 sidecar，你可以跳过身份验证策略，但仍然需要添加目标规则。

如果 8000 是 service `foo` 提供的唯一端口（或者您希望禁用所有端口的双向 TLS），则策略可以简化为：

{{< text yaml >}}
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "disable-mTLS-foo"
    namespace: bar
  spec:
    targets:
    - name: foo
    peers:
---
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "disable-mTLS-foo"
  namespace: "bar"
spec:
  host: "foo"
trafficPolicy:
  tls:
    mode: DISABLE
{{< /text >}}

## 将 `mtls_excluded_services` 配置迁移到目标规则

如果您在启用双向 TLS 的情况下安装了 Istio，并且使用网格配置 `mtls_excluded_services` 来在连接这些服务（例如 Kubernetes API server）时禁用双向 TLS，则需要通过添加目标规则来替换它。例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: "kubernetes-master"
  namespace: "default"
spec:
  host: "kubernetes.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
{{< /text >}}

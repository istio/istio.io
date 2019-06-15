---
title: 升级步骤
description: 演示如何独立升级 Istio 控制平面和数据平面。
weight: 25
keywords: [kubernetes,upgrading]
---

本页介绍如何将现有的 Istio 部署（包括控制平面和数据平面）升级到新版本。
升级过程可能涉及到新的二进制文件、配置以及 API 结构等其他更改。升级过程还有可能导致一些服务中断。为了最大限度地减少停机时间，请使用多副本以保证 Istio 控制平面组件和应用程序具有高可用性。

{{< warning >}}
Citadel 不支持多实例。同时运行多个 Citadel 实例，可能会引发系统故障。
{{< /warning >}}

在下面的步骤中，我们假设 Istio 组件在  `istio-system` 命名空间中安装和升级。

{{< warning >}}
将部署升级到 Istio 1.1 前，建议首先阅读[升级须知](/docs/setup/kubernetes/upgrade/notice)中的的简明事项列表。
{{< /warning >}}

## 升级步骤

1. [下载新的 Istio 版本](/zh/docs/setup/kubernetes/download/)并将目录更改为新版本目录。

### 控制平面升级

{{< warning >}}
使用 Tiller 升级 CRD 时，Helm 存在严重问题。
我们相信引入 `istio-init` Chart 之后这一问题已经得以解决。
但是，由于以前的 Istio 部署中使用的 Helm 和 Tiller 涵盖了从 2.7.2 到 2.12.2 的众多版本，因此建议大家谨慎操作，在继续升级之前一定要备份好自定义资源数据：

{{< text bash >}}
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | cut -f1-1 -d "." | \
    xargs -n1 -i sh -c "kubectl get --all-namespaces -oyaml {}; echo ---" > $HOME/ISTIO_1_0_RESTORE_CRD_DATA.yaml
{{< /text >}}

{{< /warning >}}

Istio 控制平面组件包括：Citadel、Ingress 网关、Egress 网关、Pilot、Galley、Policy、Telemetry 和 Sidecar 注入器。下面提供两种升级控制平面的方法，这两种方法是互斥的：

{{< tabset cookie-name="controlplaneupdate" >}}
{{< tab name="Kubernetes 的滚动更新" cookie-value="k8supdate" >}}
您可以使用 Kubernetes 的滚动更新机制来升级控制平面组件。
这适用于使用 `kubectl apply` 部署 Istio 组件的情况，
包括使用 [helm template](/zh/docs/setup/kubernetes/install/helm/#方案-1-使用-helm-template-进行安装) 生成的配置。

1. 使用 `kubectl apply` 升级 Istio 所有的 CRD。稍微等待几秒钟，让 Kubernetes API 服务器接收升级后的 CRD：

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. 将 Istio 的核心组件添加到 Kubernetes 的清单文件中，例如：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio \
      --namespace istio-system > $HOME/istio.yaml
    {{< /text >}}

    如果要启用[全局双向 TLS](/docs/concepts/security/#mutual-tls-authentication)，请将 `global.mtls.enabled` 和 `global.controlPlaneSecurityEnabled` 设置为 `true` ：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --set global.mtls.enabled=true --set global.controlPlaneSecurityEnabled=true > $HOME/istio-auth.yaml
    {{< /text >}}

1. 通过清单升级 Istio 控制平面组件，例如：

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

    或

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-auth.yaml
    {{< /text >}}

滚动更新过程会将所有 Deployment 和 Configmap 升级到新版本。完成此过程后，Istio 的控制平面应该会更新为新版本。而现有的应用程序应该继续工作。如果新控制平面存在严重问题，可以应用旧版本的 yaml 文件来回滚更改。
{{< /tab >}}

{{< tab name="Helm 升级" cookie-value="helmupgrade" >}}
如果你使用 [Helm 和 Tiller](/zh/docs/setup/kubernetes/install/helm/#方案-2-在-helm-和-tiller-的环境中使用-helm-install-命令进行安装) 安装了 Istio，
首选方案就是使用 Helm 进行升级。

1. 升级 `istio-init` chart 以更新所有 Istio [自定义资源定义](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)（CRD）。

    {{< text bash >}}
    $ helm upgrade --install istio-init install/kubernetes/helm/istio-init --namespace istio-system
    {{< /text >}}

1. 检查所有的 CRD 创建 job 是否已成功完成，以验证 Kubernetes API 服务器是否已收到所有 CRD：

    {{< text bash >}}
    $ kubectl get job --namespace istio-system | grep istio-init-crd
    {{< /text >}}

1. 升级 `istio` chart：

    {{< text bash >}}
    $ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system
    {{< /text >}}

{{< /tab >}}
{{< /tabset >}}

### Sidecar 升级

控制平面升级后，已经运行 Istio 的应用程序仍将使用旧版本的 Sidecar。要想升级 Sidecar，需要重新进行注入。

如果使用自动 Sidecar 注入，可以对所有 Pod 进行滚动升级，升级过程中，新版本的 Sidecar 将被自动重新注入。一些技巧可以重新加载所有 Pod。例如，有一个 [bash 脚本](https://gist.github.com/jmound/ff6fa539385d1a057c82fa9fa739492e)可以通过对 `terminationGracePeriodSeconds` 字段的 `patch` 来触发滚动更新。

如果您使用手动注入，可以通过执行以下命令来升级 Sidecar：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}

如果 Sidecar 以前被注入了一些定制的注入配置文件，您需要将配置文件中的版本标签更改为新文件版本并像下面这样重新注入 Sidecar：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject \
     --injectConfigFile inject-config.yaml \
     --filename $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}

## 把通过注解方式启用的以服务为单位的双向 TLS 配置转化为认证策略

如果对一个服务使用注解方式覆盖了全局双向 TLS 配置，则需要将其替换为[认证策略](/zh/docs/concepts/security/#认证策略)和[目的规则](/zh/docs/concepts/traffic-management/)。

例如，在安装 Istio 的时候启用了双向 TLS，并使用如下注解在服务 `foo` 中禁止这一功能：

{{< text yaml >}}
kind: Service
metadata:
  name: foo
  namespace: bar
  annotations:
    auth.istio.io/8000: NONE
{{< /text >}}

就需要用身份验证策略和目标规则替换它（注解可以删除）

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
创建新的目标规则时，如有必要，还可以包含其它配置，例如 `load balancer`、`connection pool` 和 `outlier detection`。
最后，如果 `foo` 没有 Sidecar，你可以跳过身份验证策略，但仍然需要添加目标规则。

如果 8000 是 `foo` 服务提供的唯一端口（或者您希望禁用所有端口的双向 TLS），则策略可以简化为：

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

## 将 `mtls_excluded_services` 配置转换为目标规则

如果您在安装 Istio 时启用了双向 TLS，并且使用网格配置 `mtls_excluded_services` 来在连接某些服务（例如 Kubernetes API server）时禁用双向 TLS，则需要通过添加目标规则的方式进行替换。例如：

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

## 从 `RbacConfig` 到 `ClusterRbacConfig`

`RbacConfig` 因为一个 [Bug](https://github.com/istio/istio/issues/8825) 的原因已经被废弃。这个 Bug 在某些情况下会将这个对象的生效范围降低到命名空间级别。如果你正在使用 `RbacConfig`，必须迁移到 `ClusterRbacConfig`。`ClusterRbacConfig` 的声明跟 `RbacConfig` 完全一样，但是实现了正确的集群级范围。

为了自动化迁移过程，我们开发了脚本`convert_RbacConfig_to_ClusterRbacConfig.sh`. 这个脚本在 [Istio 的安装包](/zh/docs/setup/kubernetes/download)中。

下载并运行如下命令：

{{< text bash >}}
$ curl -L {{< github_file >}}git/tools/convert_RbacConfig_to_ClusterRbacConfig.sh | sh -
{{< /text >}}

这个脚本自动完成下如下操作：

1. 创建跟已经存在的 RBAC 配置一样的集群 RBAC 配置，因为在 Kubernetes 中，已经创建的资源，其 `kind` 字段是不允许进行修改的。

    例如集群之中创建了下面的 `RbacConfig`：

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: RbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]
    {{< /text >}}

    这个脚本就会创建如下的 `ClusterRbacConfig`，来进行替换：

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]
    {{< /text >}}

1. 应用 `ClusterRbacConfig`，并等待几秒钟以使配置生效。

1. 在成功应用 `ClusterRbacConfig` 之后，删除之前的 `RbacConfig`。

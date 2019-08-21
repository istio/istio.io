---
title: 升级步骤
description: 演示如何独立升级 Istio 控制平面和数据平面。
weight: 25
keywords: [kubernetes,upgrading]
---

本页介绍如何将现有的 Istio 部署（包括控制平面和 sidecar 代理）升级到新版本。
升级过程可能涉及新的二进制文件以及配置和 API schemas 等其他更改。升级过程可能导致一些服务停机。为了最大限度地减少停机时间，请使用多副本以保证 Istio 控制平面组件和应用程序具有高可用性。

在下面的步骤中，我们假设 Istio 组件在  `istio-system` namespace 中安装和升级。

{{< warning >}}
将部署升级到 Istio 1.1 前您一定要先看看[升级通知](/docs/setup/upgrade/notice) 的简明事项列表。
{{< /warning >}}

## 升级步骤

1. [下载新的 Istio 版本](/zh/docs/setup/kubernetes/download/)并将目录更改为新版本目录。

### 控制平面升级

{{< warning >}}
使用 Tiller 升级 CRD 时，Helm 存在严重问题。
我们相信我们已经通过引入 `istio-init` chart 解决了这些问题。
但是，由于以前的 Istio 部署中使用的 Helm 和 Tiller 版本种类繁多，
从 2.7.2 到 2.12.2，我们建议大家谨慎操作
切忌在继续升级之前一定要备份好自定义资源数据：

{{< text bash >}}
$ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | cut -f1-1 -d "." | \
    xargs -n1 -i sh -c "kubectl get --all-namespaces -oyaml {}; echo ---" > $HOME/ISTIO_1_0_RESTORE_CRD_DATA.yaml
{{< /text >}}

{{< /warning >}}

Istio 控制平面组件包括：Citadel、Ingress 网关、Egress 网关、Pilot、Policy、Telemetry 和 Sidecar 注入器。我们可以使用 Kubernetes 的滚动更新机制来升级控制平面组件。

{{< tabset cookie-name="controlplaneupdate" >}}
{{< tab name="Kubernetes 的滚动更新" cookie-value="k8supdate" >}}
您可以使用 Kubernetes 的滚动更新机制来升级控制平面组件。
这适用于使用 `kubectl apply` 部署 Istio 组件的情况，
包括使用 [helm template](/docs/setup/install/helm/#option-1-install-with-helm-via-helm-template) 生成的配置。

1. 使用 `kubectl apply` 升级 Istio 所有的 CRD。稍微等待几秒钟，让 Kubernetes API 服务器接收升级后的 CRD：

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. 例如，将 Istio 的核心组件添加到 Kubernetes 的清单文件中。

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio \
      --namespace istio-system > $HOME/istio.yaml
    {{< /text >}}

    如果要启用 [全局双向 TLS](/docs/concepts/security/#mutual-tls-authentication)，请将 `global.mtls.enabled` 和 `global.controlPlaneSecurityEnabled` 设置为 `true` 以获取最后一个命令：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --set global.mtls.enabled=true --set global.controlPlaneSecurityEnabled=true > $HOME/istio-auth.yaml
    {{< /text >}}

    如果使用 1.9 之前的 Kubernetes 版本，则应添加 `--set sidecarInjectorWebhook.enabled=false`。

1. 通过清单升级 Istio 控制平面组件，例如：

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

    或

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-auth.yaml
    {{< /text >}}

滚动更新过程会将所有部署和配置升级到新版本。完成此过程后，
您的 Istio 控制平面应该会更新为新版本。您现有的应用程序应该继续工作。
如果新控制平面存在任何严重问题，您可以通过应用旧版本的 yaml 文件来回滚更改。
{{< /tab >}}

{{< tab name="Helm 升级" cookie-value="helmupgrade" >}}
如果你使用 [Helm 和 Tiller](/docs/setup/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install) 安装了 Istio，
首选升级选项是让 Helm 负责升级。

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

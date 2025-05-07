---
---
## 先决条件 {#prerequisites}

1. 执行任何必要的[特定于平台的设置](/zh/docs/setup/platform-setup/)。

1. 检查 [Pod 和服务的要求](/zh/docs/ops/deployment/application-requirements/)。

1. [安装最新的 Helm 客户端](https://helm.sh/docs/intro/install/)。
   早于[当前支持的最旧 Istio 版本](/zh/docs/releases/supported-releases/#support-status-of-istio-releases) 发布的 Helm 版本未经测试、支持或推荐。

1. 配置 Helm 仓库：

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}

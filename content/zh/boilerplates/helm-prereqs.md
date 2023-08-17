---
---
## 先决条件{#prerequisites}

1. 执行任何必要的[特定于平台的设置](/zh/docs/setup/platform-setup/)。

1. 检查 [Pod 和服务的要求](/zh/docs/ops/deployment/requirements/)。

1. [安装 Helm 客户端](https://helm.sh/zh/docs/intro/install/) 3.6 或更高的版本。

1. 配置 Helm 存储库：

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}

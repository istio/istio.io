---
---
本指南中使用的 `base` 和 `istiod` Helm Chart 与通过
[Istioctl](/zh/docs/setup/install/istioctl/) 或
[Operator](/zh/docs/setup/install/operator/) 安装 Istio 时使用的 Chart 相同。
但是，通过 Istioctl 和 Operator 进行安装时使用了与本指南所述
[Chart]({{< github_tree >}}/manifests/charts/gateway)
不同的[网关 Chart]({{< github_tree >}}/manifests/charts/gateways/istio-ingress)。

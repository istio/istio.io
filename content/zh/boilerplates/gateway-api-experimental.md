---
---
{{< warning >}}

本文使用 Kubernetes Gateway API 的[实验性功能](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)。
需要使用 Alpha 版本的 CRD。在继续执行此任务之前，请确保：

1) 安装 Gateway API CRD 的 Alpha 版本：

    {{< text syntax=bash snip_id=install_experimental_crds >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
    {{< /text >}}

2) 安装 Istio 时，通过将 `PILOT_ENABLE_ALPHA_GATEWAY_API`
    环境变量设置为 `true` 使 Istio 读取 Alpha 版本的资源：

    {{< text syntax=bash snip_id=enable_alpha_crds >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true --set profile=minimal -y
    {{< /text >}}

{{< /warning >}}

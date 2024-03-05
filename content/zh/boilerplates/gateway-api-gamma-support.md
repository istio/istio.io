---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< warning >}}
本文使用 Gateway API 配置内部网格（东西）流量。
使用 Gateway API 配置内部网格流量目前是一个还在开发的[实验性特性](https://gateway-api.sigs.k8s.io/geps/overview/#status)，
也是 Istio 特有的功能。在使用 Gateway API 指令之前，请确保：

1) 安装 **实验版本** 的 Gateway API CRD：

    {{< text syntax=bash snip_id=install_experimental_crds >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
    {{< /text >}}

2) 安装 Istio 时，通过将 `PILOT_ENABLE_ALPHA_GATEWAY_API`
    环境变量设置为 `true` 使 Istio 读取 Alpha 版本的 Gateway API 资源：

    {{< text syntax=bash snip_id=enable_alpha_crds >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true --set profile=minimal -y
    {{< /text >}}

{{< /warning >}}

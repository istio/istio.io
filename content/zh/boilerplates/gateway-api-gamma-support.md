---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}

请注意，本文使用 Gateway API 配置内部网格（东西）流量，即不仅是 Ingress（南北）流量。
配置内部网格流量是 Gateway API 的[实验性特性](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)，
目前正在开发中，等待[上游协议](https://gateway-api.sigs.k8s.io/contributing/gamma/)。
确保在使用 Gateway API 之前安装实验性的 CRD。

{{< text syntax=bash snip_id=install_experimental_crds >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
{{< /text >}}

{{< /tip >}}

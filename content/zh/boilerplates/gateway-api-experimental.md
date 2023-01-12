---
---
{{< warning >}}

本文使用 Kubernetes Gateway API 的[实验性功能](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)。请确保在使用 Gateway API 之前安装实验性 CRD。

{{< text syntax=bash snip_id=install_experimental_crds >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
{{< /text >}}

{{< /warning >}}

---
---
{{< warning >}}
This document uses [experimental features](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)
of the Kubernetes Gateway API. Make sure to install the experimental CRDs before using the Gateway API:

{{< text syntax=bash snip_id=install_experimental_crds >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
{{< /text >}}

{{< /warning >}}

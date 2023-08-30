---
---
{{< warning >}}
This document uses [experimental features](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)
of the Kubernetes Gateway API which require the alpha version of the CRDs. Before proceeding with this task, make sure to:

1) Install the alpha version of the Gateway API CRDs:

    {{< text syntax=bash snip_id=install_experimental_crds >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
    {{< /text >}}

2) Configure Istio to read the alpha resources by setting the `PILOT_ENABLE_ALPHA_GATEWAY_API` environment variable to `true`
    when installing Istio:

    {{< text syntax=bash snip_id=enable_alpha_crds >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true --set profile=minimal -y
    {{< /text >}}

{{< /warning >}}

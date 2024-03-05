---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< warning >}}
This document configures internal mesh (east-west) traffic
that requires Gateway API features that are either
[experimental](https://gateway-api.sigs.k8s.io/geps/overview/#status)
or Istio specific.
Before using the Gateway API instructions, make sure to:

1) Install the **experimental version** of the Gateway API CRDs:

    {{< text syntax=bash snip_id=install_experimental_crds >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
    {{< /text >}}

2) Configure Istio to read the alpha Gateway API resources by setting the `PILOT_ENABLE_ALPHA_GATEWAY_API` environment
    variable to `true` when installing Istio:

    {{< text syntax=bash snip_id=enable_alpha_crds >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true --set profile=minimal -y
    {{< /text >}}

{{< /warning >}}

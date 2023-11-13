---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< warning >}}
Note that this document uses the Gateway API to configure internal mesh (east-west) traffic,
i.e., not just ingress (north-south) traffic.
Configuring internal mesh traffic is an
[experimental feature](https://gateway-api.sigs.k8s.io/geps/overview/#status)
of the Gateway API, currently under development.
If using the Gateway API instructions, before proceeding make sure to:

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

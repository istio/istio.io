---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}

Note that this document uses the Gateway API to configure internal mesh (east-west) traffic,
i.e., not just ingress (north-south) traffic.
Configuring internal mesh traffic is an
[experimental feature](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)
of the Gateway API, currently under development and pending [upstream agreement](https://gateway-api.sigs.k8s.io/contributing/gamma/).
Make sure to install the experimental CRDs before using the Gateway API:

{{< text syntax=bash snip_id=install_experimental_crds >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
{{< /text >}}

{{< /tip >}}

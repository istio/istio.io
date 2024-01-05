---
---
{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< warning >}}
The following Gateway API instructions include features that are both
[experimental](https://gateway-api.sigs.k8s.io/geps/overview/#status)
and Istio specific. Before using the Gateway API instructions, make sure to
install the **experimental version** of the Gateway API CRDs:

{{< text syntax=bash snip_id=install_experimental_crds >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
{{< /text >}}

{{< /warning >}}

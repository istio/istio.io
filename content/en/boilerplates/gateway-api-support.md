---
---
{{< tip >}}
Istio intends to make the Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/) the default API for traffic management
[in the future](/blog/2022/gateway-api-beta/).
The following instructions allow you to choose to use either the Gateway API or the Istio configuration API when configuring
traffic management in the mesh. Follow instructions under either the `Gateway API` or `Istio classic` tab,
according to your preference.

Note that the Kubernetes Gateway API CRDs do not come installed by default on most Kubernetes clusters, so make sure they are
installed before using the Gateway API:

{{< text syntax=bash snip_id=install_crds >}}
$ kubectl get crd gateways.gateway.networking.k8s.io || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

{{< /tip >}}

---
---
Note that the Kubernetes Gateway API CRDs do not come installed by default on most Kubernetes clusters, so make sure they are
installed before using the Gateway API:

{{< text syntax=bash snip_id=install_crds >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

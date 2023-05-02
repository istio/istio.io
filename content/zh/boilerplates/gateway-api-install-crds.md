---
---
请注意，Kubernetes Gateway API CRD 不会默认安装在大多数 Kubernetes 集群上，因此请确保在使用 Gateway API 之前已安装好这些 CRD：

{{< text syntax=bash snip_id=install_crds >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

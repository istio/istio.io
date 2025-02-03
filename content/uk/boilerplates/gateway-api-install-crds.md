---
---
Зверніть увагу, що CRD Kubernetes Gateway API стандартно не встановлені в більшості кластерів Kubernetes, тому переконайтеся, що вони встановлені перед використанням Gateway API:

{{< text syntax=bash snip_id=install_crds >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/{{< k8s_gateway_api_version >}}/standard-install.yaml
{{< /text >}}

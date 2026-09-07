---
---
Вилучіть CRD Kubernetes Gateway API:

{{< text syntax=bash snip_id=remove_crds >}}
$ kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/{{< k8s_gateway_api_version >}}/experimental-install.yaml
{{< /text >}}

---
---
Remove the Kubernetes Gateway API CRDs:

{{< text syntax=bash snip_id=remove_crds >}}
$ kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
{{< /text >}}

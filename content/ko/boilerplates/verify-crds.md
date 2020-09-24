---
---
Wait for all Istio CRDs to be created:

{{< text bash >}}
$ kubectl -n istio-system wait --for=condition=complete job --all
{{< /text >}}

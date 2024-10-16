---
---
Зачекайте, поки будуть створені всі Istio CRD:

{{< text bash >}}
$ kubectl -n istio-system wait --for=condition=complete job --all
{{< /text >}}

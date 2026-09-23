---
---
Espera a que se creen todas las CRD de Istio:

{{< text bash >}}
$ kubectl -n istio-system wait --for=condition=complete job --all
{{< /text >}}

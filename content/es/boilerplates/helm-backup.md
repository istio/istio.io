---
---
Antes de actualizar Istio en tu cluster, recomendamos crear una copia de seguridad de tus
configuraciones personalizadas y restaurarla desde la copia de seguridad si es necesario:

{{< text bash >}}
$ kubectl get istio-io --all-namespaces -oyaml > "$HOME"/istio_resource_backup.yaml
{{< /text >}}

Puedes restaurar tu configuración personalizada de esta manera:

{{< text bash >}}
$ kubectl apply -f "$HOME"/istio_resource_backup.yaml
{{< /text >}}

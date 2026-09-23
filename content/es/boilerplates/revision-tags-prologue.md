---
---
Ahora, la asignación actualizada entre revisiones, etiquetas y namespaces es como se muestra a continuación:

{{< image width="90%"
link="/es/docs/setup/upgrade/canary/revision-tags-after.svg"
caption="Las etiquetas de los namespaces no han cambiado, pero ahora todos los namespaces apuntan a {{< istio_full_version_revision >}}"
>}}

Reiniciar los workloads inyectadas en los namespaces marcados como `prod-stable` ahora dará como resultado que esas workloads usen el
control plane `{{< istio_full_version_revision >}}`.
Observa que no se requirió ningún reetiquetado de namespace para migrar los workloads a la nueva revisión.

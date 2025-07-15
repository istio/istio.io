---
---
La asignación resultante entre revisiones, etiquetas y namespaces es como se muestra a continuación:

{{< image width="90%"
link="/es/docs/setup/upgrade/canary/revision-tags-before.svg"
caption="Dos namespaces apuntados a prod-stable y uno apuntado a prod-canary"
>}}

El operador del cluster puede ver esta asignación además de los namespaces etiquetados a través del comando `istioctl tag list`:

{{< text bash >}}
$ istioctl tag list
TAG         REVISION NAMESPACES
default     {{< istio_previous_version_revision >}}-1   ...
prod-canary {{< istio_full_version_revision >}}   ...
prod-stable {{< istio_previous_version_revision >}}-1   ...
{{< /text >}}

Después de que el operador del cluster esté satisfecho con la estabilidad del control plane etiquetado con `prod-canary`, los namespaces etiquetados
`istio.io/rev=prod-stable` se pueden actualizar con una acción modificando la etiqueta de revisión `prod-stable` para que apunte a la revisión
`{{< istio_full_version_revision >}}` más nueva.

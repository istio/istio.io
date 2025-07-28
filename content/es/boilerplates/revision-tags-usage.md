---
---
Considera un cluster con dos revisiones instaladas, `{{< istio_previous_version_revision >}}-1` y `{{< istio_full_version_revision >}}`. El operador del cluster crea una etiqueta de revisión `prod-stable`,
apuntando a la versión más antigua y estable `{{< istio_previous_version_revision >}}-1`, y una etiqueta de revisión `prod-canary` apuntando a la revisión más nueva `{{< istio_full_version_revision >}}`. Ese
estado podría alcanzarse a través de los siguientes comandos:

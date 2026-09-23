---
title: Actualizar con Helm (simple)
description: Actualización de una instalación en modo ambient con Helm usando un solo chart
weight: 5
owner: istio/wg-environments-maintainers
test: yes
draft: true
---

Sigue esta guía para actualizar y configurar una instalación en modo ambient usando
[Helm](https://helm.sh/docs/). Esta guía asume que ya has realizado una [instalación en modo ambient con Helm y el chart contenedor ambient](/es/docs/ambient/install/helm/all-in-one) con una versión anterior de Istio.

{{< warning >}}
Ten en cuenta que estas instrucciones de actualización solo se aplican si estás actualizando una instalación de Helm creada con el
chart contenedor ambient; si instalaste a través de charts de componentes de Helm individuales, consulta [la documentación de actualización relevante](docs/ambient/upgrade/helm)
{{< /warning >}}

## Entendiendo las actualizaciones del modo ambient

{{< warning >}}
Ten en cuenta que si instalas todo como parte de este chart contenedor, solo puedes actualizar o desinstalar
ambient a través de este chart contenedor; no puedes actualizar o desinstalar subcomponentes individualmente.
{{< /warning >}}

## Prerrequisitos

### Prepararse para la actualización

Antes de actualizar Istio, recomendamos descargar la nueva versión de istioctl y ejecutar `istioctl x precheck` para asegurarte de que la actualización sea compatible con tu entorno. La salida debería ser algo como esto:

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

Ahora, actualiza el repositorio de Helm:

{{< text syntax=bash snip_id=update_helm >}}
$ helm repo update istio
{{< /text >}}

### Actualizar el control plane y el data plane ambient de Istio

{{< warning >}}
La actualización mediante el chart contenedor in-place interrumpirá brevemente todo el tráfico de la mesh ambient en el nodo, **incluso con el uso de revisiones**. En la práctica, el período de interrupción es una ventana muy pequeña, que afecta principalmente a las conexiones de larga duración.

Se recomienda el acordonamiento de nodos y los grupos de nodos azul/verde para mitigar el riesgo del radio de explosión durante las actualizaciones de producción. Consulta la documentación de tu proveedor de Kubernetes para obtener más detalles.
{{< /warning >}}

El chart `ambient` actualiza todos los componentes del data plane y del control plane de Istio necesarios para
ambient, utilizando un chart contenedor de Helm que compone los charts de los componentes individuales.

Si has personalizado tu instalación de istiod, puedes reutilizar el archivo `values.yaml` de actualizaciones o instalaciones anteriores para mantener la configuración coherente.

{{< text syntax=bash snip_id=upgrade_ambient_aio >}}
$ helm upgrade istio-ambient istio/ambient -n istio-system --wait
{{< /text >}}

### Actualizar el chart de la gateway desplegado manualmente (opcional)

Las `Gateway` que se [desplegaron manualmente](/es/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment) deben actualizarse individualmente usando Helm:

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

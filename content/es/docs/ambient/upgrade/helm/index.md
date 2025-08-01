---
title: Actualizar con Helm
description: Actualización de una instalación en modo ambient con Helm.
weight: 5
aliases:
  - /docs/ops/ambient/upgrade/helm-upgrade
  - /latest/docs/ops/ambient/upgrade/helm-upgrade
  - /docs/ambient/upgrade/helm
  - /latest/docs/ambient/upgrade/helm
owner: istio/wg-environments-maintainers
test: yes
---

Sigue esta guía para actualizar y configurar una instalación en modo ambient usando
[Helm](https://helm.sh/docs/). Esta guía asume que ya has realizado una [instalación en modo ambient con Helm](/es/docs/ambient/install/helm/) con una versión anterior de Istio.

{{< warning >}}
A diferencia del modo sidecar, el modo ambient admite mover los pods de la aplicación a un proxy ztunnel actualizado sin un reinicio o reprogramación obligatorios de los pods de la aplicación en ejecución. Sin embargo, la actualización de ztunnel **provocará** que todas las conexiones TCP de larga duración en el nodo actualizado se restablezcan, e Istio actualmente no admite actualizaciones canary de ztunnel, **incluso con el uso de revisiones**.

Se recomienda el acordonamiento de nodos y los grupos de nodos azul/verde para limitar el radio de explosión de los restablecimientos en el tráfico de la aplicación durante las actualizaciones de producción. Consulta la documentación de tu proveedor de Kubernetes para obtener más detalles.
{{< /warning >}}

## Entendiendo las actualizaciones del modo ambient

Todas las actualizaciones de Istio implican la actualización del control plane, el data plane y las CRD de Istio. Debido a que el data plane ambient se divide en [dos componentes](/es/docs/ambient/architecture/data-plane), el ztunnel y las gateways (que incluyen waypoints), las actualizaciones implican pasos separados para estos componentes. La actualización del control plane y las CRD se trata aquí brevemente, pero es esencialmente idéntica al [proceso para actualizar estos componentes en modo sidecar](/es/docs/setup/upgrade/canary/).

Al igual que el modo sidecar, las gateways pueden hacer uso de [etiquetas de revisión](/es/docs/setup/upgrade/canary/#stable-revision-labels) para permitir un control detallado sobre las actualizaciones (de la {{< gloss >}}gateway{{< /gloss >}}), incluidos los waypoints, con controles simples para revertir a una versión anterior del control plane de Istio en cualquier momento. Sin embargo, a diferencia del modo sidecar, el ztunnel se ejecuta como un DaemonSet, un proxy por nodo, lo que significa que las actualizaciones de ztunnel afectan, como mínimo, a un nodo completo a la vez. Si bien esto puede ser aceptable en muchos casos, las aplicaciones with conexiones TCP de larga duración pueden verse interrumpidas. En tales casos, recomendamos usar el acordonamiento y el drenaje de nodos antes de actualizar el ztunnel para un nodo determinado. En aras de la simplicidad, este documento demostrará las actualizaciones in-place del ztunnel, que pueden implicar un breve tiempo de inactividad.

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

{{< tabset category-name="upgrade-prerequisites" >}}

{{< tab name="Actualización in-place" category-value="in-place" >}}

No se necesitan preparaciones adicionales para las actualizaciones in-place, procede al siguiente paso.

{{< /tab >}}

{{< tab name="Actualización con revisión" category-value="revisions" >}}

### Organiza tus etiquetas y revisiones

Para actualizar un mesh en modo ambient de manera controlada, recomendamos que tus gateways y namespaces usen la etiqueta `istio.io/rev` para especificar una etiqueta de revisión para controlar qué versiones de gateway y control plane se usarán para administrar el tráfico de tus workloads. Recomendamos dividir tu cluster de producción en múltiples etiquetas para organizar tu actualización. Todos los miembros de una etiqueta determinada se actualizarán simultáneamente, por lo que es aconsejable comenzar la actualización con tus aplicaciones de menor riesgo. No recomendamos hacer referencia a las revisiones directamente a través de etiquetas para las actualizaciones, ya que este proceso puede resultar fácilmente en la actualización accidental de una gran cantidad de proxies y es difícil de segmentar. Para ver qué etiquetas y revisiones estás usando en tu cluster, consulta la sección sobre la actualización de etiquetas.

### Elige un nombre de revisión

Las revisiones identifican instancias únicas del control plane de Istio, lo que te permite ejecutar múltiples versiones distintas del control plane simultáneamente en una sola malla.

Se recomienda que las revisiones permanezcan inmutables, es decir, una vez que se instala un control plane con un nombre de revisión en particular, la instalación no debe modificarse y el nombre de la revisión no debe reutilizarse. Las etiquetas, por otro lado, son punteros mutables a las revisiones. Esto permite que un operador de cluster realice actualizaciones del data plane sin la necesidad de ajustar ninguna etiqueta de workload, simplemente moviendo una etiqueta de una revisión a la siguiente. Todos los planos de datos se conectarán solo a un control plane, especificado por la etiqueta `istio.io/rev` (que apunta a una revisión o una etiqueta), o por la revisión predeterminada si no hay ninguna etiqueta `istio.io/rev` presente. La actualización de un data plane consiste simplemente en cambiar el control plane al que apunta modificando las etiquetas o editando las etiquetas.

Debido a que las revisiones están destinadas a ser inmutables, recomendamos elegir un nombre de revisión que se corresponda con la versión de Istio que estás instalando, como `1-22-1`. Además de elegir un nuevo nombre de revisión, debes anotar tu nombre de revisión actual. Puedes encontrarlo ejecutando:

{{< text syntax=bash snip_id=list_revisions >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/rev,!istio.io/tag' -L istio\.io/rev
$ # Almacena tu revisión y nueva revisión en variables:
$ export REVISION=istio-1-22-1
$ export OLD_REVISION=istio-1-21-2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Actualizar el control plane

### Componentes base

{{< boilerplate crd-upgrade-123 >}}

Las Definiciones de Recursos Personalizados (CRD) de todo el cluster deben actualizarse antes del despliegue de una nueva versión del control plane:

{{< text syntax=bash snip_id=upgrade_crds >}}
$ helm upgrade istio-base istio/base -n istio-system
{{< /text >}}

### control plane istiod

El control plane [Istiod](/es/docs/ops/deployment/architecture/#istiod) gestiona y configura los proxies que enrutan el tráfico dentro de la mesh. El siguiente comando instalará una nueva instancia del control plane junto con la actual, pero no introducirá nuevos proxies de gateway o waypoints, ni tomará el control de los existentes.

Si has personalizado tu instalación de istiod, puedes reutilizar el archivo `values.yaml` de actualizaciones o instalaciones anteriores para mantener la coherencia de tus planos de control.

{{< tabset category-name="upgrade-control-plane" >}}

{{< tab name="Actualización in-place" category-value="in-place" >}}

{{< text syntax=bash snip_id=upgrade_istiod_inplace >}}
$ helm upgrade istiod istio/istiod -n istio-system --wait
{{< /text >}}

{{< /tab >}}

{{< tab name="Actualización con revisión" category-value="revisions" >}}

{{< text syntax=bash snip_id=upgrade_istiod_revisioned >}}
$ helm install istiod-"$REVISION" istio/istiod -n istio-system --set revision="$REVISION" --set profile=ambient --wait
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Agente de nodo CNI

El agente de nodo CNI de Istio es responsable de detectar los pods agregados a la mesh ambient, informar a ztunnel que se deben establecer los puertos de proxy dentro de los pods agregados y configurar la redirección del tráfico dentro del namespace de red del pod. No forma parte del data plane ni del control plane.

El CNI en la versión 1.x es compatible con el control plane en la versión 1.x+1 y 1.x. Esto significa que el control plane debe actualizarse antes que el CNI de Istio, siempre que la diferencia de versión sea de una versión menor.

{{< warning >}}
Istio actualmente no admite actualizaciones canary de istio-cni, **incluso con el uso de revisiones**. Si esto es una preocupación de interrupción significativa para tu entorno, o si se desean controles de radio de explosión más estrictos para las actualizaciones de CNI, se recomienda posponer las actualizaciones de `istio-cni` hasta que los propios nodos se drenen y actualicen, o aprovechar los taints de los nodos y orquestar manualmente la actualización para este componente.

El agente de nodo CNI de Istio es un DaemonSet [system-node-critical](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/). **Debe** estar ejecutándose en cada nodo para que se mantengan las garantías de seguridad y operativas del tráfico ambient de Istio en ese nodo. De forma predeterminada, el DaemonSet del agente de nodo CNI de Istio admite actualizaciones seguras in-place y, mientras se actualiza o reinicia, evitará que se inicien nuevos pods en ese nodo hasta que haya una instancia del agente disponible en el nodo para manejarlos, con el fin de evitar fugas de tráfico no seguras. Los pods existentes que ya se hayan agregado con éxito a la mesh ambient antes de la actualización continuarán operando bajo los requisitos de seguridad de tráfico de Istio durante la actualización.
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_cni >}}
$ helm upgrade istio-cni istio/cni -n istio-system
{{< /text >}}

## Actualizar el data plane

### DaemonSet de ztunnel

El DaemonSet de {{< gloss >}}ztunnel{{< /gloss >}} es el componente de proxy de nodo. El ztunnel en la versión 1.x es compatible con el control plane en la versión 1.x+1 y 1.x. Esto significa que el control plane debe actualizarse antes que ztunnel, siempre que la diferencia de versión sea de una versión menor. Si has personalizado previamente tu instalación de ztunnel, puedes reutilizar el archivo `values.yaml` de actualizaciones o instalaciones anteriores para mantener la coherencia de tu {{< gloss >}}data plane{{< /gloss >}}.

{{< warning >}}
La actualización de ztunnel in-place interrumpirá brevemente todo el tráfico de la mesh ambient en el nodo, **incluso con el uso de revisiones**. En la práctica, el período de interrupción es una ventana muy pequeña, que afecta principalmente a las conexiones de larga duración.

Se recomienda el acordonamiento de nodos y los grupos de nodos azul/verde para mitigar el riesgo del radio de explosión durante las actualizaciones de producción. Consulta la documentación de tu proveedor de Kubernetes para obtener más detalles.
{{< /warning >}}

{{< tabset category-name="upgrade-ztunnel" >}}

{{< tab name="Actualización in-place" category-value="in-place" >}}

{{< text syntax=bash snip_id=upgrade_ztunnel_inplace >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system --wait
{{< /text >}}

{{< /tab >}}

{{< tab name="Actualización con revisión" category-value="revisions" >}}

{{< text syntax=bash snip_id=upgrade_ztunnel_revisioned >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system --set revision="$REVISION" --wait
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< tabset category-name="change-gateway-revision" >}}

{{< tab name="Actualización in-place" category-value="in-place" >}}

### Actualizar el chart de la gateway desplegado manualmente (opcional)

Las `Gateway` que se [desplegaron manualmente](/es/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment) deben actualizarse individualmente usando Helm:

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

{{< /tab >}}

{{< tab name="Actualización con revisión" category-value="revisions" >}}

### Actualizar waypoints y gateways usando etiquetas

Si has seguido las mejores prácticas, todas tus gateways, workloads y namespaces usan la revisión predeterminada (efectivamente, una etiqueta llamada `default`), o la etiqueta `istio.io/rev` con el valor establecido en un nombre de etiqueta. Ahora puedes actualizar todos estos a la nueva versión del data plane de Istio moviendo sus etiquetas para que apunten a la nueva versión, una a la vez. Para listar todas las etiquetas en tu cluster, ejecuta:

{{< text syntax=bash snip_id=list_tags >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/tag' -L istio\.io/tag,istio\.io/rev
{{< /text >}}

Para cada etiqueta, puedes actualizar la etiqueta ejecutando el siguiente comando, reemplazando `$MYTAG` con tu nombre de etiqueta y `$REVISION` con tu nombre de revisión:

{{< text syntax=bash snip_id=upgrade_tag >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$REVISION" -n istio-system | kubectl apply -f -
{{< /text >}}

Esto actualizará todos los objetos que hacen referencia a esa etiqueta, excepto aquellos que usan el [modo de despliegue manual de la gateway](/es/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment), que se tratan a continuación, y los sidecars, que no se usan en el modo ambient.

Se recomienda que supervises de cerca la salud de las aplicaciones que usan el data plane actualizado antes de actualizar la siguiente etiqueta. Si detectas un problema, puedes revertir una etiqueta, restableciéndola para que apunte al nombre de tu revisión anterior:

{{< text syntax=bash snip_id=rollback_tag >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$OLD_REVISION" -n istio-system | kubectl apply -f -
{{< /text >}}

### Actualizar las gateways desplegadas manualmente (opcional)

Las `Gateway` que se [desplegaron manualmente](/es/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment) deben actualizarse individualmente usando Helm:

{{< text syntax=bash snip_id=upgrade_gateway >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

## Desinstalar el control plane anterior

Si has actualizado todos los componentes del data plane para usar la nueva revisión del control plane de Istio y estás satisfecho de que no necesitas revertir, puedes eliminar la revisión anterior del control plane ejecutando:

{{< text syntax=bash snip_id=delete_old_revision >}}
$ helm delete istiod-"$OLD_REVISION" -n istio-system
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

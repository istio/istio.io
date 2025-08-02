---
title: Instalar con Helm (simple)
description: Instalar Istio con soporte para el modo ambient con Helm usando un solo chart.
weight: 4
owner: istio/wg-environments-maintainers
test: yes
draft: true
---

{{< tip >}}
Sigue esta guía para instalar y configurar un mesh de Istio con soporte para el modo ambient.
Si eres nuevo en Istio y solo quieres probarlo, sigue las
[instrucciones de inicio rápido](/es/docs/ambient/getting-started) en su lugar.
{{< /tip >}}

Recomendamos el uso de Helm para instalar Istio para uso en producción en modo ambient. Para permitir actualizaciones controladas, los componentes del control plane y del data plane se empaquetan e instalan por separado. (Debido a que el data plane ambient se divide en [dos componentes](/es/docs/ambient/architecture/data-plane), el ztunnel y los waypoints, las actualizaciones implican pasos separados para estos componentes).

## Prerrequisitos

1. Comprueba los [Prerrequisitos específicos de la plataforma](/es/docs/ambient/install/platform-prerequisites).

1. [Instala el cliente de Helm](https://helm.sh/docs/intro/install/), versión 3.6 o superior.

1. Configura el repositorio de Helm:

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

<!-- ### Componentes base -->

<!-- El chart `base` contiene las CRD básicas y los roles de cluster necesarios para configurar Istio. -->
<!-- Esto debe instalarse antes que cualquier otro componente de Istio. -->

<!-- {{< text syntax=bash snip_id=install_base >}} -->
<!-- $ helm install istio-base istio/base -n istio-system --create-namespace --wait -->
<!-- {{< /text >}} -->

### Instalar o actualizar las CRD de la API de Gateway de Kubernetes

{{< boilerplate gateway-api-install-crds >}}

### Instalar el control plane y el data plane ambient de Istio

El chart `ambient` instala todos los componentes del data plane y del control plane de Istio necesarios para
ambient, utilizando un chart contenedor de Helm que compone los charts de los componentes individuales.

{{< warning >}}
Ten en cuenta que si instalas todo como parte de este chart contenedor, solo puedes actualizar o desinstalar
ambient a través de este chart contenedor; no puedes actualizar o desinstalar subcomponentes individualmente.
{{< /warning >}}

{{< text syntax=bash snip_id=install_ambient_aio >}}
$ helm install istio-ambient istio/ambient --namespace istio-system --create-namespace --wait
{{< /text >}}

### gateway de entrada (opcional)

{{< tip >}}
{{< boilerplate gateway-api-future >}}
Si usas la API de Gateway, no necesitas instalar y administrar un chart de Helm de gateway de entrada como se describe a continuación.
Consulta la [tarea de la API de Gateway](/es/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment) para obtener más detalles.
{{< /tip >}}

Para instalar una gateway de entrada, ejecuta el siguiente comando:

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
{{< /text >}}

Si tu cluster de Kubernetes no admite el tipo de servicio `LoadBalancer` (`type: LoadBalancer`) con una IP externa adecuada asignada, ejecuta el comando anterior sin el parámetro `--wait` para evitar la espera infinita. Consulta [Instalación de gateways](/es/docs/setup/additional-setup/gateway/) para obtener documentación detallada sobre la instalación de gateways.

## Configuración

El chart contenedor ambient compone los siguientes charts de componentes de Helm

- base
- istiod
- istio-cni
- ztunnel

Los valores de configuración predeterminados se pueden cambiar usando uno o más argumentos `--set <parameter>=<value>`. Alternativamente, puedes especificar varios parámetros en un archivo de valores personalizado usando el argumento `--values <file>`.

Puedes anular la configuración a nivel de componente a través del chart contenedor de la misma manera que puedes hacerlo al instalar
los componentes individualmente, prefijando la ruta del valor con el nombre del componente.

Ejemplo:

{{< text syntax=bash snip_id=none >}}
$ helm install istiod istio/istiod --set hub=gcr.io/istio-testing
{{< /text >}}

Se convierte en:

{{< text syntax=bash snip_id=none >}}
$ helm install istio-ambient istio/ambient --set istiod.hub=gcr.io/istio-testing
{{< /text >}}

cuando se establece a través del chart contenedor.

Para ver las opciones de configuración admitidas y la documentación de cada subcomponente, ejecuta:

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

para cada componente que te interese.

Los detalles completos sobre cómo usar y personalizar las instalaciones de Helm están disponibles en [la documentación de instalación de sidecar](/es/docs/setup/install/helm/).

## Verificar la instalación

### Verificar el estado de el workload

Después de instalar todos los componentes, puedes verificar el estado del despliegue de Helm con:

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
istio-ambient      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ambient-{{< istio_full_version >}}     {{< istio_full_version >}}
{{< /text >}}

Puedes verificar el estado de los pods desplegados con:

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
NAME                             READY   STATUS    RESTARTS   AGE
istio-cni-node-g97z5             1/1     Running   0          10m
istiod-5f4c75464f-gskxf          1/1     Running   0          10m
ztunnel-c2z4s                    1/1     Running   0          10m
{{< /text >}}

### Verificar con la aplicación de ejemplo

Después de instalar el modo ambient con Helm, puedes seguir la guía [Desplegar la aplicación de ejemplo](/es/docs/ambient/getting-started/deploy-sample-app/) para desplegar la aplicación de ejemplo y las gateways de entrada, y luego puedes
[agregar tu aplicación a la mesh ambient](/es/docs/ambient/getting-started/secure-and-visualize/#add-bookinfo-to-the-mesh).

## Desinstalar

Puedes desinstalar Istio y sus componentes desinstalando el chart
instalado anteriormente.

1. Desinstalar todos los componentes de Istio

    {{< text syntax=bash snip_id=delete_ambient_aio >}}
    $ helm delete istio-ambient -n istio-system
    {{< /text >}}

1. (Opcional) Eliminar cualquier instalación del chart de la gateway de Istio:

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. Eliminar las CRD instaladas por Istio (opcional)

    {{< warning >}}
    Esto eliminará todos los recursos de Istio creados.
    {{< /warning >}}

    {{< text syntax=bash snip_id=delete_crds >}}
    $ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
    {{< /text >}}

1. Eliminarel namespace `istio-system`:

    {{< text syntax=bash snip_id=delete_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

---
title: Instalar con Helm
description: Instalar Istio con soporte para el modo ambient con Helm.
weight: 4
aliases:
  - /docs/ops/ambient/install/helm-installation
  - /latest/docs/ops/ambient/install/helm-installation
  - /docs/ambient/install/helm-installation
  - /latest/docs/ambient/install/helm-installation
owner: istio/wg-environments-maintainers
test: yes
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

## Instalar el control plane

Los valores de configuración predeterminados se pueden cambiar usando uno o más argumentos `--set <parameter>=<value>`. Alternativamente, puedes especificar varios parámetros en un archivo de valores personalizado usando el argumento `--values <file>`.

{{< tip >}}
Puedes mostrar los valores predeterminados de los parámetros de configuración usando el comando `helm show values <chart>` o consultar la documentación del chart de Artifact Hub para los parámetros de configuración de los charts [base](https://artifacthub.io/packages/helm/istio-official/base?modal=values), [istiod](https://artifacthub.io/packages/helm/istio-official/istiod?modal=values), [CNI](https://artifacthub.io/packages/helm/istio-official/cni?modal=values), [ztunnel](https://artifacthub.io/packages/helm/istio-official/ztunnel?modal=values) y [Gateway](https://artifacthub.io/packages/helm/istio-official/gateway?modal=values).
{{< /tip >}}

Los detalles completos sobre cómo usar y personalizar las instalaciones de Helm están disponibles en [la documentación de instalación de sidecar](/es/docs/setup/install/helm/).

A diferencia de los perfiles de [istioctl](/es/docs/ambient/install/istioctl/), que agrupan los componentes que se instalarán o eliminarán, los perfiles de Helm simplemente establecen grupos de valores de configuración.

### Componentes base

El chart `base` contiene las CRD básicas y los roles de cluster necesarios para configurar Istio.
Esto debe instalarse antes que cualquier otro componente de Istio.

{{< text syntax=bash snip_id=install_base >}}
$ helm install istio-base istio/base -n istio-system --create-namespace --wait
{{< /text >}}

### Instalar o actualizar las CRD de la API de Gateway de Kubernetes

{{< boilerplate gateway-api-install-crds >}}

### control plane istiod

El chart `istiod` instala una revisión de Istiod. Istiod es el componente del control plane que gestiona y
configura los proxies para enrutar el tráfico dentro de la mesh.

{{< text syntax=bash snip_id=install_istiod >}}
$ helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait
{{< /text >}}

### Agente de nodo CNI

El chart `cni` instala el agente de nodo CNI de Istio. Es responsable de detectar los pods que pertenecen a la mesh ambient y de configurar la redirección del tráfico entre los pods y el proxy de nodo ztunnel (que se instalará más adelante).

{{< text syntax=bash snip_id=install_cni >}}
$ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait
{{< /text >}}

## Instalar el data plane

### DaemonSet de ztunnel

El chart `ztunnel` instala el DaemonSet de ztunnel, que es el componente de proxy de nodo del modo ambient de Istio.

{{< text syntax=bash snip_id=install_ztunnel >}}
$ helm install ztunnel istio/ztunnel -n istio-system --wait
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

Para ver las opciones de configuración admitidas y la documentación, ejecuta:

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

## Verificar la instalación

### Verificar el estado de el workload

Después de instalar todos los componentes, puedes verificar el estado del despliegue de Helm con:

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
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

Puedes desinstalar Istio y sus componentes desinstalando los charts
instalados anteriormente.

1. Listar todos los charts de Istio instalados enel namespace `istio-system`:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
    istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
    istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
    istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
    ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
    {{< /text >}}

1. (Opcional) Eliminar cualquier instalación del chart de la gateway de Istio:

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. Eliminar el chart de ztunnel:

    {{< text syntax=bash snip_id=delete_ztunnel >}}
    $ helm delete ztunnel -n istio-system
    {{< /text >}}

1. Eliminar el chart de CNI de Istio:

    {{< text syntax=bash snip_id=delete_cni >}}
    $ helm delete istio-cni -n istio-system
    {{< /text >}}

1. Eliminar el chart del control plane de istiod:

    {{< text syntax=bash snip_id=delete_istiod >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Eliminar el chart base de Istio:

    {{< tip >}}
    Por diseño, eliminar un chart a través de Helm no elimina las Definiciones de Recursos Personalizados (CRD)
    instaladas a través del chart.
    {{< /tip >}}

    {{< text syntax=bash snip_id=delete_base >}}
    $ helm delete istio-base -n istio-system
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

## Generar un manifiesto antes de la instalación

Puedes generar los manifiestos para cada componente antes de instalar Istio usando el
subcomando `helm template`.
Por ejemplo, para generar un manifiesto que se pueda instalar con `kubectl` para el componente `istiod`:

{{< text syntax=bash snip_id=none >}}
$ helm template istiod istio/istiod -n istio-system --kube-version {Versión de Kubernetes del cluster de destino} > istiod.yaml
{{< /text >}}

El manifiesto generado se puede usar para inspeccionar qué se instala exactamente, así como para realizar un seguimiento de los cambios
en el manifiesto a lo largo del tiempo.

{{< tip >}}
Cualquier bandera adicional o anulación de valores personalizados que normalmente usarías para la instalación también debe
proporcionarse al comando `helm template`.
{{< /tip >}}

Para instalar el manifiesto generado anteriormente, que creará el componente `istiod` en el cluster de destino:

{{< text syntax=bash snip_id=none >}}
$ kubectl apply -f istiod.yaml
{{< /text >}}

{{< warning >}}
Si intentas instalar y administrar Istio usando `helm template`, ten en cuenta las siguientes advertencias:

1.el namespace de Istio (`istio-system` por defecto) debe crearse manualmente.

1. Es posible que los recursos no se instalen con la misma secuencia de dependencias que
`helm install`

1. Este método no se prueba como parte de las versiones de Istio.

1. Si bien `helm install` detectará automáticamente la configuración específica del entorno de tu contexto de Kubernetes,
`helm template` no puede hacerlo ya que se ejecuta sin conexión, lo que puede dar lugar a resultados inesperados. En particular, debes asegurarte
de seguir [estos pasos](/es/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) si tu
entorno de Kubernetes no admite tokens de cuenta de servicio de terceros.

1. `kubectl apply` del manifiesto generado puede mostrar errores transitorios debido a que los recursos no están disponibles en el
cluster en el orden correcto.

1. `helm install` elimina automáticamente cualquier recurso que deba eliminarse cuando cambia la configuración (por ejemplo,
si eliminas una gateway). Esto no sucede cuando usas `helm template` con `kubectl`, y estos
recursos deben eliminarse manualmente.

{{< /warning >}}

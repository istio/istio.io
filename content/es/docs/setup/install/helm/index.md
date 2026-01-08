---
title: Instalar con Helm
linktitle: Instalar con Helm
description: Instrucciones para instalar y configurar Istio en un cluster de Kubernetes usando Helm.
weight: 30
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
test: yes
---

Sigue esta guía para instalar y configurar un mesh de Istio usando
[Helm](https://helm.sh/docs/).

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-prereqs >}}

## Pasos de instalación

Esta sección describe el procedimiento para instalar Istio usando Helm. La sintaxis general para instalación con helm es:

{{< text syntax=bash snip_id=none >}}
$ helm install <release> <chart> --namespace <namespace> --create-namespace [--set <other_parameters>]
{{< /text >}}

Las variables especificadas en el comando son las siguientes:
* `<chart>` Un camino a un chart empaquetado, un camino a un directorio de chart desempaquetado o una URL.
* `<release>` Un nombre para identificar y gestionar el chart de Helm una vez instalado.
* `<namespace>` El Namespace en el cual el chart debe ser instalado.

Los valores de configuración por defecto pueden ser cambiados usando uno o más argumentos `--set <parámetro>=<valor>`. Alternativamente, puedes especificar varios parámetros en un archivo de valores personalizados usando el argumento `--values <archivo>`.

{{< tip >}}
Puedes mostrar los valores por defecto de los parámetros de configuración usando el comando `helm show values <chart>` o referirte a la documentación del chart en `artifacthub` en [Parámetros de definición de recursos personalizados](https://artifacthub.io/packages/helm/istio-official/base?modal=values), [Configuración del chart de istiod](https://artifacthub.io/packages/helm/istio-official/istiod?modal=values) y [Configuración del chart de gateway](https://artifacthub.io/packages/helm/istio-official/gateway?modal=values).
{{< /tip >}}

1. Instala el chart base de Istio que contiene las definiciones de recursos personalizados de nivel de cluster (CRDs) que deben ser instaladas antes de la implementación del control plane de Istio:

    {{< warning >}}
    Al realizar una instalación revisada, el chart base requiere el valor `--set defaultRevision=<revisión>` para que la validación de recursos funcione. A continuación instalamos la revisión `default`, por lo que `--set defaultRevision=default` está configurado.
    {{< /warning >}}

    {{< text syntax=bash snip_id=install_base >}}
    $ helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace
    {{< /text >}}

1. Valida la instalación de CRDs con el comando `helm ls`:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED                                 STATUS   CHART        APP VERSION
    istio-base istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed base-{{< istio_full_version >}}  {{< istio_full_version >}}
    {{< /text >}}

    En la salida, localiza la entrada para `istio-base` y asegúrate de que el estado esté configurado a `deployed`.

1. Si planeas usar el chart de Istio CNI, debes hacerlo ahora. Consulta [Instalar Istio con el plugin CNI](/es/docs/setup/additional-setup/cni/#installing-with-helm) para más información.

1. Instala el chart de discovery de Istio que implementa el servicio `istiod`:

    {{< text syntax=bash snip_id=install_discovery >}}
    $ helm install istiod istio/istiod -n istio-system --wait
    {{< /text >}}

1. Verifica la instalación del chart de discovery de Istio:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED                                 STATUS   CHART         APP VERSION
    istio-base istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed base-{{< istio_full_version >}}   {{< istio_full_version >}}
    istiod     istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed istiod-{{< istio_full_version >}} {{< istio_full_version >}}
    {{< /text >}}

1. Obtén el estado del chart de helm instalado para asegurarte de que esté desplegado:

    {{< text syntax=bash >}}
    $ helm status istiod -n istio-system
    NAME: istiod
    LAST DEPLOYED: Fri Jan 20 22:00:44 2023
    NAMESPACE: istio-system
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    "istiod" successfully installed!

    Para aprender más sobre la release, intenta:
      $ helm status istiod
      $ helm get all istiod

    Pasos siguientes:
      * Implementar un Gateway: https://istio.io/latest/docs/setup/additional-setup/gateway/
      * Prueba nuestras tareas para empezar con configuraciones comunes:
        * https://istio.io/latest/docs/tasks/traffic-management
        * https://istio.io/latest/docs/tasks/security/
        * https://istio.io/latest/docs/tasks/policy-enforcement/
        * https://istio.io/latest/docs/tasks/policy-enforcement/
      * Revisa la lista de releases soportados, publicaciones de CVE y nuestra guía de fortalecimiento:
        * https://istio.io/latest/docs/releases/supported-releases/
        * https://istio.io/latest/news/security/
        * https://istio.io/latest/docs/ops/best-practices/security/

    Para más documentación, consulta el sitio web de https://istio.io

    Cuéntanos cómo fue tu experiencia de instalación/actualización en https://forms.gle/99uiMML96AmsXY5d6
    {{< /text >}}

1. Verifica que el servicio `istiod` se haya instalado correctamente y que sus pods estén corriendo:

    {{< text syntax=bash >}}
    $ kubectl get deployments -n istio-system --output wide
    NAME     READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                         SELECTOR
    istiod   1/1     1            1           10m   discovery    docker.io/istio/pilot:{{< istio_full_version >}}   istio=pilot
    {{< /text >}}

1. (Opcional) Instala un gateway de entrada:

    {{< text syntax=bash snip_id=install_ingressgateway >}}
    $ kubectl create namespace istio-ingress
    $ helm install istio-ingress istio/gateway -n istio-ingress --wait
    {{< /text >}}

    Consulta [Instalar Gateways](/es/docs/setup/additional-setup/gateway/) para documentación detallada sobre la instalación del gateway.

    {{< warning >}}
    El Namespace en el que se implementa el gateway debe no tener una etiqueta `istio-injection=disabled`.
    Consulta [Controlar la política de inyección](/es/docs/setup/additional-setup/sidecar-injection/#controlling-the-injection-policy) para más información.
    {{< /warning >}}

{{< tip >}}
Consulta [Personalización avanzada del chart de Helm](/es/docs/setup/additional-setup/customize-installation-helm/) para documentación detallada sobre cómo usar
el post-renderer de Helm para personalizar los charts.
{{< /tip >}}

## Actualizar tu configuración de Istio

Puedes proporcionar configuraciones de sobrescritura específicas para cualquier chart de Helm de Istio usado anteriormente
y sigue el flujo de actualización de Helm para personalizar tu instalación de meshde Istio. Las opciones configurables pueden ser encontradas usando `helm show values istio/<chart>`;
por ejemplo `helm show values istio/gateway`.

### Migrar de instalaciones no-Helm

Si estás migrando de una versión de Istio instalada usando `istioctl` a Helm (Istio 1.5 o anterior), necesitas eliminar los recursos actuales del control plane de Istio y re-instalar Istio usando Helm tal como se describe anteriormente. Al eliminar la instalación actual de Istio, no debes eliminar las definiciones de recursos personalizados de Istio (CRDs) ya que eso puede llevar a la pérdida de tus recursos personalizados de Istio.

{{< warning >}}
Se recomienda tomar una copia de tus recursos de Istio usando los pasos
descritos anteriormente antes de eliminar la instalación actual de Istio en tu cluster.
{{< /warning >}}

Puedes seguir los pasos mencionados en la [Guía de desinstalación de istioctl](/es/docs/setup/install/istioctl#uninstall-istio).

## Desinstalar

Puedes desinstalar Istio y sus componentes desinstalando los charts
instalados anteriormente.

1. Lista todos los charts de Istio instalados en el namespace `istio-system`:

    {{< text syntax=bash snip_id=helm_ls >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED                                 STATUS   CHART         APP VERSION
    istio-base istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed base-{{< istio_full_version >}}   {{< istio_full_version >}}
    istiod     istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed istiod-{{< istio_full_version >}} {{< istio_full_version >}}
    {{< /text >}}

1. (Opcional) Elimina cualquier instalación de charts de gateway de Istio:

    {{< text syntax=bash snip_id=delete_delete_gateway_charts >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. Elimina el chart de discovery de Istio:

    {{< text syntax=bash snip_id=helm_delete_discovery_chart >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. Elimina el chart base de Istio:

    {{< tip >}}
    Por diseño, la eliminación de un chart a través de Helm no elimina las
    definiciones de recursos personalizados (CRDs) instaladas a través del chart.
    {{< /tip >}}

    {{< text syntax=bash snip_id=helm_delete_base_chart >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. Elimina el namespace `istio-system`:

    {{< text syntax=bash snip_id=delete_istio_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

## Desinstalar recursos de la etiqueta de revisión estable

Si decides continuar usando el control plane anterior, en lugar de completar la actualización,
puedes desinstalar la revisión más reciente y su etiqueta por primera vez
`helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags={prod-canary} --set revision=canary -n istio-system | kubectl delete -f -`.
Luego, debes desinstalar la revisión de Istio que apuntaba siguiendo el procedimiento de desinstalación anterior.

Si instalaste los gateways (s) para esta revisión usando actualizaciones in-place, también debes reinstalar los gateways (s) para la revisión anterior manualmente.
La eliminación de la revisión anterior y sus etiquetas no revertirá automáticamente los gateways (s) previamente actualizados.

### (Opcional) Eliminar CRDs instalados por Istio

La eliminación permanente de CRDs elimina cualquier recurso de Istio que hayas creado en tu cluster.
Para eliminar CRDs de Istio instalados en tu cluster:

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
{{< /text >}}

## Generar un manifiesto antes de la instalación

Puedes generar los manifiestos para cada componente antes de instalar Istio usando el subcomando `helm template`.
Por ejemplo, para generar un manifiesto que puede ser instalado con `kubectl` para el componente `istiod`:

{{< text syntax=bash snip_id=none >}}
$ helm template istiod istio/istiod -n istio-system --kube-version {Kubernetes version of target cluster} > istiod.yaml
{{< /text >}}

El manifiesto generado puede ser usado para inspeccionar exactamente qué está instalado así como para rastrear los cambios en el manifiesto a lo largo del tiempo.

{{< tip >}}
Cualquier flag adicional o sobrescritura de valores personalizados que normalmente usarías para la instalación también deben ser suministrados al comando `helm template`.
{{< /tip >}}

Para instalar el manifiesto generado anteriormente, que creará el componente `istiod` en el cluster de destino:

{{< text syntax=bash snip_id=none >}}
$ kubectl apply -f istiod.yaml
{{< /text >}}

{{< warning >}}
Si estás intentando instalar y gestionar Istio usando `helm template`, por favor ten en cuenta los siguientes puntos:

1. El namespace de Istio (`istio-system` por defecto) debe ser creado manualmente.

1. Los recursos pueden no ser instalados con la misma secuenciación de dependencias que
`helm install`

1. Este método no está probado como parte de las releases de Istio.

1. Mientras `helm install` detectará automáticamente las configuraciones específicas del entorno de tu Kubernetes desde tu contexto,
`helm template` no puede hacerlo ya que se ejecuta en línea, lo que puede conducir a resultados inesperados. En particular, debes asegurarte
de que sigas [estos pasos](/es/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) si tu
entorno de Kubernetes no soporta tokens de cuenta de servicio de terceros.

1. `kubectl apply` del manifiesto generado puede mostrar errores transitorios debido a recursos no disponibles en el
cluster en el orden correcto.

1. `helm install` automáticamente poda cualquier recurso que debería ser eliminado cuando la configuración cambia (por ejemplo,
si eliminas un gateway). Esto no sucede cuando usas `helm template` con `kubectl`, y estos
recursos deben ser eliminados manualmente.

{{< /warning >}}

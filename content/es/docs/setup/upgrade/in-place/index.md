---
title: Actualizaciones in-place
description: Actualiza Istio o vuelve a una versión anterior in-place.
weight: 20
keywords: [kubernetes,upgrading,in-place]
owner: istio/wg-environments-maintainers
test: no
---

El comando `istioctl upgrade` realiza una actualización de Istio.

{{< tip >}}
La [actualización canary](/es/docs/setup/upgrade/canary/) es más segura que una actualización in-place y es el método de actualización recomendado.
{{< /tip >}}

El comando de actualización también puede volver Istio a una versión anterior (downgrade).

Consulta la [referencia de `istioctl upgrade`](/es/docs/reference/commands/istioctl/#istioctl-upgrade)
para ver todas las opciones que ofrece el comando `istioctl upgrade`.

{{< warning >}}
`istioctl upgrade` sirve para actualizaciones in-place y no es compatible con instalaciones hechas con
el flag `--revision`. Las actualizaciones de esas instalaciones fallarán con un error.
{{< /warning >}}

## Prerrequisitos de la actualización {#upgrade-prerequisites}

Antes de comenzar el proceso de actualización, revisa los siguientes prerrequisitos:

* La versión de Istio instalada no está más de una versión menor por detrás de la versión a la que actualizas.
   Por ejemplo, necesitas la 1.6.0 o superior antes de comenzar el proceso de actualización a la 1.7.x.

* Tu instalación de Istio se [instaló usando {{< istioctl >}}](/es/docs/setup/install/istioctl/).

## Pasos de actualización {#upgrade-steps}

{{< warning >}}
Puede haber interrupciones del tráfico durante el proceso de actualización. Para minimizarlas, asegúrate de
que haya al menos dos réplicas de `istiod` en ejecución. Además, asegúrate de que los
[`PodDisruptionBudgets`](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
estén configurados con una disponibilidad mínima de 1.
{{< /warning >}}

Los comandos de esta sección deben ejecutarse con la nueva versión de `istioctl`, que
se encuentra en el subdirectorio `bin/` del paquete descargado.

1. [Descarga la nueva versión de Istio](/es/docs/setup/additional-setup/download-istio-release/)
   y cambia al directorio de la nueva versión.

1. Asegúrate de que tu configuración de Kubernetes apunte al clúster que quieres actualizar:

    {{< text bash >}}
    $ kubectl config view
    {{< /text >}}

1. Asegúrate de que la actualización sea compatible con tu entorno.

    {{< text bash >}}
    $ istioctl x precheck
    ✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
    To get started, check out https://istio.io/latest/docs/setup/getting-started/
    {{< /text >}}

1. Inicia la actualización ejecutando este comando:

    {{< text bash >}}
    $ istioctl upgrade
    {{< /text >}}

    {{< warning >}}
    Si instalaste Istio usando el flag `-f`, por ejemplo
    `istioctl install -f <IstioOperator-custom-resource-definition-file>`,
    debes pasar el mismo valor del flag `-f` al comando `istioctl upgrade`.
    {{< /warning >}}

    Si instalaste Istio usando flags `--set`, asegúrate de pasar los mismos flags `--set` al actualizar;
    de lo contrario, se revertirán las personalizaciones hechas con `--set`. Para uso en producción, se recomienda
    usar un archivo de configuración en lugar de `--set`.

    Si omites el flag `-f`, Istio se actualiza usando el perfil por defecto.

    Después de realizar varias comprobaciones, `istioctl` te pedirá que confirmes si quieres continuar.

1. `istioctl` actualizará in-place el control plane y los gateways de Istio a la nueva versión e indicará
   el estado de finalización.

1. Después de que `istioctl` complete la actualización, debes actualizar manualmente el data plane de Istio
   reiniciando todos los pods con sidecars de Istio:

    {{< text bash >}}
    $ kubectl rollout restart deployment
    {{< /text >}}

## Prerrequisitos para volver a una versión anterior {#downgrade-prerequisites}

Antes de comenzar el proceso para volver a una versión anterior, revisa los siguientes prerrequisitos:

* Tu instalación de Istio se [instaló usando {{< istioctl >}}](/es/docs/setup/install/istioctl/).

* La versión de Istio a la que quieres volver no está más de una versión menor por detrás de la versión de Istio instalada.
   Por ejemplo, desde Istio 1.7.x no puedes volver a una versión inferior a la 1.6.0.

* Para volver a una versión anterior, debes usar el binario `istioctl` de la versión
    a la que quieres volver.
    Por ejemplo, si vuelves de Istio 1.7 a la 1.6.5, usa `istioctl`
    versión 1.6.5.

## Pasos para volver a una versión anterior de Istio {#steps-to-downgrade-to-a-lower-istio-version}

Puedes usar `istioctl upgrade` para volver a una versión anterior de Istio. Los pasos son
idénticos al proceso de actualización descrito en la sección anterior, solo que usando el binario `istioctl` correspondiente
a la versión anterior (p. ej., 1.6.5). Al finalizar, Istio volverá a la versión que tenías instalada antes.

Como alternativa, puedes usar `istioctl install` para instalar una versión anterior del control plane de Istio.

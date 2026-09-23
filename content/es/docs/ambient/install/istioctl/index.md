---
title: Instalar con istioctl
description: Instalar Istio con soporte para el modo ambient usando la herramienta de línea de comandos istioctl.
weight: 10
keywords: [istioctl,ambient]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
Sigue esta guía para instalar y configurar un mesh de Istio con soporte para el modo ambient.
Si eres nuevo en Istio y solo quieres probarlo, sigue las
[instrucciones de inicio rápido](/es/docs/ambient/getting-started) en su lugar.
{{< /tip >}}

Esta guía de instalación utiliza la herramienta de línea de comandos
[istioctl](/es/docs/reference/commands/istioctl/). `istioctl`, al igual que otros métodos de instalación, expone muchas opciones de personalización. Además,
ofrece validación de la entrada del usuario para ayudar a prevenir errores de instalación e incluye muchas
herramientas de análisis y configuración posteriores a la instalación.

Usando estas instrucciones, puedes seleccionar cualquiera de los
[perfiles de configuración](/es/docs/setup/additional-setup/config-profiles/) integrados de Istio
y luego personalizar aún más la configuración para tus necesidades específicas.

El comando `istioctl` admite la API completa de [`IstioOperator`](/es/docs/reference/config/istio.operator.v1alpha1/)
a través de opciones de línea de comandos para configuraciones individuales, o pasando un archivo YAML que contiene un
recurso personalizado de `IstioOperator`
{{<gloss CRDs>}}{{</gloss>}}.

## Prerrequisitos

Antes de comenzar, comprueba los siguientes prerrequisitos:

1. [Descarga la versión de Istio](/es/docs/setup/additional-setup/download-istio-release/).
1. Realiza cualquier [configuración específica de la plataforma](/es/docs/ambient/install/platform-prerequisites/) necesaria.

## Instalar o actualizar las CRD de la API de Gateway de Kubernetes

{{< boilerplate gateway-api-install-crds >}}

## Instalar Istio usando el perfil ambient

`istioctl` admite una serie de [perfiles de configuración](/es/docs/setup/additional-setup/config-profiles/) que incluyen diferentes opciones predeterminadas,
y se pueden personalizar para tus necesidades de producción. El soporte para el modo ambient se incluye en el perfil `ambient`. Instala Istio con el
siguiente comando:

{{< text syntax=bash snip_id=install_ambient >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

Este comando instala el perfil `ambient` en el cluster definido por tu
configuración de Kubernetes.

## Configurar y modificar perfiles

La API de instalación de Istio está documentada en la [referencia de la API de `IstioOperator`](/es/docs/reference/config/istio.operator.v1alpha1/). Puedes
usar la opción `--set` para `istioctl install` para modificar parámetros de instalación individuales, o especificar tu propio archivo de configuración con `-f`.

Los detalles completos sobre cómo usar y personalizar las instalaciones de `istioctl` están disponibles en [la documentación de instalación de sidecar](/es/docs/setup/install/istioctl/).

## Desinstalar Istio

Para desinstalar completamente Istio de un cluster, ejecuta el siguiente comando:

{{< text syntax=bash snip_id=uninstall >}}
$ istioctl uninstall --purge -y
{{< /text >}}

{{< warning >}}
La bandera opcional `--purge` eliminará todos los recursos de Istio, incluidos los recursos con ámbito de cluster que pueden compartirse con otros planos de control de Istio.
{{< /warning >}}

Alternativamente, para eliminar solo un control plane de Istio específico, ejecuta el siguiente comando:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall <tus opciones de instalación originales>
{{< /text >}}

El namespaces del control plane (por ejemplo, `istio-system`) no se elimina de forma predeterminada.
Si ya no es necesario, usa el siguiente comando para eliminarlo:

{{< text syntax=bash snip_id=remove_namespace >}}
$ kubectl delete namespace istio-system
{{< /text >}}

## Generar un manifiesto antes de la instalación

Puedes generar el manifiesto antes de instalar Istio usando el
subcomando `manifest generate`.
Por ejemplo, usa el siguiente comando para generar un manifiesto para el perfil `default` que se pueda instalar con `kubectl`:

{{< text syntax=bash snip_id=none >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

El manifiesto generado se puede usar para inspeccionar qué se instala exactamente, así como para realizar un seguimiento de los cambios
en el manifiesto a lo largo del tiempo. Si bien el CR de `IstioOperator` representa la configuración completa del usuario y
es suficiente para realizar un seguimiento, la salida de `manifest generate` también captura posibles cambios
en los charts subyacentes y, por lo tanto, se puede usar para realizar un seguimiento de los recursos instalados reales.

{{< tip >}}
Cualquier bandera adicional o anulación de valores personalizados que normalmente usarías para la instalación también debe
proporcionarse al comando `istioctl manifest generate`.
{{< /tip >}}

{{< warning >}}
Si intentas instalar y administrar Istio usando `istioctl manifest generate`, ten en cuenta las siguientes advertencias:

1. Crea manualmenteel namespace de Istio (`istio-system` por defecto).

1. La validación de Istio no se habilitará de forma predeterminada. A diferencia de `istioctl install`, el comando `manifest generate` no
   creará la configuración del webhook de validación `istiod-default-validator` a menos que se establezca `values.defaultRevision`:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl manifest generate --set values.defaultRevision=default
    {{< /text >}}

1. Es posible que los recursos no se instalen con la misma secuencia de dependencias que
   `istioctl install`.

1. Este método no se prueba como parte de las versiones de Istio.

1. Si bien `istioctl install` detectará automáticamente la configuración específica del entorno de tu contexto de Kubernetes,
   `manifest generate` no puede hacerlo ya que se ejecuta sin conexión, lo que puede dar lugar a resultados inesperados. En particular, debes asegurarte
   de seguir [estos pasos](/es/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) si tu
   entorno de Kubernetes no admite tokens de cuenta de servicio de terceros. Se recomienda agregar
   `--cluster-specific` a tu comando `istio manifest generate` para detectar el entorno del cluster de destino,
   lo que incrustará esa configuración de entorno específica del cluster en los manifiestos generados.
   Esto requiere acceso a la red a tu cluster en ejecución.

1. `kubectl apply` del manifiesto generado puede mostrar errores transitorios debido a que los recursos no están disponibles en el
   cluster en el orden correcto.

1. `istioctl install` elimina automáticamente cualquier recurso que deba eliminarse cuando cambia la configuración (por ejemplo,
   si eliminas una gateway). Esto no sucede cuando usas `istio manifest generate` con `kubectl` y estos
   recursos deben eliminarse manualmente.

{{< /warning >}}

---
title: Instalar con Istioctl
description: Instala y personaliza cualquier perfil de configuración de Istio para evaluación detallada o uso en producción.
weight: 10
keywords: [istioctl,kubernetes]
owner: istio/wg-environments-maintainers
test: no
---

Sigue esta guía para instalar y configurar un mesh de Istio para evaluación detallada o uso en producción.
Si eres nuevo en Istio, y solo quieres probarlo, sigue las
[instrucciones de inicio rápido](/es/docs/setup/getting-started) en su lugar.

Esta guía de instalación usa la herramienta de línea de comandos [istioctl](/es/docs/reference/commands/istioctl/)
para proporcionar una rica personalización del control plane de Istio y de los sidecars para el data plane de Istio.
Tiene validación de entrada del usuario para ayudar a prevenir errores de instalación y opciones de personalización para
sobrescribir cualquier aspecto de la configuración.

Usando estas instrucciones, puedes seleccionar cualquiera de los
[perfiles de configuración](/es/docs/setup/additional-setup/config-profiles/) incorporados de Istio
y luego personalizar aún más la configuración para tus necesidades específicas.

El comando `istioctl` soporta la [`IstioOperator` API](/es/docs/reference/config/istio.operator.v1alpha1/) completa
a través de opciones de línea de comandos para configuraciones individuales o para pasar un archivo yaml que contiene un
{{<gloss CRDs>}}recurso personalizado (CR){{</gloss>}} `IstioOperator`.

## Prerrequisitos

Antes de comenzar, verifica los siguientes prerrequisitos:

1. [Descarga la versión de Istio](/es/docs/setup/additional-setup/download-istio-release/).
1. Realiza cualquier configuración específica de la plataforma ([/es/docs/setup/platform-setup/](/es/docs/setup/platform-setup/)).
1. Verifica los [Requisitos para Pods y Servicios](/es/docs/ops/deployment/application-requirements/).

## Instalar Istio usando el perfil por defecto

La opción más simple es instalar el perfil `default` de Istio
[perfil de configuración](/es/docs/setup/additional-setup/config-profiles/)
usando el siguiente comando:

{{< text bash >}}
$ istioctl install
{{< /text >}}

Este comando instala el perfil `default` en el clúster definido por tu
configuración de Kubernetes. El perfil `default` es un buen punto de partida
para establecer un entorno de producción, a diferencia del perfil `demo` más grande que
está destinado a evaluar un amplio conjunto de características de Istio.

Varias configuraciones pueden modificarse para modificar las instalaciones. Por ejemplo, para habilitar los registros de acceso:

{{< text bash >}}
$ istioctl install --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

{{< tip >}}
Muchos de los ejemplos de esta página y en la documentación en su totalidad están escritos usando `--set` para modificar los parámetros de instalación, en lugar de pasar un archivo de configuración con `-f`. Esto se hace para hacer los ejemplos más compactos.
Los dos métodos son equivalentes, pero `-f` es fuertemente recomendado para producción. El comando anterior se escribiría de la siguiente manera usando `-f`:

{{< text bash >}}
$ cat <<EOF > ./my-config.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
EOF
$ istioctl install -f my-config.yaml
{{< /text >}}

{{< /tip >}}

{{< tip >}}
La API completa está documentada en la [referencia de la API de `IstioOperator`](/es/docs/reference/config/istio.operator.v1alpha1/).
En general, puedes usar la bandera `--set` en `istioctl` como lo harías con
Helm, y la API de `values.yaml` de Helm es actualmente compatible para compatibilidad hacia atrás. La única diferencia es que
debes prefijar las rutas de `values.yaml` heredadas con `values.` porque este es el prefijo para la API de pasatrough de Helm.
{{< /tip >}}

## Instalar desde gráficos externos

Por defecto, `istioctl` usa gráficos compilados para generar el manifiesto de instalación. Estos gráficos se lanzan juntos con
`istioctl` para propósitos de auditoría y personalización y se pueden encontrar en el archivo tar de la versión en el
directorio `manifests`.
`istioctl` también puede usar gráficos externos en lugar de los compilados. Para seleccionar gráficos externos, establece
la bandera `manifests` a un camino de sistema de archivos local:

{{< text bash >}}
$ istioctl install --manifests=manifests/
{{< /text >}}

Si estás usando el binario de `istioctl` {{< istio_full_version >}}, este comando resultará en la misma instalación que `istioctl install` solo, porque apunta a los
mismos gráficos que los compilados.
Aparte de para experimentar con o probar nuevas características, recomendamos usar los gráficos compilados en lugar de externos para asegurar la compatibilidad del
binario de `istioctl` con los gráficos.

## Instalar un perfil diferente

Otros perfiles de configuración de Istio pueden instalarse en un clúster pasando el
nombre del perfil en la línea de comandos. Por ejemplo, el siguiente comando puede usarse
para instalar el perfil `demo`:

{{< text bash >}}
$ istioctl install --set profile=demo
{{< /text >}}

## Generar un manifiesto antes de la instalación

Puedes generar el manifiesto antes de instalar Istio usando el subcomando `manifest generate`.
Por ejemplo, usa el siguiente comando para generar un manifiesto para el perfil `default` que puede ser instalado con `kubectl`:

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

El manifiesto generado puede usarse para inspeccionar exactamente qué se ha instalado así como para rastrear cambios en el manifiesto a lo largo del tiempo. Mientras que el CR `IstioOperator` representa la configuración completa del usuario y es suficiente para rastrearlo, la salida de `manifest generate` también captura posibles cambios en los gráficos subyacentes y, por lo tanto, puede usarse para rastrear los recursos realmente instalados.

{{< tip >}}
Cualquier otra bandera o sobrescritura de valores personalizados que normalmente usarías para la instalación también deberías ser suministrada al comando `istioctl manifest generate`.
{{< /tip >}}

{{< warning >}}
Si estás intentando instalar y gestionar Istio usando `istioctl manifest generate`, por favor ten en cuenta los siguientes advertencias:

1. El espacio de nombres de Istio (`istio-system` por defecto) debe crearse manualmente.

1. La validación de Istio no estará habilitada por defecto. A diferencia de `istioctl install`, el comando `manifest generate`
no creará la configuración de webhook de validador de `istiod-default-validator` a menos que `values.defaultRevision` esté establecido:

    {{< text bash >}}
    $ istioctl manifest generate --set values.defaultRevision=default
    {{< /text >}}

1. Los recursos pueden no instalarse con la misma secuenciación de dependencias que
`istioctl install`.

1. Este método no está probado como parte de las versiones de Istio.

1. Mientras que `istioctl install` detectará automáticamente las configuraciones específicas del entorno de tu contexto de Kubernetes,
`manifest generate` no puede hacerlo porque se ejecuta en línea, lo que puede llevar a resultados inesperados. En particular, debes asegurarte
de que sigas [estos pasos](/es/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) si tu
entorno de Kubernetes no soporta tokens de cuenta de servicio de terceros. Se recomienda añadir `--cluster-specific` a tu comando `istio manifest generate` para detectar el entorno del clúster objetivo, lo que incluirá esos ajustes de entorno específicos del clúster en los manifiestos generados. Esto requiere acceso a red a tu clúster en ejecución.

1. `kubectl apply` del manifiesto generado puede mostrar errores transitorios debido a recursos no disponibles en el
orden correcto en el clúster.

1. `istioctl install` automáticamente poda cualquier recurso que debería ser eliminado cuando la configuración cambia (por ejemplo,
si eliminas un gateway). Esto no ocurre cuando usas `istio manifest generate` con `kubectl` y estos
recursos deben ser eliminados manualmente.

{{< /warning >}}

Consulta [Personalizar la configuración de la instalación](/es/docs/setup/additional-setup/customize-installation/) para obtener más información sobre la personalización de la instalación.

## Desinstalar Istio

Para desinstalar completamente Istio de un clúster, ejecuta el siguiente comando:

{{< text bash >}}
$ istioctl uninstall --purge
{{< /text >}}

{{< warning >}}
La bandera opcional `--purge` eliminará todos los recursos de Istio, incluyendo recursos de nivel de clúster que pueden ser compartidos con otros planes de control de Istio.
{{< /warning >}}

Alternativamente, para eliminar solo un plan de control de Istio específico, ejecuta el siguiente comando:

{{< text bash >}}
$ istioctl uninstall <tus opciones de instalación originales>
{{< /text >}}

o

{{< text bash >}}
$ istioctl manifest generate <tus opciones de instalación originales> | kubectl delete --ignore-not-found=true -f -
{{< /text >}}

El espacio de nombres del plan de control (por ejemplo, `istio-system`) no se elimina por defecto.
Si ya no es necesario, usa el siguiente comando para eliminarlo:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

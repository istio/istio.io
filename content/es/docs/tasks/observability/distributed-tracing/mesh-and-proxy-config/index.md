---
title: Configurar el trazado usando MeshConfig y anotaciones de pod
description: Cómo configurar las opciones de trazado usando MeshConfig y anotaciones de pod.
weight: 3
keywords: [telemetry,tracing]
aliases:
 - /docs/tasks/observability/distributed-tracing/configurability/
 - /docs/tasks/observability/distributed-tracing/configurability/mesh-and-proxy-config/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
status: Beta
---

{{< boilerplate telemetry-tracing-tips >}}

Istio proporciona la capacidad de configurar opciones de trazado avanzadas,
como la tasa de muestreo y la adición de tags personalizados a los spans reportados.

## Antes de empezar

1.  Asegúrese de que sus applications propaguen las cabeceras de trazado como se describe [aquí](/es/docs/tasks/observability/distributed-tracing/overview/).

1.  Siga la guía de instalación de trazado que se encuentra en [Integraciones](/es/docs/ops/integrations/)
    según su backend de trazado preferido para instalar el software apropiado y
    configurar sus proxies de Istio para enviar trazas al deployment de trazado.

## Configuraciones de trazado disponibles

Puede configurar las siguientes opciones de trazado en Istio:

1.  Tasa de muestreo aleatorio para el porcentaje de solicitudes que se seleccionarán para la generación de trazas.

1.  Longitud máxima de la ruta de la solicitud después de la cual la ruta se truncará para la
    presentación de informes. Esto puede ser útil para limitar el almacenamiento de datos de trazas, especialmente si está
    recopilando trazas en los ingress gateways.

1.  Adición de tags personalizados en los spans. Estos tags se pueden agregar en función de valores
    literales estáticos, valores de entorno o campos de las cabeceras de la solicitud. Esto se puede utilizar para
    inyectar información adicional en los spans específicos de su entorno.

Hay dos formas de configurar las opciones de trazado:

1.  Globalmente, a través de las opciones de `MeshConfig`.

1.  Anotaciones por pod, para personalización específica del workload.

{{< warning >}}
Para que la nueva configuración de trazado surta efecto para cualquiera de estas
opciones, debe reiniciar los pods inyectados con proxies de Istio.

Cualquier anotación de pod agregada para la configuración de trazado anula la configuración global.
Para preservar cualquier configuración global, debe copiarla de la
configuración de la mesh global a las anotaciones del pod junto con la personalización específica del
workload. En particular, asegúrese de que la dirección del backend de trazado se
proporcione siempre en las anotaciones para garantizar que las trazas se informen
correctamente para el workload.
{{< /warning >}}

## Instalación

El uso de estas features abre nuevas posibilidades para gestionar las trazas en su entorno.

En este ejemplo, muestrearemos todas las trazas y agregaremos un tag llamado `clusterID`
usando la variable de entorno `ISTIO_META_CLUSTER_ID` inyectada en su pod. Solo los
primeros 256 caracteres del valor serán utilizados.

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 100.0
        max_path_tag_length: 256
        custom_tags:
          clusterID:
            environment:
              name: ISTIO_META_CLUSTER_ID
EOF
$ istioctl install -f ./tracing.yaml
{{< /text >}}

### Usar `MeshConfig` para la configuración de trazas

Todas las opciones de trazado se pueden configurar globalmente a través de `MeshConfig`.
Para simplificar la configuración, se recomienda crear un único fichero YAML
que pueda pasar al comando `istioctl install -f`.

{{< text yaml >}}
cat <<'EOF' > tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 10
        custom_tags:
          my_tag_header:
            header:
              name: host
EOF
{{< /text >}}

### Usar la anotación `proxy.istio.io/config` para la configuración de trazas

Puede agregar la anotación `proxy.istio.io/config` a la especificación de metadatos de su Pod
para anular cualquier configuración de trazado de toda la mesh.
Por ejemplo, para modificar el deployment `curl` que se envía con Istio, agregaría
lo siguiente a `samples/curl/curl.yaml`:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        ...
        proxy.istio.io/config: |
          tracing:
            sampling: 10
            custom_tags:
              my_tag_header:
                header:
                  name: host
    spec:
      ...
{{< /text >}}

## Personalización

### Personalizar el muestreo de trazas

La opción de tasa de muestreo se puede utilizar para controlar qué porcentaje de solicitudes se
informan a su sistema de trazado. Esto debe configurarse en función de su
tráfico en la mesh y la cantidad de datos de trazado que desea recopilar.
La tasa predeterminada es del 1%.

{{< warning >}}
Anteriormente, el método recomendado era cambiar la configuración `values.pilot.traceSampling`
durante la configuración de la mesh o cambiar la variable de entorno `PILOT_TRACE_SAMPLE`
en el deployment de istiod.
Si bien este método para alterar el muestreo sigue funcionando, se recomienda
encarecidamente el siguiente método.

En caso de que se especifiquen ambos, el valor especificado en `MeshConfig` anulará cualquier otra configuración.
{{< /warning >}}

Para modificar el muestreo aleatorio predeterminado al 50%, agregue la siguiente opción a su
fichero `tracing.yaml`.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 50
{{< /text >}}

La tasa de muestreo debe estar en el rango de 0.0 a 100.0 con una precisión de 0.01.
Por ejemplo, para trazar 5 solicitudes de cada 10000, use 0.05 como valor aquí.

### Personalizar los tags de trazado

Se pueden agregar tags personalizados a los spans en función de literales, variables de entorno y
cabeceras de solicitud del cliente para proporcionar información adicional en los spans
específicos de su entorno.

{{< warning >}}
No hay límite en la cantidad de tags personalizados que puede agregar, pero los nombres de los tags deben ser únicos.
{{< /warning >}}

Puede personalizar los tags usando cualquiera de las tres opciones admitidas a continuación.

1.  Literal representa un valor estático que se agrega a cada span.

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_literal:
                literal:
                  value: <VALUE>
    {{< /text >}}

1.  Las variables de entorno se pueden usar cuando el valor del tag personalizado se
    completa a partir de una variable de entorno del proxy del workload.

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_env:
                environment:
                  name: <ENV_VARIABLE_NAME>
                  defaultValue: <VALUE>      # optional
    {{< /text >}}

    {{< warning >}}
    Para agregar tags personalizados basados en variables de entorno, debe
    modificar el ConfigMap `istio-sidecar-injector` en su namespace raíz del sistema Istio.
    {{< /warning >}}

1.  La opción de cabecera de solicitud del cliente se puede utilizar para completar el valor del tag a partir de una
    cabecera de solicitud del cliente entrante.

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_header:
                header:
                  name: <CLIENT-HEADER>
                  defaultValue: <VALUE>      # optional
    {{< /text >}}

### Personalizar la longitud del tag de trazado

De forma predeterminada, la longitud máxima de la ruta de la solicitud incluida como parte del tag del span `HttpUrl` es 256.
Para modificar esta longitud máxima, agregue lo siguiente a su fichero `tracing.yaml`.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        max_path_tag_length: <VALUE>
{{< /text >}}

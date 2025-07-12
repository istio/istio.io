---
title: Configurar el muestreo de trazas
description: Aprenda los diferentes enfoques sobre cómo configurar el muestreo de trazas en los proxies.
weight: 4
keywords: [sampling,telemetry,tracing,opentelemetry]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio proporciona múltiples formas de configurar el muestreo de trazas. En esta página aprenderá y comprenderá
todas las diferentes formas en que se puede configurar el muestreo.

## Antes de empezar

1.  Asegúrese de que sus applications propaguen las cabeceras de trazado como se describe [aquí](/es/docs/tasks/observability/distributed-tracing/overview/).

## Configuraciones de muestreo de trazas disponibles

1.  Muestreador de Porcentaje: una tasa de muestreo aleatoria para el porcentaje de solicitudes que se seleccionarán para la generación de trazas.

1.  Muestreador de OpenTelemetry Personalizado: una implementación de muestreador personalizada, que debe emparejarse con el `OpenTelemetryTracingProvider`.

### Muestreador de Porcentaje

{{< boilerplate telemetry-tracing-tips >}}

El porcentaje de la tasa de muestreo aleatorio utiliza el valor de porcentaje especificado para elegir qué solicitudes muestrear.

La tasa de muestreo debe estar en el rango de 0.0 a 100.0 con una precisión de 0.01.
Por ejemplo, para trazar 5 solicitudes de cada 10000, use 0.05 como valor aquí.

Hay tres formas de configurar la tasa de muestreo aleatorio:

#### API de Telemetría

El muestreo se puede configurar en varios ámbitos: en toda la malla, en el namespace o en el workload, lo que ofrece una gran flexibilidad.
Para obtener más información, consulte la documentación de la [API de Telemetría](/es/docs/tasks/observability/telemetry/).

Instale Istio sin establecer `sampling` dentro de `defaultConfig`:

{{< text syntax=bash snip_id=install_without_sampling >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

Habilite el proveedor de trazado a través de la API de Telemetría y establezca el `randomSamplingPercentage`:

{{< text syntax=bash snip_id=enable_telemetry_with_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
   name: otel-demo
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 10
EOF
{{< /text >}}

#### Usando `MeshConfig`

El muestreo de porcentaje aleatorio se puede configurar globalmente a través de `MeshConfig`.

{{< text syntax=bash snip_id=install_default_sampling >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 10
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

Luego, habilite el proveedor de trazado a través de la API de Telemetría. Tenga en cuenta que no establecemos `randomSamplingPercentage` aquí.

{{< text syntax=bash snip_id=enable_telemetry_no_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: otel-tracing
EOF
{{< /text >}}

#### Usando la anotación `proxy.istio.io/config`

Puede agregar la anotación `proxy.istio.io/config` a la especificación de metadatos de su Pod
para anular cualquier configuración de muestreo de toda la malla.

Por ejemplo, para anular el muestreo de toda la malla anterior, agregaría lo siguiente a su manifiesto de pod:

{{< text syntax=yaml snip_id=none >}}
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
            sampling: 20
    spec:
      ...
{{< /text >}}

### Muestreador de OpenTelemetry Personalizado

La especificación de OpenTelemetry define la [API del Muestreador](https://opentelemetry.io/docs/specs/otel/trace/sdk/#sampler).
La API del Muestreador permite construir un muestreador personalizado que puede tomar decisiones de muestreo más inteligentes y eficientes,
como el [muestreo de probabilidad](https://opentelemetry.io/docs/specs/otel/trace/tracestate-probability-sampling-experimental/).

Dichos muestreadores se pueden emparejar con el [`OpenTelemetryTracingProvider`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider).

{{< quote >}}
La implementación del muestreador reside en el proxy y se puede encontrar en
[Muestreadores de OpenTelemetry de Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/opentelemetry/samplers#opentelemetry-samplers).
{{< /quote >}}

Configuraciones actuales de muestreadores personalizados en Istio:

- [Muestreador de Dynatrace](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider-DynatraceSampler)

Los muestreadores personalizados se configuran a través de `MeshConfig`. Aquí hay un ejemplo de cómo configurar el muestreador de Dynatrace:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 443
        service: abc.live.dynatrace.com/api/v2/otlp
        http:
          path: "/api/v2/otlp/v1/traces"
          timeout: 10s
          headers:
            - name: "Authorization"
              value: "Api-Token dt0c01."
        dynatrace_sampler:
          tenant: "abc"
          cluster_id: 123
{{< /text >}}

### Orden de precedencia

Con múltiples formas de configurar el muestreo, es importante comprender
el orden de precedencia de cada método.

Cuando se utiliza el muestreador de porcentaje aleatorio, el orden de precedencia es:

<table><tr><td>API de Telemetría > Anotación de Pod > <code>MeshConfig</code> </td></tr></table>

Esto significa que, si se define un valor en todos los anteriores, el valor en la API de Telemetría es el que se selecciona.

Cuando se configura un muestreador de OpenTelemetry personalizado, el orden de precedencia es:

<table><tr><td>Muestreador de OTel Personalizado > (API de Telemetría | Anotación de Pod | <code>MeshConfig</code>)</td></tr></table>

Esto significa que, si se configura un muestreador de OpenTelemetry personalizado, anula todos los demás métodos.
Además, el valor del porcentaje aleatorio se establece en `100` y no se puede cambiar. Esto es importante,
porque el muestreador personalizado necesita recibir el 100% de los spans para poder realizar correctamente su decisión.

## Desplegar el OpenTelemetry Collector

{{< boilerplate start-otel-collector-service >}}

## Desplegar la Application Bookinfo

Despliegue la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application).

## Generar trazas usando la muestra de Bookinfo

1.  Cuando la application Bookinfo esté en funcionamiento, acceda a `http://$GATEWAY_URL/productpage`
    una o más veces para generar información de traza.

    {{< boilerplate trace-generation >}}

## Limpieza

1.  Elimine el recurso Telemetry:

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1.  Elimine cualquier proceso `istioctl` que aún pueda estar ejecutándose usando control-C o:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}

1.  Desinstale el OpenTelemetry Collector:

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}

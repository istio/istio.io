---
title: Configurar registros de acceso con la API de Telemetría
description: Esta tarea muestra cómo configurar los proxies de Envoy para enviar registros de acceso con la API de Telemetría.
weight: 10
keywords: [telemetry,logs]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

La API de Telemetría ha estado en Istio como una API de primera clase desde hace algún tiempo.
Anteriormente, los usuarios tenían que configurar la telemetría en la sección `MeshConfig` de la configuración de Istio.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## Instalación

En este ejemplo, enviaremos registros a [Grafana Loki](https://grafana.com/oss/loki/), así que asegúrese de que esté instalado:

{{< text syntax=bash snip_id=install_loki >}}
$ istioctl install -f @samples/open-telemetry/loki/iop.yaml@ --skip-confirmation
$ kubectl apply -f @samples/addons/loki.yaml@ -n istio-system
$ kubectl apply -f @samples/open-telemetry/loki/otel.yaml@ -n istio-system
{{< /text >}}

## Empezar con la API de Telemetría

1. Habilitar el registro de acceso

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n istio-system -f -
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: mesh-logging-default
    spec:
      accessLogging:
      - providers:
        - name: otel
    EOF
    {{< /text >}}

    El ejemplo anterior utiliza el proveedor de registro de acceso `envoy` incorporado, y no configuramos nada más que la configuración predeterminada.

1. Deshabilitar el registro de acceso para un workload específico

    Puede deshabilitar el registro de acceso para el service `curl` con la siguiente configuración:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: disable-curl-logging
      namespace: default
    spec:
      selector:
        matchLabels:
          app: curl
      accessLogging:
      - providers:
        - name: otel
        disabled: true
    EOF
    {{< /text >}}

1. Filtrar el registro de acceso con el modo de workload

    Puede deshabilitar el registro de acceso de entrada para el service `httpbin` con la siguiente configuración:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: disable-httpbin-logging
    spec:
      selector:
        matchLabels:
          app: httpbin
      accessLogging:
      - providers:
        - name: otel
        match:
          mode: SERVER
        disabled: true
    EOF
    {{< /text >}}

1. Filtrar el registro de acceso con expresión CEL

    La siguiente configuración muestra el registro de acceso solo cuando el código de respuesta es mayor o igual a 500:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: filter-curl-logging
    spec:
      selector:
        matchLabels:
          app: curl
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: response.code >= 500
    EOF
    {{< /text >}}

    {{< tip >}}
    No hay atributo `response.code` cuando las conexiones fallan. En ese caso, debe usar la expresión CEL `!has(response.code) || response.code >= 500`.
    {{< /tip >}}

1. Establecer el registro de acceso de filtro predeterminado con expresión CEL

    La siguiente configuración muestra los registros de acceso solo cuando el código de respuesta es mayor o igual a 400 o la solicitud fue a BlackHoleCluster o PassthroughCluster:
    Nota: `xds.cluster_name` solo está disponible con Istio versión 1.16.2 y superior

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: default-exception-logging
      namespace: istio-system
    spec:
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: "response.code >= 400 || xds.cluster_name == 'BlackHoleCluster' ||  xds.cluster_name == 'PassthroughCluster' "

    EOF
    {{< /text >}}

1. Filtrar registros de acceso de verificación de salud con expresión CEL

    La siguiente configuración muestra los registros de acceso solo cuando los registros no son generados por el Servicio de Verificación de Salud de Amazon Route 53.
    Nota: `request.useragent` es específico del tráfico HTTP, por lo tanto, para evitar romper el tráfico TCP, necesitamos verificar la existencia del campo.
    Para obtener más información, consulte [Comprobación de tipos de CEL](https://kubernetes.io/docs/reference/using-api/cel/#type-checking)

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: filter-health-check-logging
    spec:
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: "!has(request.useragent) || !(request.useragent.startsWith("Amazon-Route53-Health-Check-Service"))"
    EOF
    {{< /text >}}

    Para obtener más información, consulte [Usar expresiones para valores](/es/docs/tasks/observability/metrics/customize-metrics/#use-expressions-for-values)

## Trabajar con el proveedor de OpenTelemetry

Istio admite el envío de registros de acceso con el protocolo [OpenTelemetry](https://opentelemetry.io/), como se explica [aquí](/es/docs/tasks/observability/logs/otel-provider).

## Limpieza

1.  Eliminar toda la API de Telemetría:

    {{< text bash >}}
    $ kubectl delete telemetry --all -A
    {{< /text >}}

1.  Eliminar `loki`:

    {{< text bash >}}
    $ kubectl delete -f @samples/addons/loki.yaml@ -n istio-system
    $ kubectl delete -f @samples/open-telemetry/loki/otel.yaml@ -n istio-system
    {{< /text >}}

1.  Desinstalar Istio del cluster:

    {{< text bash >}}
    $ istioctl uninstall --purge --skip-confirmation
    {{< /text >}}

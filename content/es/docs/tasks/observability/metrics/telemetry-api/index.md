---
title: Personalización de Métricas de Istio con la API de Telemetría
description: Esta tarea muestra cómo personalizar las métricas de Istio con la API de Telemetría.
weight: 10
keywords: [telemetry,metrics,customize]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

La API de Telemetría ha estado en Istio como una API de primera clase desde hace algún tiempo.
Anteriormente, los usuarios tenían que configurar las métricas en la sección `telemetry` de la configuración de Istio.

Esta tarea muestra cómo personalizar las métricas que genera Istio con la API de Telemetría.

## Antes de empezar

[Instale Istio](/es/docs/setup/) en su cluster y despliegue una application.

La API de Telemetría no puede funcionar junto con `EnvoyFilter`. Para más detalles, consulte este [problema](https://github.com/istio/istio/issues/39772).

* A partir de la versión `1.18` de Istio, el `EnvoyFilter` de Prometheus no se
  instalará por defecto, y en su lugar se utiliza `meshConfig.defaultProviders` para
  habilitarlo. La API de Telemetría debe utilizarse para personalizar aún más la
  pipeline de telemetría.

* Para versiones de Istio anteriores a la `1.18`, debe instalar con la siguiente configuración de `IstioOperator`:

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      values:
        telemetry:
          enabled: true
          v2:
            enabled: false
    {{< /text >}}

## Anular métricas

La sección `metrics` proporciona valores para las dimensiones de las métricas como expresiones,
y le permite eliminar o anular las dimensiones de métricas existentes.
Puede modificar las definiciones de métricas estándar usando `tags_to_remove` o redefiniendo una dimensión.

1. Eliminar tags `grpc_response_status` de la métrica `REQUEST_COUNT`

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-tags
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - match:
                mode: CLIENT_AND_SERVER
                metric: REQUEST_COUNT
              tagOverrides:
                grpc_response_status:
                  operation: REMOVE
    {{< /text >}}

1. Agregar tags personalizados para la métrica `REQUEST_COUNT`

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: custom-tags
      namespace: istio-system
    spec:
      metrics:
        - overrides:
            - match:
                metric: REQUEST_COUNT
                mode: CLIENT
              tagOverrides:
                destination_x:
                  value: filter_state.upstream_peer.app
            - match:
                metric: REQUEST_COUNT
                mode: SERVER
              tagOverrides:
                source_x:
                  value: filter_state.downstream_peer.app
          providers:
            - name: prometheus
    {{< /text >}}

## Deshabilitar métricas

1. Deshabilitar todas las métricas con la siguiente configuración:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-all-metrics
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT_AND_SERVER
                metric: ALL_METRICS
    {{< /text >}}

1. Deshabilitar métricas `REQUEST_COUNT` con la siguiente configuración:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-request-count
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT_AND_SERVER
                metric: REQUEST_COUNT
    {{< /text >}}

1. Deshabilitar métricas `REQUEST_COUNT` para el cliente con la siguiente configuración:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-client
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT
                metric: REQUEST_COUNT
    {{< /text >}}

1. Deshabilitar métricas `REQUEST_COUNT` para el servidor con la siguiente configuración:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-server
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: SERVER
                metric: REQUEST_COUNT
    {{< /text >}}

## Verificar los resultados

Envíe tráfico a la malla. Para la muestra de Bookinfo, visite `http://$GATEWAY_URL/productpage` en su navegador web
o emita el siguiente comando:

{{< text bash >}}
$ curl "http://$GATEWAY_URL/productpage"
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` es el valor establecido en el ejemplo de [Bookinfo](/es/docs/examples/bookinfo/).
{{< /tip >}}

Use el siguiente comando para verificar que Istio genera los datos para sus nuevas
o modificadas dimensiones:

{{< text bash >}}
$ istioctl x es "$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')" -oprom | grep istio_requests_total | grep -v TYPE |grep -v 'reporter="destination"'
{{< /text >}}

{{< text bash >}}
$ istioctl x es "$(kubectl get pod -l app=details -o jsonpath='{.items[0].metadata.name}')" -oprom | grep istio_requests_total
{{< /text >}}

Por ejemplo, en la salida, localice la métrica `istio_requests_total` y
verifique que contiene su nueva dimensión.

{{< tip >}}
Puede que los proxies tarden un poco en empezar a aplicar la configuración. Si no se recibe la métrica,
puede intentar enviar solicitudes de nuevo después de una breve espera, y buscar la métrica de nuevo.
{{< /tip >}}

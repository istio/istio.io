---
title: Clasificación de Métricas Basada en Solicitud o Respuesta
description: Esta tarea muestra cómo mejorar la telemetría agrupando solicitudes y respuestas por su tipo.
weight: 27
keywords: [telemetry,metrics,classify,request-based,openapispec,swagger]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

Es útil visualizar la telemetría basada en el tipo de solicitudes y respuestas
manejadas por los services en su malla. Por ejemplo, un librero rastrea el número de veces
que se solicitan reseñas de libros. Una solicitud de reseña de libro tiene esta estructura:

{{< text plain >}}
GET /reviews/{review_id}
{{< /text >}}

Contar el número de solicitudes de reseñas debe tener en cuenta el elemento ilimitado
`review_id`. `GET /reviews/1` seguido de `GET /reviews/2` debe contarse como dos
solicitudes para obtener reseñas.

Istio le permite crear reglas de clasificación usando el
plugin AttributeGen que agrupa las solicitudes
en un número fijo de operaciones lógicas. Por ejemplo, puede crear una operación llamada
`GetReviews`, que es una forma común de identificar operaciones usando el
[`Open API Spec operationId`](https://swagger.io/docs/specification/paths-and-operations/).
Esta información se inyecta en el procesamiento de la solicitud como atributo `istio_operationId` con
valor igual a `GetReviews`.
Puede usar el atributo como una dimensión en las métricas estándar de Istio. De manera similar,
puede rastrear métricas basadas en otras operaciones como `ListReviews` y
`CreateReviews`.

## Clasificar métricas por solicitud

Puede clasificar las solicitudes según su tipo, por ejemplo `ListReview`,
`GetReview`, `CreateReview`.

1. Cree un fichero, por ejemplo `attribute_gen_service.yaml`, y guárdelo con el
   siguiente contenido. Esto agrega el plugin `istio.attributegen`.
   También crea un atributo, `istio_operationId` y lo rellena
   con valores para las categorías a contar como métricas.

    Esta configuración es específica del service ya que las rutas de solicitud suelen ser
    específicas del service.

    {{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: istio-attributegen-filter
spec:
  selector:
    matchLabels:
      app: reviews
  url: https://storage.googleapis.com/istio-build/proxy/attributegen-359dcd3a19f109c50e97517fe6b1e2676e870c4d.wasm
  imagePullPolicy: Always
  phase: AUTHN
  pluginConfig:
    attributes:
    - output_attribute: "istio_operationId"
      match:
        - value: "ListReviews"
          condition: "request.url_path == '/reviews' && request.method == 'GET'"
        - value: "GetReview"
          condition: "request.url_path.matches('^/reviews/[[:alnum:]]*$') && request.method == 'GET'"
        - value: "CreateReview"
          condition: "request.url_path == '/reviews/' && request.method == 'POST'"
---
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: custom-tags
spec:
  metrics:
    - overrides:
        - match:
            metric: REQUEST_COUNT
            mode: CLIENT_AND_SERVER
          tagOverrides:
            request_operation:
              value: filter_state['wasm.istio_operationId']
      providers:
        - name: prometheus
    {{< /text >}}

1. Aplique sus cambios usando el siguiente comando:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

1. Después de que los cambios surtan efecto, visite Prometheus y busque las nuevas o
   cambiadas dimensiones, por ejemplo `istio_requests_total` en los pods `reviews`.

## Clasificar métricas por respuesta

Puede clasificar las respuestas usando un proceso similar al de las solicitudes. Tenga en cuenta que la dimensión `response_code` ya existe por defecto.
El siguiente ejemplo cambiará cómo se rellena.

1. Cree un fichero, por ejemplo `attribute_gen_service.yaml`, y guárdelo con
   el siguiente contenido. Esto agrega el plugin `istio.attributegen` y
   genera el atributo `istio_responseClass` utilizado por el plugin de estadísticas.

    Este ejemplo clasifica varias respuestas, como agrupar todos los códigos de respuesta
    en el rango `200` como una dimensión `2xx`.

    {{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: istio-attributegen-filter
spec:
  selector:
    matchLabels:
      app: productpage
  url: https://storage.googleapis.com/istio-build/proxy/attributegen-359dcd3a19f109c50e97517fe6b1e2676e870c4d.wasm
  imagePullPolicy: Always
  phase: AUTHN
  pluginConfig:
    attributes:
      - output_attribute: istio_responseClass
        match:
          - value: 2xx
            condition: response.code >= 200 && response.code <= 299
          - value: 3xx
            condition: response.code >= 300 && response.code <= 399
          - value: "404"
            condition: response.code == 404
          - value: "429"
            condition: response.code == 429
          - value: "503"
            condition: response.code == 503
          - value: 5xx
            condition: response.code >= 500 && response.code <= 599
          - value: 4xx
            condition: response.code >= 400 && response.code <= 499
---
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: custom-tags
spec:
  metrics:
    - overrides:
        - match:
            metric: REQUEST_COUNT
            mode: CLIENT_AND_SERVER
          tagOverrides:
            response_code:
              value: filter_state['wasm.istio_responseClass']
      providers:
        - name: prometheus
    {{< /text >}}

1. Aplique sus cambios usando el siguiente comando:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f attribute_gen_service.yaml
    {{< /text >}}

## Verificar los resultados

1. Genere métricas enviando tráfico a su application.

1. Visite Prometheus y busque las nuevas o cambiadas dimensiones, por ejemplo
   `2xx`. Alternativamente, use el siguiente comando para verificar que Istio genera los datos para su nueva dimensión:

    {{< text bash >}}
    $ kubectl exec pod-name -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_
    {{< /text >}}

    En la salida, localice la métrica (por ejemplo, `istio_requests_total`) y verifique la presencia de la nueva o cambiada dimensión.

## Solución de problemas

Si la clasificación no ocurre como se esperaba, verifique las siguientes causas y resoluciones potenciales.

Revise los registros del proxy de Envoy para el pod que tiene el service en el que aplicó el cambio de configuración. Verifique que no haya errores reportados por el service en los registros del proxy de Envoy en el pod, (`pod-name`), donde configuró la clasificación usando el siguiente comando:

{{< text bash >}}
$ kubectl logs pod-name -c istio-proxy | grep -e "Config Error" -e "envoy wasm"
{{< /text >}}

Además, asegúrese de que no haya fallos del proxy de Envoy buscando signos de reinicios en la salida del siguiente comando:

{{< text bash >}}
$ kubectl get pods pod-name
{{< /text >}}

## Limpieza

Elimine el fichero de configuración yaml.

{{< text bash >}}
$ kubectl -n istio-system delete -f attribute_gen_service.yaml
{{< /text >}}

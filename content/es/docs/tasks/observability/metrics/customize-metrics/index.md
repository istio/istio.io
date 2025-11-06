---
title: Personalización de Métricas de Istio
description: Esta tarea muestra cómo personalizar las métricas de Istio.
weight: 25
keywords: [telemetry,metrics,customize]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Esta tarea muestra cómo personalizar las métricas que genera Istio.

Istio genera telemetría que varios dashboards consumen para ayudarle a visualizar
su malla. Por ejemplo, los dashboards que soportan Istio incluyen:

* [Grafana](/es/docs/tasks/observability/metrics/using-istio-dashboard/)
* [Kiali](/es/docs/tasks/observability/kiali/)
* [Prometheus](/es/docs/tasks/observability/metrics/querying-metrics/)

Por defecto, Istio define y genera un conjunto de métricas estándar (por ejemplo,
`requests_total`), pero también puede personalizarlas y crear nuevas métricas
utilizando la [API de Telemetría](/es/docs/tasks/observability/telemetry/).

## Antes de empezar

[Instale Istio](/es/docs/setup/) en su cluster y despliegue una application.
Alternativamente, puede configurar estadísticas personalizadas como parte de la
instalación de Istio.

La application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/) se utiliza como
application de ejemplo a lo largo de esta tarea. Para obtener instrucciones de instalación, consulte [desplegar la application Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application).

## Habilitar métricas personalizadas

Para personalizar las métricas de telemetría, por ejemplo, para agregar las dimensiones `request_host`
y `destination_port` a la métrica `requests_total` emitida tanto por los
gateways como por los sidecars en la dirección de entrada y salida, use lo siguiente:

{{< text bash >}}
$ cat <<EOF > ./custom_metrics.yaml
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: namespace-metrics
spec:
  metrics:
  - providers:
    - name: prometheus
    overrides:
    - match:
        metric: REQUEST_COUNT
      tagOverrides:
        destination_port:
          value: "string(destination.port)"
        request_host:
          value: "request.host"
EOF
$ kubectl apply -f custom_metrics.yaml
{{< /text >}}

## Verificar los resultados

Envíe tráfico a la mesh. Para la muestra de Bookinfo, visite `http://$GATEWAY_URL/productpage` en su navegador web
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
$ kubectl exec "$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_requests_total
{{< /text >}}

Por ejemplo, en la salida, localice la métrica `istio_requests_total` y
verifique que contiene su nueva dimensión.

{{< tip >}}
Puede que los proxies tarden un poco en empezar a aplicar la configuración. Si no se recibe la métrica,
puede intentar enviar solicitudes de nuevo después de una breve espera, y buscar la métrica de nuevo.
{{< /tip >}}

## Usar expresiones para valores

Los valores en la configuración de métricas son expresiones comunes, lo que significa que
debe entrecomillar las cadenas en JSON, por ejemplo, "'string value'". A diferencia del lenguaje de expresiones de Mixer,
no hay soporte para el operador pipe (`|`), pero puede emularlo con el operador `has` o `in`, por ejemplo:

{{< text plain >}}
has(request.host) ? request.host : "unknown"
{{< /text >}}

Para obtener más información, consulte [Common Expression Language](https://opensource.google/projects/cel).

Istio expone todos los [atributos estándar de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/attributes).
Los metadatos de los peers están disponibles como atributos `upstream_peer` para salida y `downstream_peer` para entrada con los siguientes campos:

| Campo       | Tipo     | Valor                                                      |
|-------------|----------|------------------------------------------------------------|
| `app`       | `string` | Nombre de la application.                                  |
| `version`   | `string` | Versión de la application.                                 |
| `service`   | `string` | Instancia del service.                                     |
| `revision`  | `string` | Versión del service.                                       |
| `name`      | `string` | Nombre del pod.                                            |
| `namespace` | `string` | Namespace en el que se ejecuta el pod.                     |
| `type`      | `string` | Tipo de workload.                                          |
| `workload`  | `string` | Nombre del workload.                                       |
| `cluster`   | `string` | Identificador del cluster al que pertenece este workload. |

Por ejemplo, la expresión para la etiqueta `app` del peer que se utilizará en una configuración de salida es
`filter_state.downstream_peer.app` o `filter_state.upstream_peer.app`.

## Limpieza

Para eliminar la application de ejemplo `Bookinfo` y su configuración, consulte
[limpieza de `Bookinfo`](/es/docs/examples/bookinfo/#cleanup).

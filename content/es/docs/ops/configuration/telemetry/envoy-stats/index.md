---
title: Estadísticas de Envoy
description: Control detallado de las estadísticas de Envoy.
weight: 10
aliases:
  - /help/ops/telemetry/envoy-stats
  - /docs/ops/telemetry/envoy-stats
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

El proxy Envoy mantiene estadísticas detalladas sobre el tráfico de red.

Las estadísticas de Envoy solo cubren el tráfico de una instancia concreta de Envoy. Consulta
[Observabilidad](/es/docs/tasks/observability/) para la telemetría persistente de Istio por servicio. Las
estadísticas que registran los proxies Envoy pueden aportar más información sobre instancias específicas de pods.

Para ver las estadísticas de un pod:

{{< text syntax=bash snip_id=get_stats >}}
$ kubectl exec "$POD" -c istio-proxy -- pilot-agent request GET stats
{{< /text >}}

Envoy genera estadísticas sobre su comportamiento y las agrupa según la función del proxy. Algunos ejemplos:

- [Conexión upstream](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
- [Listener](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/stats)
- [HTTP Connection Manager](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/stats)
- [TCP proxy](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/tcp_proxy_filter#statistics)
- [Router](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter.html?highlight=vhost#statistics)

De forma predeterminada, Istio configura Envoy para que registre un conjunto mínimo de estadísticas, con el fin de reducir el consumo global de CPU y memoria de los proxies instalados. Las claves de
recopilación predeterminadas son:

- `cluster_manager`
- `listener_manager`
- `server`
- `cluster.xds-grpc`

Para ver la configuración de Envoy para la recopilación de datos estadísticos, usa
[`istioctl proxy-config bootstrap`](/es/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap) y sigue la
[inmersión profunda en la configuración de Envoy](/es/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration).
Envoy solo recopila datos estadísticos de los elementos que coinciden con la `inclusion_list` dentro
del elemento JSON `stats_matcher`.

{{< tip >}}
Nota: Los nombres de las estadísticas de Envoy pueden variar según la composición de la configuración de Envoy. Por ello, los nombres expuestos de las estadísticas de los Envoy gestionados por Istio dependen del comportamiento de configuración de Istio.
Si creas o mantienes paneles o alertas basados en estadísticas de Envoy, se **recomienda encarecidamente** que examines las
estadísticas en un entorno canary **antes de actualizar Istio**.
Consulta [Nomenclatura de Istio para los recursos de Envoy](#istio-naming-of-envoy-resources) para ver cómo se construyen estos nombres.
{{< /tip >}}

Para configurar el proxy de Istio de modo que registre estadísticas adicionales, puedes agregar [`ProxyConfig.ProxyStatsMatcher`](/es/docs/reference/config/istio.mesh.v1alpha1/#ProxyStatsMatcher) a la mesh config. Por ejemplo, para habilitar globalmente las estadísticas de circuit breakers, reintentos de solicitudes, conexiones upstream y timeouts de solicitudes, puedes especificar el stats matcher de la siguiente manera:

{{< tip >}}
El proxy debe reiniciarse para tomar la configuración del stats matcher.
{{< /tip >}}

{{< text syntax=yaml snip_id=proxyStatsMatcher >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyStatsMatcher:
        inclusionRegexps:
          - ".*outlier_detection.*"
          - ".*upstream_rq_retry.*"
          - ".*upstream_cx_.*"
        inclusionSuffixes:
          - "upstream_rq_timeout"
{{< /text >}}

También puedes sobrescribir la configuración global de coincidencia de estadísticas por proxy mediante la anotación `proxy.istio.io/config`. Por ejemplo, para configurar la misma inclusión de generación de estadísticas que arriba, puedes agregar la anotación a un proxy de gateway o a un workload de la siguiente manera:

{{< text syntax=yaml snip_id=proxyIstioConfig >}}
metadata:
  annotations:
    proxy.istio.io/config: |-
      proxyStatsMatcher:
        inclusionRegexps:
        - ".*outlier_detection.*"
        - ".*upstream_rq_retry.*"
        - ".*upstream_cx_.*"
        inclusionSuffixes:
        - "upstream_rq_timeout"
{{< /text >}}

{{< tip >}}
Nota: Si usas `sidecar.istio.io/statsInclusionPrefixes`, `sidecar.istio.io/statsInclusionRegexps` y `sidecar.istio.io/statsInclusionSuffixes`, considera cambiar a la configuración basada en `ProxyConfig`, ya que ofrece un valor predeterminado global y una forma uniforme de sobrescribirlo en el gateway y en el sidecar proxy.
{{< /tip >}}

## Nomenclatura de Istio para los recursos de Envoy {#istio-naming-of-envoy-resources}

Envoy delimita el alcance de la mayoría de las estadísticas según el clúster, el connection manager o la dirección del listener a los que pertenecen. Istio genera los nombres de los clústeres y de los connection managers al traducir la configuración de la mesh a configuración de Envoy, por lo que también aparecen en los nombres de las estadísticas, en las etiquetas de Prometheus y en los registros de acceso.

{{< warning >}}
Los nombres siguientes describen el comportamiento actual de Istio. No son una API estable y pueden cambiar entre versiones. Examina las estadísticas en un entorno canary antes de actualizar. Para que las estadísticas de los clústeres no dependan de estos nombres, [personaliza los nombres de las estadísticas de clúster](#customize-cluster-stat-names).
{{< /warning >}}

Estos nombres se aplican a los sidecar proxies y a los gateways. Los waypoint proxies en modo ambient usan nombres de clúster diferentes, y ztunnel no utiliza Envoy.

| Recurso | Formato del nombre | Ejemplo |
|----------|-------------|---------|
| Clúster de salida (outbound) | `outbound\|<port>\|<subset>\|<service FQDN>` | `outbound\|9080\|v1\|reviews.default.svc.cluster.local` |
| Clúster de entrada (inbound) | `inbound\|<target port>\|\|` | `inbound\|9080\|\|` |
| Nombre de servidor TLS de salida (SNI) | `outbound_.<port>_.<subset>_.<service FQDN>` | `outbound_.9080_._.reviews.default.svc.cluster.local` |
| Clústeres comodín (catch-all) | `PassthroughCluster`, `BlackHoleCluster`, `InboundPassthroughCluster` | `PassthroughCluster` |
| Clústeres de bootstrap del proxy | `xds-grpc`, `sds-grpc`, `prometheus_stats`, `agent` | `xds-grpc` |
| HTTP connection manager de salida | `outbound_<bind address>_<port>` | `outbound_0.0.0.0_9080` |
| HTTP connection manager de entrada | `inbound_<bind address>_<target port>` | `inbound_0.0.0.0_9080` |
| TCP proxy | el nombre de estadística del clúster de destino, o `<name>.<namespace>` del `VirtualService` para rutas ponderadas | `outbound\|3306\|\|mysql.default.svc.cluster.local` |

El segmento subset del nombre de un clúster de salida está vacío cuando no se aplica ningún subset de [`DestinationRule`](/es/docs/reference/config/networking/destination-rule/), por ejemplo `outbound|9080||reviews.default.svc.cluster.local`. Envoy crea las estadísticas de tráfico de un clúster, como `upstream_rq_total`, cuando el proxy le envía tráfico por primera vez, por lo que no existen para los clústeres que aún no han recibido tráfico. Para listar los clústeres y listeners de un proxy, consulta [depuración de Envoy e Istiod](/es/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration).

Istio termina la mayoría de los nombres de clúster y de HTTP connection manager usados en las estadísticas con el delimitador `;`, por ejemplo:

{{< text syntax=plain snip_id=none >}}
cluster.outbound|9080||reviews.default.svc.cluster.local;.upstream_rq_total
http.outbound_0.0.0.0_9080;.downstream_rq_total
{{< /text >}}

La configuración de bootstrap del proxy extrae estos nombres en tags, que se convierten en etiquetas en la salida de Prometheus de Envoy. Por ejemplo, `envoy_cluster_upstream_rq_total` tiene una etiqueta `cluster_name` con el valor `outbound|9080||reviews.default.svc.cluster.local`. Los tags más utilizados son:

- `cluster_name`: el nombre del clúster.
- `http_conn_manager_prefix`: el nombre del HTTP connection manager.
- `tcp_prefix`: el nombre del TCP proxy.
- `response_code` y `response_code_class`: el código de respuesta HTTP, como `200` o `2xx`.
- `listener_address`: la dirección del listener, como `0.0.0.0_15006`.

Para ver la lista completa de tags y las expresiones que los extraen, consulta el elemento `stats_config` en la salida de [`istioctl proxy-config bootstrap`](/es/docs/reference/commands/istioctl/#istioctl-proxy-config-bootstrap).

## Personalizar los nombres de las estadísticas de clúster {#customize-cluster-stat-names}

Las opciones de mesh config [`inboundClusterStatName`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-inbound_cluster_stat_name) y [`outboundClusterStatName`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-outbound_cluster_stat_name) reemplazan los nombres de clúster en las estadísticas por un patrón que tú controlas. Los nombres de los clústeres en sí no cambian, por lo que el enrutamiento y la salida de `istioctl proxy-config` no se ven afectados. El patrón puede usar las siguientes variables:

| Variable | Valor |
|----------|-------|
| `%SERVICE%` | `<name>.<namespace>` para los servicios de Kubernetes; el nombre de host completo en otro caso |
| `%SERVICE_NAME%` | `<name>` para los servicios de Kubernetes; el nombre de host completo en otro caso |
| `%SERVICE_FQDN%` | El nombre de host completo del servicio, como `reviews.default.svc.cluster.local` |
| `%SERVICE_PORT%` | El puerto del servicio |
| `%SERVICE_PORT_NAME%` | El nombre del puerto del servicio |
| `%TARGET_PORT%` | El puerto de destino del workload. Solo tiene sentido en los nombres de clúster de `inboundClusterStatName` |
| `%SUBSET_NAME%` | El nombre del subset de `DestinationRule`. Solo para `outboundClusterStatName` |

Istio agrega el delimitador `;` al resultado, por lo que el tag `cluster_name` sigue funcionando. Los mismos patrones también nombran las estadísticas de los TCP proxies, sin el delimitador. No cambian los nombres de clúster en los registros de acceso.

Si un patrón omite `%SUBSET_NAME%`, los clústeres de todos los subsets de un servicio comparten las mismas estadísticas. Por ejemplo, para nombrar las estadísticas de los clústeres de salida según el servicio y el puerto:

{{< text syntax=yaml snip_id=outboundClusterStatName >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    outboundClusterStatName: "%SERVICE%_%SERVICE_PORT%"
{{< /text >}}

Con esta configuración, las estadísticas de las solicitudes al servicio `httpbin` en el puerto `8000` del namespace `default` comienzan con `cluster.httpbin.default_8000;` en lugar de `cluster.outbound|8000||httpbin.default.svc.cluster.local;`.

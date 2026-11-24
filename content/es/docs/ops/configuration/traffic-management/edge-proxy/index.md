---
title: Configuración del proxy de borde
description: Configura en los ingress gateways los valores por defecto que Envoy recomienda como mejores prácticas para proxies de borde.
weight: 65
keywords: [traffic-management,ingress,gateway,edge,security,hardening]
owner: istio/wg-networking-maintainers
test: n/a
---

Cuando un gateway de Istio se despliega como proxy de borde (edge proxy), expuesto directamente a tráfico
de clientes que no son de confianza, Envoy [recomienda ajustes específicos](https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/edge)
para los límites de buffer, los timeouts, la optimización de HTTP/2, el saneamiento de encabezados y los límites de conexiones.

La API `ProxyConfig.ConnectionSettings` de Istio te permite aplicar estas recomendaciones en
un solo paso con el perfil `EDGE`, o configurar ajustes individuales para cualquier proxy.

Para ver la referencia completa de los campos, consulta [`ProxyConfig.ConnectionSettings`](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig-ConnectionSettings).

## Aplicar el perfil `EDGE`

Establece `profile: EDGE` dentro de `connectionSettings` para aplicar a un gateway los valores por defecto
de proxy de borde que recomienda Envoy. El perfil se puede establecer de forma global mediante `MeshConfig` o por gateway
con una anotación de pod.

### Configuración global

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
{{< /text >}}

### Anotación por gateway

{{< text syntax=yaml snip_id=none >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"connectionSettings": {"profile": "EDGE"}}'
{{< /text >}}

### Valores por defecto del perfil `EDGE`

El perfil `EDGE` aplica los siguientes valores por defecto. Cualquier campo que establezcas explícitamente
siempre tiene prioridad sobre los valores por defecto del perfil.

| Ajuste | Valor por defecto |
|---------|---------------|
| `listenerPerConnectionBufferLimitBytes` | `32768 (32 KiB)` |
| `clusterPerConnectionBufferLimitBytes` | `32768 (32 KiB)` |
| `httpIdleTimeout` | `3600s` (1 hora) |
| `httpRequestTimeout` | `300s` (5 minutos) |
| `httpStreamIdleTimeout` | `300s` (5 minutos) |
| `httpMaxConcurrentStreams` | 100 |
| `http2InitialStreamWindowSize` | `65536 (64 KiB)` |
| `http2InitialConnectionWindowSize` | 1048576 (1 MiB) |
| `httpRequestHeadersTimeout` | `60s` (1 minuto) |
| `httpHeadersWithUnderscoresAction` | `REJECT_REQUEST` |
| `httpMergeSlashes` | true |
| `httpPathWithEscapedSlashesAction` | `UNESCAPE_AND_REDIRECT` |

{{< tip >}}
Los valores por defecto del perfil `EDGE` solo se aplican a los proxies de gateway (Router), incluso cuando el
ajuste se aplica de forma global mediante `MeshConfig`. Sin embargo, los campos de
`connectionSettings` establecidos explícitamente (sin depender de los valores por defecto del perfil) se aplican a todos
los tipos de proxy, incluidos los sidecars.
{{< /tip >}}

## Sobrescribir los valores por defecto del perfil

Puedes establecer `profile: EDGE` y sobrescribir ajustes específicos. Por ejemplo, para aumentar
el límite máximo de streams concurrentes:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
        httpMaxConcurrentStreams: 200
{{< /text >}}

O mediante una anotación de pod:

{{< text syntax=yaml snip_id=none >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"connectionSettings": {"profile": "EDGE", "httpMaxConcurrentStreams": 200}}'
{{< /text >}}

## Configurar ajustes individuales sin un perfil

Puedes establecer campos individuales de `connectionSettings` sin usar un perfil. Esto es
útil cuando quieres optimizar aspectos concretos de las conexiones sin aplicar todo el conjunto de valores por defecto de proxy de borde.

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        httpIdleTimeout: 600s
        httpMaxConcurrentStreams: 50
{{< /text >}}

Si no se establece ningún perfil, no se aplica ningún valor por defecto adicional. Solo tienen efecto los campos
establecidos explícitamente.

## Límite global de conexiones downstream

El campo `globalDownstreamConnectionLimit` configura el número máximo de
conexiones downstream que acepta el proxy. Para ello, se usa el overload manager de Envoy
en la configuración de bootstrap.

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
        globalDownstreamConnectionLimit: 10000
{{< /text >}}

Este campo tiene prioridad sobre el valor `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS`
de los metadatos del proxy; este valor, a su vez, tiene prioridad sobre el flag de runtime obsoleto
`overload.global_downstream_max_connections`.

## Relación con otras APIs

**DestinationRule**: `ConnectionSettings` configura el lado downstream del
proxy (los listeners y el HTTP Connection Manager), mientras que, en DestinationRule,
`connectionPoolSettings` configura el lado del cluster upstream. Ambos se aplican
de forma independiente en saltos distintos y no se sobrescriben entre sí.

**Normalización de rutas**: Los campos `httpMergeSlashes` y `httpPathWithEscapedSlashesAction`
de `ConnectionSettings`, cuando se establecen, tienen prioridad sobre los ajustes equivalentes que `MeshConfig` define en
`pathNormalization`. Para ver recomendaciones sobre cómo elegir las opciones
de normalización de rutas, consulta las [mejores prácticas de seguridad](/es/docs/ops/best-practices/security/#understand-path-normalization-in-authorization-policy).

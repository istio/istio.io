---
title: "Presentamos la API TrafficExtension"
description: Una nueva API unificada para extender los proxies Envoy en Istio con WebAssembly y Lua, compatible con el modo sidecar y el modo ambient.
publishdate: 2026-05-18
attribution: "Liam White"
keywords: [istio, wasm, lua, extensibility, ambient, traffic extension]
target_release: "1.30"
---

La extensibilidad de la mesh siempre ha sido un principio fundamental del diseño de Istio. Al permitir que los usuarios inyecten lógica personalizada directamente en el data plane, Istio habilita una amplia variedad de casos de uso: autenticación personalizada, recopilación de telemetría especializada o transformación de solicitudes y respuestas en tiempo real.

Hasta ahora, la única API de extensibilidad soportada por Istio era `WasmPlugin`, diseñada para extensiones basadas en WebAssembly. Los usuarios que querían usar scripts Lua solo podían hacerlo de forma indirecta mediante `EnvoyFilter`, un mecanismo de bajo nivel que es potente pero fácil de configurar incorrectamente.

Istio 1.30 introduce la API `TrafficExtension` — una API única y unificada para configurar extensiones Wasm y Lua en sidecars, gateways y waypoints basados en Envoy.

## ¿Qué es TrafficExtension?

`TrafficExtension` es una nueva API de Istio que reemplaza a `WasmPlugin` como mecanismo principal de extensibilidad del proxy. Soporta dos tipos de extensión:

- **Scripts Lua** — scripts Lua inline integrados directamente en el recurso, ejecutados dentro de Envoy sin necesidad de distribución de módulos. Ideales para manipulación simple de headers, logging y lógica condicional. Se aplican únicamente al tráfico de capa 7 (HTTP).
- **Plugins WebAssembly** — módulos sandbox Proxy-Wasm cargados dinámicamente desde registros de imágenes OCI. Soportan múltiples lenguajes (Go, Rust, C++, AssemblyScript) y se recomiendan para procesamiento complejo, aplicación de políticas, recopilación de telemetría y mutaciones de payload. Se aplican al tráfico de capa 7 (HTTP) o capa 4 (TCP).

Consulta la [página de conceptos de TrafficExtension](/docs/concepts/extensibility/) para obtener orientación detallada sobre cómo elegir entre Lua y Wasm para tu caso de uso.

## Cómo escribir extensiones

### Lua

Los scripts Lua se escriben inline. El siguiente ejemplo lee el header de solicitud `x-number`, calcula si el valor es par o impar, y agrega el header de respuesta `x-parity`:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
{{< /text >}}

### WebAssembly

Los módulos Wasm se cargan desde registros OCI. El siguiente ejemplo aplica autenticación básica al path `/productpage` usando un plugin Wasm preconstruido:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods: ["GET", "POST"]
          credentials: ["ok:test"]
{{< /text >}}

Las extensiones Wasm preconstruidas están disponibles en el [repositorio del ecosistema de Istio](https://github.com/istio-ecosystem/wasm-extensions). Para crear las tuyas, consulta los [SDKs de Proxy-Wasm](https://github.com/proxy-wasm).

## Apuntado de recursos

`TrafficExtension` soporta dos mecanismos de apuntado adaptados a distintos modos de despliegue.

**`selector`** apunta a los proxies sidecar usando selectores de etiquetas. Un recurso creado en `istio-system` se aplica a todo el clúster; un recurso en cualquier otro namespace se aplica únicamente a los workloads de ese namespace.

**`targetRefs`** apunta directamente a Gateways o Services — necesario para los waypoint proxies en modo ambient, que no se mapean a workloads mediante selectores de etiquetas. La misma extensión `basic-auth` aplicada a un Gateway ambient tiene este aspecto:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods: ["GET", "POST"]
          credentials: ["ok:test"]
{{< /text >}}

## Ordenación de extensiones

Cuando múltiples extensiones apuntan al mismo proxy, `phase` y `priority` controlan el orden de ejecución.

`phase` sitúa la extensión en un punto conocido de la cadena de filtros:

| Phase | Posición |
|-------|----------|
| `AUTHN` | Fase de autenticación |
| `AUTHZ` | Fase de autorización |
| `STATS` | Fase de estadísticas/observabilidad |
| *(sin definir)* | Cerca del router (por defecto) |

Dentro de una phase, `priority` desempata — los valores más altos se ejecutan antes en el path de la solicitud.

## Migrar desde WasmPlugin

`TrafficExtension` reemplaza a `WasmPlugin` como API de extensibilidad recomendada. Los recursos `WasmPlugin` existentes son totalmente compatibles con la nueva API — de hecho, Istio ahora transforma internamente todos los recursos `WasmPlugin` en recursos `TrafficExtension` antes de generar la configuración que distribuye a Envoy.

No hay migración forzada en Istio 1.30. Cuando estés listo para migrar, la [referencia de la API TrafficExtension](/docs/reference/config/proxy_extensions/traffic_extension/) documenta la especificación completa.

## Primeros pasos

- [Conceptos de TrafficExtension](/docs/concepts/extensibility/) — tipos de extensión, apuntado y ordenación explicados
- [Ejecutar módulos WebAssembly](/docs/tasks/extensibility/wasm-modules/) — tarea paso a paso para despliegues con sidecar
- [Ejecutar scripts Lua](/docs/tasks/extensibility/lua-scripts/) — tarea paso a paso para despliegues con sidecar
- [Extender waypoints con WebAssembly](/docs/ambient/usage/extend-waypoint-wasm/) — guía para modo ambient
- [Extender waypoints con Lua](/docs/ambient/usage/extend-waypoint-lua/) — guía para modo ambient

## Comunidad

`TrafficExtension` es alpha, y tu retroalimentación influye directamente en la API antes de que se estabilice. Si encuentras problemas o tienes sugerencias, [abre un issue en GitHub](https://github.com/istio/istio/issues) o únete a la discusión en [Istio Slack](https://slack.istio.io/). Nos encantaría saber cómo estás usando las extensiones de proxy en tus despliegues.

¿Listo para participar? Visita la [página de comunidad de Istio](/get-involved/).

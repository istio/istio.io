---
title: Ejecutar módulos WebAssembly
description: Describe cómo hacer disponibles módulos WebAssembly remotos en la mesh.
weight: 10
aliases:
  - /docs/tasks/extensibility/wasm-module-distribution/
  - /help/ops/extensibility/distribute-remote-wasm-module
  - /docs/ops/extensibility/distribute-remote-wasm-module
  - /ops/configuration/extensibility/wasm-module-distribution
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio proporciona la capacidad de extender la funcionalidad del proxy usando [WebAssembly (Wasm)](/docs/concepts/extensibility/).
Una de las ventajas clave de la extensibilidad Wasm es que las extensiones pueden cargarse dinámicamente en tiempo de ejecución.
Estas extensiones deben distribuirse primero al proxy Envoy.
Istio hace esto posible permitiendo que el agente proxy descargue módulos Wasm dinámicamente.

## Antes de comenzar

Despliega la aplicación de ejemplo [Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Configurar un módulo Wasm

En este ejemplo, agregarás una extensión HTTP Basic auth a tu mesh. Configurarás Istio
para descargar el [módulo Basic auth](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)
desde un registro de imágenes remoto y cargarlo. Se configurará para ejecutarse en llamadas a `/productpage`.

Para configurar un filtro WebAssembly con un módulo Wasm remoto, crea un recurso `TrafficExtension`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
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
          request_methods:
            - "GET"
            - "POST"
          credentials:
            - "ok:test"
            - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

Se inyectará un filtro HTTP en los proxies del ingress gateway como filtro de autenticación.
El agente de Istio interpretará la configuración del `TrafficExtension`, descargará los módulos Wasm remotos
desde el registro de imágenes OCI a un archivo local, e inyectará el filtro HTTP en Envoy referenciando ese archivo.

{{< idea >}}
Si se crea un `TrafficExtension` en un namespace específico distinto de `istio-system`, se configurarán los pods de ese
namespace. Si el recurso se crea en el namespace `istio-system`, todos los namespaces se verán afectados.
{{< /idea >}}

## Verificar el módulo Wasm

[Determina la IP y el puerto del ingress](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports).

1. Prueba `/productpage` sin credenciales:

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    401
    {{< /text >}}

1. Prueba `/productpage` con credenciales:

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    200
    {{< /text >}}

## Orden y alcance

Cuando múltiples recursos `TrafficExtension` apuntan al mismo workload, el orden de ejecución se controla
mediante `phase` y `priority`.

- **`phase`** establece la posición amplia en la cadena de filtros: `AUTHN`, `AUTHZ` o `STATS`.
  Las extensiones sin phase se insertan cerca del final de la cadena, antes del router.
- **`priority`** desempata dentro del mismo phase. Los valores más altos se ejecutan primero.

El campo `match` restringe un `TrafficExtension` a tráfico específico por modo y puerto:

{{< text yaml >}}
spec:
  match:
  - mode: CLIENT
    ports:
    - number: 8080
{{< /text >}}

Los modos válidos son `CLIENT` (saliente), `SERVER` (entrante) y `CLIENT_AND_SERVER` (ambos, el valor por defecto).

## Limpieza

{{< text bash >}}
$ kubectl delete trafficextension -n istio-system basic-auth
{{< /text >}}

## Monitorear la distribución de módulos Wasm

El agente de Istio recopila las siguientes estadísticas:

- `istio_agent_wasm_cache_lookup_count`: número de lookups en la caché de descargas remotas de Wasm.
- `istio_agent_wasm_cache_entries`: número de conversiones de configuración Wasm y sus resultados, incluyendo éxito, sin carga remota, fallo de marshaling, fallo de descarga remota y hint de descarga remota fallida.
- `istio_agent_wasm_config_conversion_duration_bucket`: tiempo total en milisegundos que el agente de Istio dedica a la conversión de configuración para módulos Wasm.
- `istio_agent_wasm_remote_fetch_count`: número de descargas remotas de Wasm y sus resultados, incluyendo éxito, fallo de descarga y discrepancia de checksum.

Si se rechaza una configuración de filtro Wasm, ya sea por fallo de descarga u otras razones, istiod también emitirá `pilot_total_xds_rejects` con la etiqueta de tipo `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`.

## Desarrollar una extensión Wasm

Para obtener más información sobre el desarrollo de módulos Wasm, consulta las guías proporcionadas en el
[repositorio `istio-ecosystem/wasm-extensions`](https://github.com/istio-ecosystem/wasm-extensions),
mantenido por la comunidad de Istio y usado para desarrollar la extensión Wasm de Telemetría de Istio:

- [Escribir, probar, desplegar y mantener una extensión Wasm con C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
- [Construir imágenes OCI compatibles con plugins Wasm de Istio](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md)
- [Escribir pruebas unitarias para extensiones Wasm en C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
- [Escribir pruebas de integración para extensiones Wasm](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)

Para más detalles sobre la API, consulta la [referencia de `TrafficExtension`](/docs/reference/config/proxy_extensions/traffic_extension/).

## Limitaciones

Existen limitaciones conocidas en este mecanismo de distribución de módulos, que se abordarán en releases futuras:

- Solo se soportan filtros HTTP.

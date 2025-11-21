---
title: Distribución de Módulos WebAssembly
description: Describe cómo hacer que los módulos WebAssembly remotos estén disponibles en la mesh.
weight: 10
aliases:
  - /help/ops/extensibility/distribute-remote-wasm-module
  - /docs/ops/extensibility/distribute-remote-wasm-module
  - /ops/configuration/extensibility/wasm-module-distribution
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio proporciona la capacidad de [extender la funcionalidad del proxy usando WebAssembly (Wasm)](/blog/2020/wasm-announce/).
Una de las ventajas clave de la extensibilidad de Wasm es que las extensiones se pueden cargar dinámicamente en runtime.
Estas extensiones deben distribuirse primero al proxy de Envoy.
Istio hace esto posible al permitir que el agente del proxy descargue dinámicamente los módulos Wasm.

## Configurar la Aplicación de Prueba

Antes de comenzar esta tarea, despliegue la aplicación de ejemplo [Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application).

## Configurar Módulos Wasm

En este ejemplo, agregará una extensión de autenticación básica HTTP a su malla. Configurará Istio para obtener el [módulo de autenticación básica](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) de un registry de imágenes remoto y cargarlo. Se configurará para que se ejecute en las llamadas a `/productpage`.

Para configurar un filtro WebAssembly con un módulo Wasm remoto, cree un recurso `WasmPlugin`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
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

Se inyectará un filtro HTTP en los proxies del ingress gateway como un filtro de autenticación.
El agente de Istio interpretará la configuración de `WasmPlugin`, descargará los módulos Wasm remotos del registry de imágenes OCI a un fichero local e inyectará el filtro HTTP en Envoy haciendo referencia a ese fichero.

{{< idea >}}
Si se crea un `WasmPlugin` en un namespace específico además de `istio-system`, se configurarán los pods de ese namespace. Si el recurso se crea en el namespace `istio-system`, todos los namespaces se verán afectados.
{{< /idea >}}

## Verificar el módulo Wasm configurado

1. Probar `/productpage` sin credenciales

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    401
    {{< /text >}}

1. Probar `/productpage` con credenciales

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    200
    {{< /text >}}

Para ver más ejemplos de uso de la API `WasmPlugin`, consulte la [referencia de la API](/es/docs/reference/config/proxy_extensions/wasm-plugin/).

## Limpiar los módulos Wasm

{{< text bash >}}
$ kubectl delete wasmplugins.extensions.istio.io -n istio-system basic-auth
{{< /text >}}

## Monitorear la Distribución de Módulos Wasm

Hay varias estadísticas que rastrean el estado de distribución de los módulos Wasm remotos.

Las siguientes estadísticas son recopiladas por el agente de Istio:

- `istio_agent_wasm_cache_lookup_count`: número de búsquedas en la caché de obtención remota de Wasm.
- `istio_agent_wasm_cache_entries`: número de conversiones de configuración de Wasm y resultados, incluyendo éxito, sin carga remota, fallo de marshalling, fallo de obtención remota y falta de pista de obtención remota.
- `istio_agent_wasm_config_conversion_duration_bucket`: Tiempo total en milisegundos que istio-agent dedica a la conversión de configuración para los módulos Wasm.
- `istio_agent_wasm_remote_fetch_count`: número de obtenciones remotas de Wasm y resultados, incluyendo éxito, fallo de descarga y discrepancia de checksum.

Si se rechaza una configuración de filtro Wasm, ya sea por un fallo en la descarga o por otras razones, istiod también emitirá `pilot_total_xds_rejects` con la etiqueta de tipo `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`.

## Desarrollar una Extensión Wasm

Para obtener más información sobre el desarrollo de módulos Wasm, consulte las guías proporcionadas en el [repositorio `istio-ecosystem/wasm-extensions`](https://github.com/istio-ecosystem/wasm-extensions),
que es mantenido por la comunidad de Istio y se utiliza para desarrollar la extensión Wasm de Telemetría de Istio:

- [Escribir, probar, desplegar y mantener una extensión Wasm con C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
- [Construir imágenes OCI compatibles con el plugin Wasm de Istio](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md)
- [Escribir pruebas unitarias para extensiones Wasm de C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
- [Escribir pruebas de integración para extensiones Wasm](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)

## Limitaciones

Existen limitaciones conocidas con este mecanismo de distribución de módulos, que se abordarán en futuras versiones:

- Solo se admiten filtros HTTP.

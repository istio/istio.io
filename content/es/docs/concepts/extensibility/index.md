---
title: Extensibilidad
description: Describe los mecanismos de extensión de proxy de Istio, incluyendo filtros WebAssembly y Lua.
weight: 50
keywords: [wasm,webassembly,emscripten,extension,plugin,filter,lua,TrafficExtension]
aliases:
  - /docs/concepts/wasm/
  - /latest/docs/concepts/wasm/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Istio proporciona dos mecanismos de extensión principales: extensiones de Envoy, descritas a continuación, y [Proveedores de extensión](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-extension_providers).

## Extender los proxies Envoy

Istio proporciona dos mecanismos para extender los proxies basados en Envoy: WebAssembly (Wasm) y Lua.
Ambos se configuran usando la API [`TrafficExtension`](/docs/reference/config/proxy_extensions/traffic_extension/),
que provee una forma unificada de adjuntar extensiones a workloads con targeting consistente y ordenamiento por phase/priority.

### Elegir el tipo de filtro

| | WebAssembly | Lua |
|---|---|---|
| **Lenguajes** | C++, Rust, Go, AssemblyScript y más | Solo Lua |
| **Distribución** | Descargado desde registros OCI, URLs HTTP o archivos locales | Inline directamente en el recurso |
| **Memoria** | Mayor — cada plugin se ejecuta en su propio sandbox | ~10x menor que WebAssembly |
| **Aislamiento** | Sandbox VM completo — un crash se contiene al plugin | Se ejecuta en proceso; un crash puede matar el hilo de trabajo |
| **Política de fallo** | Configurable — fail-closed por defecto | Solo fail-open — sin opción de configuración |
| **SDLC** | Ecosistema completo: pruebas unitarias, CI, releases versionados | Limitado — el script vive en el recurso mismo |
| **Ideal para** | Lógica compleja, plugins reutilizables, extensiones en producción | Transformaciones simples puntuales, soluciones temporales |

En general, prefiere WebAssembly para extensiones en producción que requieran pruebas, versionado y reutilización.
Prefiere Lua para cambios ligeros y localizados donde la simplicidad del código inline supera la falta de herramientas.

### Plugins WebAssembly

WebAssembly es una tecnología de sandboxing para extensiones más complejas. La API sandbox Proxy-Wasm reemplaza a Mixer como el mecanismo de extensión principal en Istio.

Objetivos del sandbox WebAssembly:

- **Eficiencia** - Una extensión agrega baja latencia, y poco overhead de CPU y memoria.
- **Funcionalidad** - Una extensión puede aplicar políticas, recopilar telemetría y realizar mutaciones de payload.
- **Aislamiento** - Un error de programación o crash en un plugin no afecta a otros plugins.
- **Configuración** - Los plugins se configuran usando una API consistente con otras APIs de Istio. Una extensión puede configurarse dinámicamente.
- **Operador** - Una extensión puede desplegarse con canary y en modo log-only, fail-open o fail-close.
- **Desarrollador de extensiones** - El plugin puede escribirse en varios lenguajes de programación.

Esta [charla en video](https://youtu.be/XdWmm_mtVXI) es una introducción a la arquitectura de la integración de WebAssembly.

#### Arquitectura de alto nivel

Las extensiones de Istio (plugins Proxy-Wasm) tienen varios componentes:

- **Filter Service Provider Interface (SPI)** para construir plugins Proxy-Wasm para filtros.
- **Sandbox** V8 Wasm Runtime embebido en Envoy.
- **Host APIs** para headers, trailers y metadata.
- **Call out APIs** para llamadas gRPC y HTTP.
- **Stats and Logging APIs** para métricas y monitoreo.

{{< image width="80%" link="./extending.svg" caption="Extendiendo Istio/Envoy" >}}

#### Ejemplo

Un ejemplo de plugin C++ Proxy-Wasm para un filtro se puede encontrar
[aquí](https://github.com/istio-ecosystem/wasm-extensions/tree/master/example).
Puedes seguir [esta guía](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md) para implementar una extensión Wasm con C++.

#### Ecosistema

- [Extensiones Wasm del ecosistema Istio](https://github.com/istio-ecosystem/wasm-extensions)
- [Especificación ABI Proxy-Wasm](https://github.com/proxy-wasm/spec)
- [SDK C++ Proxy-Wasm](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [SDK Go Proxy-Wasm](https://github.com/proxy-wasm/proxy-wasm-go-sdk)
- [SDK Rust Proxy-Wasm](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [SDK AssemblyScript Proxy-Wasm](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://webassemblyhub.io/)
- [Extensiones WebAssembly para proxies de red (video)](https://www.youtube.com/watch?v=OIUPf8m7CGA)

### Scripts Lua

Los filtros Lua proporcionan un enfoque de scripting inline y ligero para transformaciones simples de requests y responses.
El código Lua se integra directamente en el recurso `TrafficExtension` y se ejecuta dentro del proxy Envoy; no se requiere
distribución de módulos. Los filtros Lua son más adecuados para manipulación simple de headers, logging o lógica condicional.
Para procesamiento más complejo, se recomiendan los filtros WebAssembly.

El consumo de memoria de Lua es significativamente menor que el de WebAssembly. Los [benchmarks](https://github.com/liamawhite/lua-vs-wasm-envoy)
muestran que Lua consume aproximadamente 20–26 MiB independientemente de la concurrencia, mientras que WebAssembly varía de ~110 MiB
con baja concurrencia a ~290 MiB con alta concurrencia:

| Concurrencia | Lua (MiB) | Wasm (MiB) |
|---|---|---|
| 1 | 19.79 | 117.7 |
| 2 | 23.07 | 132.5 |
| 4 | 22.63 | 152.0 |
| 8 | 23.97 | 190.9 |
| 16 | 25.66 | 291.8 |

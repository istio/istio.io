---
title: Extensibilidad
description: Describe el sistema de plugins WebAssembly de Istio.
weight: 50
keywords: [wasm,webassembly,emscripten,extension,plugin,filter]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

WebAssembly es una tecnología de sandboxing que se puede utilizar para extender el proxy de Istio (Envoy). La API del sandbox de Proxy-Wasm reemplaza a Mixer como el principal mecanismo de extensión en Istio.

Objetivos del sandbox de WebAssembly:

- **Eficiencia**: una extensión agrega baja latencia y sobrecarga de CPU y memoria.
- **Función**: una extensión puede aplicar políticas, recopilar telemetría y realizar mutaciones de carga útil.
- **Aislamiento**: un error de programación o un bloqueo en un complemento no afecta a otros complementos.
- **Configuración**: los complementos se configuran mediante una API que es coherente con otras API de Istio. Una extensión se puede configurar dinámicamente.
- **Operador**: una extensión se puede implementar en canary y como solo registro, a prueba de fallas o a prueba de cierre.
- **Desarrollador de extensiones**: el complemento se puede escribir en varios lenguajes de programación.

Esta [charla en video](https://youtu.be/XdWmm_mtVXI) es una introducción sobre la arquitectura de la integración de WebAssembly.

## Arquitectura de alto nivel

Las extensiones de Istio (plugins de Proxy-Wasm) tienen varios componentes:

- **Interfaz de proveedor de servicios de filtro (SPI)** para crear complementos de Proxy-Wasm para filtros.
- **Sandbox** V8 Wasm Runtime integrado en Envoy.
- **API de host** para encabezados, avances y metadatos.
- **API de llamada** para llamadas gRPC y HTTP.
- **API de estadísticas y registro** para métricas y monitoreo.

{{< image width="80%" link="./extending.svg" caption="Extending Istio/Envoy" >}}

## Ejemplo

Se puede encontrar un ejemplo de complemento de Proxy-Wasm en C++ para un filtro
[aquí](https://github.com/istio-ecosystem/wasm-extensions/tree/master/example).
Puede seguir [esta guía](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md) para implementar una extensión Wasm con C++.

## Ecosistema

- [Extensiones Wasm del ecosistema de Istio](https://github.com/istio-ecosystem/wasm-extensions)
- [Especificación de la ABI de Proxy-Wasm](https://github.com/proxy-wasm/spec)
- [SDK de C++ de Proxy-Wasm](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [SDK de Rust de Proxy-Wasm](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [SDK de AssemblyScript de Proxy-Wasm](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://webassemblyhub.io/)
- [Extensiones de WebAssembly para proxies de red (video)](https://www.youtube.com/watch?v=OIUPf8m7CGA)

---
title: Política de descarga de módulos WebAssembly
description: Describe cómo determina Istio si debe descargar los módulos Wasm o usar las versiones en caché.
weight: 10
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
status: Alpha
---

{{< boilerplate alpha >}}

La [API WasmPlugin](/es/docs/reference/config/proxy_extensions/wasm-plugin) proporciona un método para [distribuir módulos Wasm](/es/docs/tasks/extensibility/wasm-modules) a los proxies.
Como cada proxy descarga los módulos Wasm desde un registro de imágenes remoto o un servidor HTTP, es importante entender cómo decide Istio si descarga los módulos, tanto por usabilidad como por rendimiento.

## Política de descarga de imágenes y excepciones

De forma análoga a `ImagePullPolicy` de Kubernetes, [WasmPlugin](/es/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin) también tiene los conceptos `IfNotPresent` y `Always`, que significan "usar el módulo en caché" y "descargar siempre el módulo, independientemente de la caché", respectivamente.

Los usuarios configuran explícitamente cómo se obtienen los módulos Wasm con el campo `ImagePullPolicy`. Sin embargo, Istio puede anular el comportamiento definido por el usuario en los siguientes casos:

1. Si el usuario establece `sha256` en [WasmPlugin](/es/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin), se usa la política `IfNotPresent`, independientemente de `ImagePullPolicy`.
1. Si el campo `url` apunta a una imagen OCI y esta tiene un sufijo de digest (por ejemplo, `gcr.io/foo/bar@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`), se usa la política `IfNotPresent`.

Cuando no se especifica `ImagePullPolicy` para un recurso, Istio usa por defecto el comportamiento `IfNotPresent`. Sin embargo, si el campo `url` especifica una imagen OCI con el tag `latest`, Istio usará el comportamiento `Always`.

## Ciclo de vida de los módulos en caché

Cada proxy, ya sea un proxy sidecar o un gateway, almacena en caché los módulos Wasm. Por lo tanto, la vida útil del módulo Wasm en caché está limitada por la del pod correspondiente.
Además, existe un mecanismo de expiración para mantener al mínimo el uso de memoria del proxy: si un módulo Wasm en caché no se usa durante cierto tiempo, se elimina.

Puedes configurar esta expiración mediante las variables de entorno `WASM_MODULE_EXPIRY` y `WASM_PURGE_INTERVAL` de [pilot-proxy](/es/docs/reference/commands/pilot-agent/#envvars), que definen, respectivamente, el tiempo de expiración y el intervalo de comprobación de la expiración.

## Qué significa "Always"

En Kubernetes, `ImagePullPolicy: Always` significa que una imagen se descarga directamente desde su origen cada vez que se crea un pod.
Cada vez que se inicia un pod nuevo, Kubernetes vuelve a descargar la imagen.

En un `WasmPlugin`, `ImagePullPolicy: Always` significa que Istio descargará una imagen directamente desde su origen cada vez que se cree o se modifique el recurso de Kubernetes `WasmPlugin` correspondiente.
Ten en cuenta que, con la política `Always`, un cambio no solo en `spec`, sino también en `metadata`, provoca la descarga de un módulo Wasm. Esto puede hacer que una imagen se descargue desde el origen varias veces durante la vida de un pod y durante la vida de un proxy individual.

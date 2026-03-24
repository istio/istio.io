---
title: Anuncio de Istio 1.28.4
linktitle: 1.28.4
subtitle: Versión de Parche
description: Parche de Istio 1.28.4.
publishdate: 2026-02-16
release: 1.28.4
aliases:
    - /news/announcing-1.28.4
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.28.3 e Istio 1.28.4.

{{< relnote >}}

## Actualización de seguridad

- [CVE-2025-61732](https://github.com/advisories/GHSA-8jvr-vh7g-f8gx) (CVSS score 8.6, High): Una discrepancia en el análisis de comentarios entre Go y C/C++ permitía la introducción de código malicioso en el binario cgo resultante.
- [CVE-2025-68121](https://github.com/advisories/GHSA-h355-32pf-p2xm) (CVSS score 4.8, Moderate): Un fallo en la reanudación de sesiones de `crypto/tls` permite que los handshakes reanudados tengan éxito cuando deberían fallar si ClientCAs o RootCAs se modifican entre el handshake inicial y el reanudado. Esto puede ocurrir al usar `Config.Clone` con mutaciones o `Config.GetConfigForClient`. Como resultado, los clientes pueden reanudar sesiones con servidores no previstos, y los servidores pueden reanudar sesiones con clientes no previstos.

## Cambios

- **Añadida** una función de participación opcional cuando se usa `istio-cni` en modo ambient para crear un archivo de configuración CNI propiedad de Istio que contiene los contenidos del archivo de configuración CNI primario y el complemento CNI de Istio. Esta función es una solución al problema del tráfico que omite la mesh al reiniciar el nodo cuando el `DaemonSet` de istio-cni no está listo, el complemento CNI de Istio no está instalado, o el complemento no se invoca para configurar la redirección de tráfico de los pods a sus ztunnels de nodo. Esta función se habilita configurando `cni.istioOwnedCNIConfig` a `true` en los valores del chart Helm de `istio-cni`. Si no se establece ningún valor para `cni.istioOwnedCNIConfigFilename`, el archivo de configuración CNI propiedad de Istio se llamará `02-istio-cni.conflist`. El `istioOwnedCNIConfigFilename` debe tener una prioridad lexicográfica mayor que el nombre del archivo de configuración CNI primario. Los complementos CNI ambient y encadenado deben estar habilitados para que esta función funcione.

- **Añadidos** mecanismos de seguridad al controlador de despliegue de gateway para validar tipos de objetos, nombres y namespaces,
  evitando la creación de recursos de Kubernetes arbitrarios mediante inyección de plantillas.
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **Añadido** un mecanismo de reintentos al comprobar si un pod tiene ambient habilitado en `istio-cni`.
  Esto es para abordar posibles fallos transitorios que resulten en una posible omisión de la mesh. Esta función
  está desactivada por defecto y puede habilitarse configurando `ambient.enableAmbientDetectionRetry` en el chart de `istio-cni`.

- **Añadida** autorización basada en namespace para los endpoints de depuración en el puerto 15014.
  Los namespaces que no son del sistema quedan restringidos a los endpoints `config_dump`/`ndsz`/`edsz` y solo a proxies del mismo namespace.
  Se puede deshabilitar con `ENABLE_DEBUG_ENDPOINT_AUTH=false` si es necesario por compatibilidad.

- **Corregidos** errores de búsqueda de funciones de traducción para MeshConfig y MeshNetworks en istioctl.
  ([Issue #57967](https://github.com/istio/istio/issues/57967))

- **Corregido** un error donde el estado de `BackendTLSPolicy` podía perder el seguimiento del Gateway `ancestorRef` debido a corrupción del índice interno.
  ([Issue #58731](https://github.com/istio/istio/pull/58731))

- **Corregido** un problema donde el `DaemonSet` de istio-cni trataba los cambios de `NodeAffinity` como actualizaciones,
  haciendo que la configuración CNI quedara incorrectamente en su lugar cuando un nodo ya no coincidía con las reglas de `NodeAffinity` del `DaemonSet`.
  ([Issue #58768](https://github.com/istio/istio/issues/58768))

- **Corregida** la validación de anotaciones de recursos para rechazar caracteres de nueva línea y de control que podrían inyectar contenedores en las especificaciones de pods mediante la representación de plantillas.
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

- **Corregido** el mapeo incorrecto de `meshConfig.tlsDefaults.minProtocolVersion` a `tls_minimum_protocol_version` en el contexto TLS descendente.

- **Corregido** un problema que causaba que el registro de clústeres del multiclúster ambient se volviera inestable periódicamente, lo que llevaba a que se enviara configuración incorrecta a los proxies.

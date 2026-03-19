---
title: Anuncio de Istio 1.27.6
linktitle: 1.27.6
subtitle: Versión de Parche
description: Parche de Istio 1.27.6.
publishdate: 2026-02-10
release: 1.27.6
aliases:
    - /news/announcing-1.27.6
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.27.5 e Istio 1.27.6.

{{< relnote >}}

## Cambios

- **Añadidos** mecanismos de seguridad al controlador de despliegue de gateway para validar tipos de objetos, nombres y namespaces,
  evitando la creación de recursos de Kubernetes arbitrarios mediante inyección de plantillas.
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **Añadida** autorización basada en namespace para los endpoints de depuración en el puerto 15014.
  Los namespaces que no son del sistema quedan restringidos a los endpoints `config_dump/ndsz/edsz` y solo a proxies del mismo namespace.
  Si es necesario por compatibilidad, este comportamiento puede desactivarse con `ENABLE_DEBUG_ENDPOINT_AUTH=false`.

- **Añadido** el campo `service.selectorLabels` al chart Helm del gateway para etiquetas de selector de servicio personalizadas durante las migraciones basadas en revisiones.

- **Corregida** la validación de anotaciones de recursos para rechazar caracteres de nueva línea y de control que podrían inyectar contenedores en las especificaciones de pods mediante la representación de plantillas.
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

- **Corregido** el mapeo incorrecto de `meshConfig.tlsDefaults.minProtocolVersion` a `tls_minimum_protocol_version` en el contexto TLS descendente.

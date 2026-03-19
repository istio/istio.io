---
title: Anuncio de Istio 1.28.3
linktitle: 1.28.3
subtitle: Versión de Parche
description: Parche de Istio 1.28.3.
publishdate: 2026-01-19
release: 1.28.3
aliases:
    - /news/announcing-1.28.3
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.28.2 e Istio 1.28.3.

{{< relnote >}}

## Cambios

- **Añadido** el campo `service.selectorLabels` al chart Helm del gateway para etiquetas de selector de servicio personalizadas durante las migraciones basadas en revisiones.

- **Corregido** un problema con fugas de memoria de goroutine en modo ambient.
  ([Issue #58478](https://github.com/istio/istio/issues/58478))

- **Corregido** un problema en el multiclúster ambient donde los fallos del informer para clústeres remotos no se solucionaban hasta el reinicio de istiod.
  ([Issue #58047](https://github.com/istio/istio/issues/58047))

- **Corregido** un problema con fallos en las operaciones NFT y fallos en la eliminación de pods.
  ([Issue #58492](https://github.com/istio/istio/issues/58492))

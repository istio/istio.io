---
title: Anuncio de Istio 1.27.7
linktitle: 1.27.7
subtitle: Versión de Parche
description: Parche de Istio 1.27.7.
publishdate: 2026-02-16
release: 1.27.7
aliases:
    - /news/announcing-1.27.7
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.27.6 e Istio 1.27.7.

{{< relnote >}}

## Actualización de seguridad

- [CVE-2025-61732](https://github.com/advisories/GHSA-8jvr-vh7g-f8gx) (CVSS score 8.6, High): Una discrepancia en el análisis de comentarios entre Go y C/C++ permitía la introducción de código malicioso en el binario cgo resultante.
- [CVE-2025-68121](https://github.com/advisories/GHSA-h355-32pf-p2xm) (CVSS score 4.8, Moderate): Un fallo en la reanudación de sesiones de `crypto/tls` permite que los handshakes reanudados tengan éxito cuando deberían fallar si ClientCAs o RootCAs se modifican entre el handshake inicial y el reanudado. Esto puede ocurrir al usar `Config.Clone` con mutaciones o `Config.GetConfigForClient`. Como resultado, los clientes pueden reanudar sesiones con servidores no previstos, y los servidores pueden reanudar sesiones con clientes no previstos.

## Cambios

No hay otros cambios introducidos en esta versión además de las actualizaciones de seguridad mencionadas anteriormente.

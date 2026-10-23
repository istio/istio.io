---
title: Anuncio de Istio 1.29.10
linktitle: 1.29.10
subtitle: Versión de Parche
description: Parche de Istio 1.29.10.
publishdate: 2026-10-21
release: 1.29.10
aliases:
    - /news/announcing-1.29.10
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.29.9 e Istio 1.29.10. 1.29 llegó al [fin de su vida útil](/news/support/announcing-1.29-eol/) el 15 de octubre de 2026, y esta es una versión excepcional para abordar [ISTIO-SECURITY-2026-008](/news/security/istio-security-2026-008). Te recomendamos actualizar a una versión soportada.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-008](/news/security/istio-security-2026-008).

- **Eliminada** la confianza en los certificados de CA intermedios comprometidos de eMudhra. El bundle de CA de las imágenes basadas en `ubuntu` y `distroless` ya no incluye `emSign ECC Root CA - G3`.
- **Actualizado** `rustls-webpki` en ztunnel a la versión 0.103.16, que rechaza las cadenas de certificados que contienen cualquiera de las claves de los CA intermedios comprometidos de eMudhra.
- Istio 1.29 se compila con Go 1.25, que ya no recibe correcciones, por lo que esta versión no incluye la corrección de Go para [CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943). istiod, `istioctl` y `pilot-agent` dependen únicamente del bundle de CA actualizado. Actualiza a 1.30.7 o 1.31.3 para obtener la corrección de Go.

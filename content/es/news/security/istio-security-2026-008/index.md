---
title: ISTIO-SECURITY-2026-008
subtitle: Boletín de Seguridad
description: Desconfianza de los certificados de CA intermedios comprometidos de eMudhra en las imágenes de Istio, Go y ztunnel.
cves: [CVE-2026-111943]
cvss: "N/A"
vector: ""
releases: ["1.31.0 to 1.31.2", "1.30.0 to 1.30.6", "1.29.0 to 1.29.9"]
publishdate: 2026-10-21
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## Compromiso de los CA intermedios de eMudhra

Las claves privadas de ocho certificados de CA intermedios de eMudhra, incluidos sus cross-signs de Sectigo, fueron [divulgadas como comprometidas](https://emudhra.we-have-a-problem.com/) el 20 de octubre de 2026. Cualquiera que posea una de estas claves puede emitir certificados para cualquier dominio que encadene a raíces en las que confían los bundles de CA públicos incluidos en las imágenes de Istio. Los navegadores que exigen Certificate Transparency estaban protegidos, pero Envoy, Go y ztunnel no exigen Certificate Transparency.

Esta versión elimina la confianza en estos CA intermedios:

- El bundle de CA de las imágenes de Istio basadas en `ubuntu` se actualiza a `ca-certificates` `20260816ubuntu0.24.04.1`, que elimina `emSign ECC Root CA - G3`.
- Las imágenes `distroless` se reconstruyen sobre una base actualizada de `cgr.dev/chainguard/static`, que elimina `emSign ECC Root CA - G3`.
- __[CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943)__: istiod, `istioctl` y `pilot-agent` se compilan con Go 1.26.10 (Istio 1.30 y 1.31), que rechaza las cadenas de certificados que contienen cualquiera de las claves de los CA intermedios comprometidos, independientemente de las raíces de confianza. Istio 1.29 se compila con Go 1.25, que ya no recibe correcciones, y depende únicamente del bundle de CA actualizado. Recomendamos a los usuarios de 1.29 actualizar a una versión soportada para obtener la corrección de Go.
- ztunnel se actualiza a `rustls-webpki` 0.103.16, que rechaza las cadenas de certificados que contienen cualquiera de las claves de los CA intermedios comprometidos.

Envoy no tiene una lista integrada de claves en las que no se confía y no comprueba la revocación a menos que se configure una CRL, por lo que los sidecars y los gateways dependen del bundle de CA actualizado.

## ¿Estoy afectado?

Los certificados mTLS de la propia mesh de Istio no están afectados. Estás potencialmente afectado si Istio confía en el bundle de CA público de la imagen, por ejemplo:

- Un `DestinationRule` con `tls.mode: SIMPLE` y sin `caCertificates` ni `credentialName`, algo común en el egress hacia servicios HTTPS externos mediante un `ServiceEntry`.
- `RequestAuthentication` con un `jwksUri`, que istiod obtiene usando el bundle de CA del sistema.
- `XDS_ROOT_CA=SYSTEM` u otras configuraciones en las que `pilot-agent` o ztunnel se conectan a istiod usando el bundle de CA del sistema.

## Mitigación

- Para usuarios de Istio 1.31: actualiza a **1.31.3** o posterior.
- Para usuarios de Istio 1.30: actualiza a **1.30.7** o posterior.
- Para usuarios de Istio 1.29: actualiza a **1.29.10**. 1.29 llegó al [fin de su vida útil](/news/support/announcing-1.29-eol/) el 15 de octubre de 2026, y esta es una versión excepcional. Planifica una actualización a 1.30 o posterior.
- Si no puedes actualizar, define `caCertificates` (o `credentialName`) en los recursos `DestinationRule` de los servicios externos en lugar de depender del bundle de CA del sistema, o define `caCrl` con las CRL de los CA intermedios revocados.

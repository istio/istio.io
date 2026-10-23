---
title: Anuncio de Istio 1.30.7
linktitle: 1.30.7
subtitle: Versión de Parche
description: Parche de Istio 1.30.7.
publishdate: 2026-10-21
release: 1.30.7
aliases:
    - /news/announcing-1.30.7
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.30.6 e Istio 1.30.7.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-008](/news/security/istio-security-2026-008).

- **Eliminada** la confianza en los certificados de CA intermedios comprometidos de eMudhra. El bundle de CA de las imágenes basadas en `ubuntu` y `distroless` ya no incluye `emSign ECC Root CA - G3`.
- __[CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943)__: Se actualizó Go a 1.26.10, que rechaza las cadenas de certificados que contienen cualquiera de las claves de los CA intermedios comprometidos de eMudhra en istiod, `istioctl` y `pilot-agent`.
- **Actualizado** `rustls-webpki` en ztunnel a la versión 0.103.16, que rechaza las cadenas de certificados que contienen cualquiera de las claves de los CA intermedios comprometidos de eMudhra.

## Cambios

- **Corregido** que el controlador de node-untaint de ambient eliminara el taint `cni.istio.io/not-ready` cuando solo istio-cni estaba listo. Ahora también puede esperar a que ztunnel esté listo en el nodo, de modo que los pods no se programen en un nodo cuyo ztunnel sigue bloqueado. Está deshabilitado por defecto en esta rama de versiones y se habilita con `PILOT_NODE_UNTAINT_CHECK_ZTUNNEL=true`. Solo se aplica cuando ambient está habilitado. ([Issue #52073](https://github.com/istio/istio/issues/52073))
- **Corregido** que istiod fallara al iniciar cuando el certificado de CA autofirmado de `istio-ca-secret` ha expirado, lo que puede ocurrir cuando el deployment se escala a cero durante más tiempo que el TTL del certificado. Ahora el certificado expirado se renueva automáticamente usando la clave privada existente.
- **Corregido** que `istioctl bug-report --duration` no filtrara los logs cuando se usaba sin `--end-time`.

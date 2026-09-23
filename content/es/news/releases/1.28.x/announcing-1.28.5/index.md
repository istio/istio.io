---
title: Anuncio de Istio 1.28.5
linktitle: 1.28.5
subtitle: Versión de Parche
description: Parche de Istio 1.28.5.
publishdate: 2026-03-10
release: 1.28.5
aliases:
    - /news/announcing-1.28.5
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.28.4 e Istio 1.28.5.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-001](/news/security/istio-security-2026-001).

### CVEs de Envoy

- [CVE-2026-26308](https://nvd.nist.gov/vuln/detail/CVE-2026-26308) (CVSS score 7.5, High): Corrección del bypass de cabecera multivalor en RBAC.
- [CVE-2026-26311](https://nvd.nist.gov/vuln/detail/CVE-2026-26311) (CVSS score 5.9, Medium): Métodos de decodificación HTTP bloqueados tras el reinicio descendente.
- [CVE-2026-26310](https://nvd.nist.gov/vuln/detail/CVE-2026-26310) (CVSS score 5.9, Medium): Corrección de fallo en `getAddressWithPort()` con dirección IPv6 con ámbito.
- [CVE-2026-26309](https://nvd.nist.gov/vuln/detail/CVE-2026-26309) (CVSS score 5.3, Medium): Corrección de escritura JSON con desfase de uno.
- [CVE-2026-26330](https://nvd.nist.gov/vuln/detail/CVE-2026-26330) (CVSS score 5.3, Medium): Corrección de fallo en la fase de respuesta de rate limiting.

### CVEs de Istio

- __[CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838)__ / __[GHSA-974c-2wxh-g4ww](https://github.com/istio/istio/security/advisories/GHSA-974c-2wxh-g4ww)__: (CVSS score 6.9, Medium): Los endpoints de depuración permiten acceso a datos del proxy entre namespaces.
  Reportado por [1seal](https://github.com/1seal).
- __[CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837)__ / __[GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c)__: (CVSS score 8.7, High): Un fallo del resolvedor JWKS puede permitir la omisión de autenticación mediante claves predeterminadas conocidas.
  Reportado por [1seal](https://github.com/1seal).

### Correcciones de seguridad de Istio

- **Corregidos** los endpoints de depuración XDS en el puerto de texto plano 15010 para requerir autenticación, evitando el acceso no autenticado a la configuración del proxy.
  Reportado por [1seal](https://github.com/1seal).
- **Corregido** el SSRF potencial en la obtención de imágenes de `WasmPlugin` mediante la validación de las URLs de realm del token bearer.
  Reportado por [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Corregidos** los endpoints de depuración HTTP en el puerto 15014 para aplicar autorización basada en namespace, evitando el acceso a datos del proxy entre namespaces.
  Reportado por [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Añadida** la posibilidad de especificar namespaces autorizados para los endpoints de depuración cuando `ENABLE_DEBUG_ENDPOINT_AUTH=true`. Se habilita configurando `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` con una lista separada por comas de namespaces autorizados. El namespace del sistema (normalmente `istio-system`) siempre está autorizado.

## Cambios

- **Corregido** un problema donde las configuraciones de `InferencePool` se perdían durante la fusión de `VirtualService` cuando múltiples `HTTPRoutes` que hacían referencia a diferentes `InferencePools` estaban vinculados al mismo Gateway.
  ([Issue #58392](https://github.com/istio/istio/issues/58392))

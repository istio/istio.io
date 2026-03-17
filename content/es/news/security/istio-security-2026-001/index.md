---
title: ISTIO-SECURITY-2026-001
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy y correcciones de seguridad de Istio.
cves: [CVE-2026-26308, CVE-2026-26309, CVE-2026-26310, CVE-2026-26311, CVE-2026-26330, CVE-2026-31837, CVE-2026-31838]
cvss: "8.7"
vector: "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.29.0", "1.28.0 to 1.28.4", "1.27.0 to 1.27.7"]
publishdate: 2026-03-10
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2026-26308](https://nvd.nist.gov/vuln/detail/CVE-2026-26308)__: (CVSS score 7.5, High): Fixed RBAC header matcher to validate each header value individually instead of concatenating multiple header values into a single string. This prevents potential bypasses when requests contain multiple values for the same header.
- __[CVE-2026-26311](https://nvd.nist.gov/vuln/detail/CVE-2026-26311)__: (CVSS score 5.9, Medium): Fixed an issue where filter chain execution could continue on HTTP streams that had been reset but not yet destroyed, potentially causing use-after-free conditions.
- __[CVE-2026-26310](https://nvd.nist.gov/vuln/detail/CVE-2026-26310)__: (CVSS score 5.9, Medium): Fixed a crash in `Utility::getAddressWithPort` when called with a scoped IPv6 address (e.g., `fe80::1%eth0`).
- __[CVE-2026-26309](https://nvd.nist.gov/vuln/detail/CVE-2026-26309)__: (CVSS score 5.3, Medium): Fixed an off-by-one write in `JsonEscaper::escapeString()` that could corrupt the string null terminator.
- __[CVE-2026-26330](https://nvd.nist.gov/vuln/detail/CVE-2026-26330)__: (CVSS score 5.3, Medium): Fixed a bug in the gRPC rate limit client that could lead to potential use-after-free issues. Only affects Istio 1.28 and 1.29.

### CVEs de Istio

- __[CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838)__ / __[GHSA-974c-2wxh-g4ww](https://github.com/istio/istio/security/advisories/GHSA-974c-2wxh-g4ww)__: (CVSS score 6.9, Medium): Debug Endpoints Allow Cross-Namespace Proxy Data Access.
  Reported by [1seal](https://github.com/1seal).
- __[CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837)__ / __[GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c)__: (CVSS score 8.7, High): JWKS Resolver Failure May Allow Authentication Bypass Using Known Default Keys.
  Reported by [1seal](https://github.com/1seal).

### Otras correcciones de seguridad de Istio

- **Fixed** XDS debug endpoints on plaintext port 15010 to require authentication, preventing unauthenticated access to proxy configuration.
  Reported by [1seal](https://github.com/1seal).
- **Fixed** potential SSRF in `WasmPlugin` image fetching by validating bearer token realm URLs.
  Reported by [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Fixed** HTTP debug endpoints on port 15014 to enforce namespace-based authorization, preventing cross-namespace proxy data access.
  Reported by [Sergey Kanibor (Luntry)](https://github.com/r0binak).

## ¿Estoy afectado?

Todos los usuarios que ejecutan versiones de Istio afectadas están potencialmente en riesgo.

- La vulnerabilidad de coincidencia de cabeceras RBAC en Envoy puede ser explotada cuando las políticas de autorización coinciden con cabeceras que pueden contener múltiples valores, lo que permite eludir las políticas.

- La vulnerabilidad del resolvedor JWKS podría permitir eludir la autenticación cuando falla una solicitud de JWKS, ya que istiod recurre a claves predeterminadas conocidas públicamente que un atacante puede usar para falsificar JWTs válidos. Los usuarios con recursos `RequestAuthentication` configurados con `jwksUri` están directamente afectados.

- La vulnerabilidad del endpoint de depuración XDS permitía el acceso no autenticado a los endpoints de depuración (como `config_dump`) en el puerto XDS de texto plano 15010, lo que podría filtrar configuración sensible del proxy a cualquier workload con acceso de red a istiod. Después de actualizar, la autenticación de los endpoints de depuración está habilitada por defecto. Las variables de entorno `ENABLE_DEBUG_ENDPOINT_AUTH` y `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` pueden usarse para ajustar la compatibilidad con sistemas heredados si es necesario.

- La vulnerabilidad SSRF en la obtención de imágenes de `WasmPlugin` podría permitir a un atacante redirigir las credenciales del token bearer a una URL arbitraria.

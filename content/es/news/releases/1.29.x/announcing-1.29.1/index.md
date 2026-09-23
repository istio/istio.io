---
title: Anuncio de Istio 1.29.1
linktitle: 1.29.1
subtitle: Versión de Parche
description: Parche de Istio 1.29.1.
publishdate: 2026-03-10
release: 1.29.1
aliases:
    - /news/announcing-1.29.1
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.29.0 e Istio 1.29.1.

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
- **Corregidos** los endpoints de depuración HTTP en el puerto 15014 para aplicar autorización basada en namespace, evitando el acceso a datos del proxy entre namespaces.
  Reportado por [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Añadida** la posibilidad de especificar namespaces autorizados para los endpoints de depuración cuando `ENABLE_DEBUG_ENDPOINT_AUTH=true`. Se habilita configurando `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` con una lista separada por comas de namespaces autorizados. El namespace del sistema (normalmente `istio-system`) siempre está autorizado.
- **Corregido** el resolvedor JWKS para usar un fallback seguro cuando la obtención de JWKS falla, evitando la omisión de autenticación mediante claves predeterminadas de conocimiento público.
  Reportado por [1seal](https://github.com/1seal).
- **Corregido** el SSRF potencial en la obtención de imágenes de `WasmPlugin` mediante la validación de las URLs de realm del token bearer.
  Reportado por [Sergey Kanibor (Luntry)](https://github.com/r0binak).

## Cambios

- **Corregido** el mapeo incorrecto de `meshConfig.tlsDefaults.minProtocolVersion` a `tls_minimum_protocol_version` en el contexto TLS descendente.
- **Corregido** el análisis del origen CORS de la Gateway API para ser más estricto con los comodines, y para ignorar las solicitudes preflight que no coincidan.
  ([Issue #59018](https://github.com/istio/istio/issues/59018))
- **Corregido** un problema donde los waypoints no podían añadir el filtro de escucha del inspector TLS cuando solo existían puertos TLS,
  haciendo que el enrutamiento basado en SNI fallara para `ServiceEntry` con comodines con `resolution: DYNAMIC_DNS`.
  ([Issue #59024](https://github.com/istio/istio/issues/59024))
- **Corregido** un problema donde el descubrimiento de metadatos de peers basado en baggage interfería con las políticas de tráfico TLS o PROXY.
  Como solución a corto plazo, el descubrimiento de metadatos basado en baggage está desactivado para las rutas con políticas de tráfico TLS o PROXY configuradas,
  lo que puede resultar en telemetría incompleta en despliegues multiclúster.
  ([Issue #59117](https://github.com/istio/istio/issues/59117))
- **Corregida** una referencia nula que ocurre durante el proceso de actualización en el despliegue multi-primary.
  ([Issue #59153](https://github.com/istio/istio/issues/59153))
- **Corregida** una referencia nula en la validación de `ServiceEntry` para la resolución `DYNAMIC_DNS` que podía causar que istiod se interrumpiera.
  ([Issue #59171](https://github.com/istio/istio/issues/59171))
- **Corregido** que istiod se interrumpiera cuando `PILOT_ENABLE_AMBIENT=true` pero `AMBIENT_ENABLE_MULTI_NETWORK` no está configurado
  y existe un recurso `WorkloadEntry` con una red diferente a la del clúster local.
- **Corregido** un problema donde establecer los límites o solicitudes de recursos a `null` causaba errores de validación.
  ([Issue #58805](https://github.com/istio/istio/issues/58805))

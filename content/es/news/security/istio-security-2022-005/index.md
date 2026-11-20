---
title: ISTIO-SECURITY-2022-005
subtitle: Boletín de seguridad
description: En ciertas configuraciones, los encabezados mal formados que recibe Envoy pueden provocar accesos inesperados a memoria, comportamiento indefinido o fallos.
cves: [CVE-2022-31045, CVE-2022-29225, CVE-2022-29224, CVE-2022-29226, CVE-2022-29228, CVE-2022-29227]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.12.0", "1.12.0 to 1.12.7", "1.13.0 to 1.13.4", "1.14.0"]
publishdate: 2022-06-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-31045

- [CVE-2022-31045](https://github.com/istio/istio/security/advisories/GHSA-xwx5-5c9g-x68x) (Puntuación CVSS: 5.9, gravedad moderada): Acceso inválido a memoria.
  En ciertas configuraciones, los encabezados mal formados que recibe Envoy pueden provocar accesos inesperados a memoria, comportamiento indefinido o fallos.

### CVE de Envoy

Estas vulnerabilidades de Envoy no afectan directamente a las funcionalidades de Istio. Las correcciones se incluyen en las versiones 1.12.8, 1.13.5 y 1.14.1.

- [CVE-2022-29225](https://github.com/envoyproxy/envoy/security/advisories/GHSA-75hv-2jjj-89hh) (Puntuación CVSS: 7.5, gravedad alta): Riesgo de agotamiento de recursos en los descompresores.
  Los descompresores acumulan los datos descomprimidos en un búfer intermedio antes de sustituir el cuerpo en `decode/encodeBody`. Una expansión desproporcionada de los datos comprimidos puede agotar la memoria del proxy.

- [CVE-2022-29224](https://github.com/envoyproxy/envoy/security/advisories/GHSA-m4j9-86g3-8f49) (Puntuación CVSS: 5.9, gravedad moderada): Fallo de segmentación en `GrpcHealthCheckerImpl`.
  Si Envoy comprueba por gRPC el estado de un servidor upstream controlado por un atacante, en ciertas circunstancias puede desreferenciar un puntero nulo y terminar de forma inesperada.

- [CVE-2022-29226](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h45c-2f94-prxh) (Puntuación CVSS: 10.0, gravedad crítica): Omisión de la autenticación en el filtro OAuth.
  El filtro OAuth da por hecho que los tokens de acceso ya se validaron. Esa suposición puede dar acceso a un cliente sin autenticar y omitir el flujo de autenticación previsto.

- [CVE-2022-29228](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rww6-8h7g-8jf6) (Puntuación CVSS: 7.5, gravedad alta): El filtro OAuth llama a `continueDecoding()` desde `decodeHeaders()`.
  El filtro OAuth intenta continuar la cadena de filtros después de emitir una respuesta local. Esto activa un `ASSERT()` en las versiones más recientes y corrompe la memoria en las anteriores.

- [CVE-2022-29227](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rm2p-qvf6-pvr6) (Puntuación CVSS: 7.5, gravedad alta): Fallo en redirecciones internas de solicitudes con cuerpo o campos de tráiler HTTP.
  Envoy puede fallar si una redirección interna de una solicitud con cuerpo o campos de tráiler HTTP genera una respuesta local.

## ¿Estoy afectado?

El riesgo es mayor si tienes un `Gateway` de entrada de Istio expuesto al tráfico externo.

## Agradecimientos

Agradecemos a Otto van der Schaaf, de Red Hat, por el reporte.

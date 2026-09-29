---
title: ISTIO-SECURITY-2026-004
subtitle: Boletín de Seguridad
description: CVE reportado por Envoy.
cves: [CVE-2026-47774]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.30.0", "1.29.0 to 1.29.3", "1.28.0 to 1.28.7"]
publishdate: 2026-06-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8)__: (CVSS score 7.5, High): Agotamiento de memoria en HTTP/2 mediante amplificación HPACK de cabeceras cookie.
  Los bytes de las cabeceras cookie no se contabilizan completamente durante la validación del tamaño de las cabeceras de solicitud, y los límites del bloque de cabeceras HPACK se aplican sobre los bytes codificados sin un límite correspondiente en el tamaño total de las cabeceras decodificadas.
  Un atacante remoto no autenticado puede aprovechar esto para agotar la memoria en el proceso Envoy, causando denegación de servicio mediante terminación por OOM.

## ¿Estoy afectado?

Estás afectado si ejecutas una versión afectada de Istio y aceptas tráfico HTTP/2 downstream.
Esto incluye cualquier despliegue de Istio que exponga servicios a clientes externos o workloads no confiables mediante
HTTP/2 o gRPC, ya que un atacante puede enviar solicitudes especialmente elaboradas con cabeceras cookie grandes para provocar
un consumo excesivo de memoria.

## Mitigación

- Para usuarios de Istio 1.30: actualiza a **1.30.1** o posterior.
- Para usuarios de Istio 1.29: actualiza a **1.29.4** o posterior.
- Para usuarios de Istio 1.28: actualiza a **1.28.8** o posterior.

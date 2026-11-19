---
title: ISTIO-SECURITY-2022-006
subtitle: Boletín de seguridad
description: En ciertas configuraciones, los encabezados mal formados que recibe Envoy pueden provocar accesos inesperados a memoria, comportamiento indefinido o fallos.
cves: [CVE-2022-31045]
cvss: "5.9"
vector: "AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.13.6", "1.14.2"]
publishdate: 2022-07-26
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## Evita usar Istio 1.14.2 e Istio 1.13.6

Debido a un problema en el proceso de publicación, las compilaciones de Istio 1.14.2 y 1.13.6 no incluyeron la corrección de [CVE-2022-31045](/news/security/istio-security-2022-005/#cve-2022-31045).

Por el momento, recomendamos evitar la instalación de 1.14.2 y 1.13.6 en producción. Si ya instalaste alguna de ellas, puedes volver a Istio 1.14.1 o 1.13.5. Está previsto publicar Istio 1.14.3 e Istio 1.13.7 más adelante esta semana.

---
title: ISTIO-SECURITY-2022-008
subtitle: Boletín de seguridad
description: Suplantación de identidad con acceso a localhost.
cves: [CVE-2022-39388]
cvss: "7.6"
vector: "AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.15.2"]
publishdate: 2022-11-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-39388

- __[CVE-2022-39388](https://github.com/istio/istio/security/advisories/GHSA-6c6p-h79f-g6p4)__:
  (Puntuación CVSS: 7.6, gravedad alta): Suplantación de identidad con acceso a localhost.

Un usuario con acceso a Istiod mediante localhost puede suplantar la identidad de cualquier workload dentro de la service mesh.

## ¿Estoy afectado?

El riesgo es mayor si ejecutas Istio 1.15.2 y hay usuarios con acceso a la máquina donde se ejecuta Istiod.

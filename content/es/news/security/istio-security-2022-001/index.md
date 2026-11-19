---
title: ISTIO-SECURITY-2022-001
subtitle: Boletín de seguridad
description: Política de autorización para reglas de host durante las actualizaciones.
cves: [CVE-2022-21679]
cvss: "6.8"
vector: "AV:N/AC:H/PR:N/UI:R/S:U/C:H/I:H/A:N"
releases: ["1.12.0 a 1.12.1"]
publishdate: 2022-01-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-21679

Istio 1.12.0 y 1.12.1 generan una configuración incorrecta para los proxies de la versión 1.11. El problema afecta a los campos `hosts` y `notHosts` de la política de autorización. Al usar estos campos, la configuración incorrecta podría hacer que ciertas solicitudes eludan la política o que esta las rechace por error.

El problema se presenta cuando se combina un plano de control 1.12.0 o 1.12.1 con un plano de datos 1.11 y la política de autorización usa `hosts` o `notHosts`.

### Mitigación

* Actualiza a Istio 1.12.2.
* Si la política de autorización usa `hosts` o `notHosts`, evita combinar un plano de control 1.12.0 o 1.12.1 con un plano de datos 1.11.

## Agradecimientos

Agradecemos a Yangmin Zhu y a @Aakash2017.

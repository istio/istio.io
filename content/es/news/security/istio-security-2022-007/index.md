---
title: ISTIO-SECURITY-2022-007
subtitle: Boletín de seguridad
description: Denegación de servicio relacionada con la biblioteca de expresiones regulares de Go.
cves: [CVE-2022-39278]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["Todas las versiones anteriores a 1.13", "1.13.0 a 1.13.8", "1.14.0 a 1.14.4", "1.15.0 a 1.15.1"]
publishdate: 2022-10-12
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-39278

- __[CVE-2022-39278](https://github.com/istio/istio/security/advisories/GHSA-86vr-4wcv-mm9w)__:
  (Puntuación CVSS: 7.5, gravedad alta): Denegación de servicio relacionada con la biblioteca de expresiones regulares de Go.

Un error al procesar solicitudes puede provocar la caída de Istiod, el plano de control de Istio. El riesgo aumenta si se expone públicamente el servicio de webhooks de validación o mutación de Kubernetes. El endpoint usa TLS en el puerto 15017 y no requiere autenticación.

En instalaciones sencillas, normalmente solo se puede acceder a Istiod desde el propio clúster, lo que limita el alcance del impacto. En algunos despliegues, especialmente si el plano de control se ejecuta en un clúster distinto, el puerto queda expuesto a Internet.

### CVE de Go

La vulnerabilidad de la biblioteca de expresiones regulares se documenta en el siguiente reporte de Go. La corrección está disponible en Go 1.18.7 y 1.19.2.

- [CVE-2022-41715](https://github.com/golang/go/issues/55949)

## ¿Estoy afectado?

El riesgo es mayor si usas una versión afectada de Istio y ejecutas Istiod en un entorno externo o lo has expuesto al exterior.

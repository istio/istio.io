---
title: ISTIO-SECURITY-2022-004
subtitle: Boletín de seguridad
description: Denegación de servicio en el control plane sin autenticación por agotamiento de la pila.
cves: [CVE-2022-24726, CVE-2022-24921]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.11.0", "1.11.0 to 1.11.7", "1.12.0 to 1.12.4", "1.13.0 to 1.13.1"]
publishdate: 2022-03-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-24726

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (Puntuación CVSS: 7.5, gravedad alta): Denegación de servicio en el control plane sin autenticación por agotamiento de la pila.

Istiod, el control plane de Istio, tiene un error en el procesamiento de solicitudes que puede provocar la caída del proceso. Si el servicio de webhooks de validación o mutación de Kubernetes está expuesto públicamente, un cliente externo puede desencadenar la denegación de servicio sin autenticarse. El endpoint usa TLS en el puerto 15017.

En instalaciones sencillas, normalmente solo se puede acceder a Istiod desde el propio clúster, lo que limita el alcance del impacto. En algunos despliegues, especialmente si el control plane se ejecuta en un clúster distinto, el puerto queda expuesto a Internet.

Istio considera que esta es una vulnerabilidad de día cero debido a la publicación de [CVE-2022-24921](https://github.com/advisories/GHSA-6685-ffxp-xm6f) por parte del equipo de Go.

### CVE de Envoy

La siguiente vulnerabilidad de Envoy también se corrigió en Istio 1.11.8, 1.12.5 y 1.13.2. La corrección se publicó en [https://github.com/envoyproxy/envoy](https://github.com/envoyproxy/envoy) para las versiones de Envoy incluidas en versiones anteriores de Istio. Como se explica en [ISTIO-SECURITY-2022-003](/news/security/istio-security-2022-003), esta vulnerabilidad no afectaba a Istio.

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
  (Puntuación CVSS: 3.1, gravedad baja): Omisión de comprobaciones del uso extendido de claves y de los propósitos de confianza de certificados X.509.

La siguiente vulnerabilidad también se corrigió en Istio 1.12.5 y 1.13.2.

- __[CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2)__
  (Puntuación CVSS: 3.1, gravedad baja): Omisión de la comprobación de `subjectAltName` y de las restricciones `nameConstraints` en certificados X.509.

## ¿Estoy afectado?

El riesgo es mayor si usas un Istiod externo o si has expuesto Istiod al exterior.

## Agradecimientos

Agradecemos a John Howard (Google) por el reporte y la corrección.

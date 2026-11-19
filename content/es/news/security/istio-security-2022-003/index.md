---
title: ISTIO-SECURITY-2022-003
subtitle: Boletín de seguridad
description: Varias vulnerabilidades relacionadas con la denegación de servicio en Istiod y con Envoy.
cves: [CVE-2022-23635, CVE-2021-43824, CVE-2021-43825, CVE-2021-43826, CVE-2022-21654, CVE-2022-21655, CVE-2022-23606]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["Todas las versiones anteriores a 1.11.0", "1.11.0 a 1.11.6", "1.12.0 a 1.12.3", "1.13.0"]
publishdate: 2022-02-22
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-23635

- __[CVE-2022-23635](https://github.com/istio/istio/security/advisories/GHSA-856q-xv3c-7f2f)__:
  (Puntuación CVSS: 7.5, gravedad alta): Denegación de servicio en el plano de control sin autenticación.

Un error al procesar solicitudes puede provocar la caída de Istiod, el plano de control de Istio. El endpoint usa TLS en el puerto 15012 y no requiere autenticación.

En instalaciones sencillas, normalmente solo se puede acceder a Istiod desde el propio clúster, lo que limita el alcance del impacto. En algunos despliegues, especialmente en [topologías multiclúster](/docs/setup/install/multicluster/primary-remote/), este puerto queda expuesto a Internet.

### CVE de Envoy

En el momento de la publicación, Istio no considera que estas vulnerabilidades de Envoy lo afecten. Se incluyen por transparencia.

| ID de CVE | Puntuación y gravedad | Descripción | Corregido en 1.13.1 | Corregido en 1.12.4 | Corregido en 1.11.7 |
|-----------|-----------------------|-------------|---------------------|---------------------|---------------------|
| [CVE-2021-43824](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vj5m-rch8-5r2p) | 6.5, moderada | Posible desreferenciación de un puntero nulo al usar una condición `safe_regex` en el filtro JWT. | Sí | Sí | Sí |
| [CVE-2021-43825](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h69p-g6xg-mhhh) | 6.1, moderada | Uso de memoria liberada al superar el límite del búfer de salida tras ampliar la respuesta con filtros. | Sí | Sí | Sí |
| [CVE-2021-43826](https://github.com/envoyproxy/envoy/security/advisories/GHSA-cmx3-fvgf-83mf) | 6.1, moderada | Uso de memoria liberada durante el establecimiento de conexiones en túneles TCP sobre HTTP. | Sí | Sí | Sí |
| [CVE-2022-21654](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5j4x-g36v-m283) | 7.3, alta | Una gestión incorrecta de la configuración permite reutilizar sesiones mTLS sin volver a validarlas tras un cambio en los ajustes de validación. | Sí | Sí | Sí |
| [CVE-2022-21655](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7r5p-7fmh-jxpg) | 7.5, alta | Gestión incorrecta de redirecciones internas a rutas con una entrada de respuesta directa. | Sí | Sí | Sí |
| [CVE-2022-23606](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9vp2-4cp7-vvxf) | 4.4, moderada | Agotamiento de la pila al eliminar un clúster mediante Cluster Discovery Service. | Sí | Sí | N/A |
| [CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2) | 3.1, baja | Omisión de la comprobación de `subjectAltName` y de las restricciones `nameConstraints` en certificados X.509. | No, en la próxima versión. | No, en la próxima versión. | Envoy no incorporó esta corrección a esa rama. |
| [CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g) | 3.1, baja | Omisión de comprobaciones del uso extendido de claves y de los propósitos de confianza de certificados X.509. | No, en la próxima versión. | No, en la próxima versión. | No, en la próxima versión. |

## ¿Estoy afectado?

El riesgo es mayor si ejecutas Istio en un entorno multiclúster o si has expuesto Istiod al exterior.

## Agradecimientos

Agradecemos a Adam Korczynski ([`ADA Logics`](https://adalogics.com)) y a John Howard (Google) por el reporte y la corrección.

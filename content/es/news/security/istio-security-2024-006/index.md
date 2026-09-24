---
title: ISTIO-SECURITY-2024-006
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy.
cves: [CVE-2024-45807, CVE-2024-45808, CVE-2024-45806, CVE-2024-45809, CVE-2024-45810]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 to 1.22.4", "1.23.0 to 1.23.1"]
publishdate: 2024-09-19
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2024-45807](https://github.com/envoyproxy/envoy/security/advisories/GHSA-qc52-r4x5-9w37)__: (CVSS Score 7.5, High): oghttp2 puede causar un crash en `OnBeginHeadersForStream`.

- __[CVE-2024-45808](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p222-xhp9-39rc)__: (CVSS Score 6.5, Moderate): La falta de validación del campo `REQUESTED_SERVER_NAME` en los logs de acceso permite inyectar contenido inesperado en los logs de acceso.

- __[CVE-2024-45806](https://github.com/envoyproxy/envoy/security/advisories/GHSA-ffhv-fvxq-r6mf)__: (CVSS Score 6.5, Moderate): Posibilidad de que fuentes externas manipulen las cabeceras `x-envoy`.

- __[CVE-2024-45809](https://github.com/envoyproxy/envoy/security/advisories/GHSA-wqr5-qmq7-3qw3)__: (CVSS Score 5.3, Moderate): Crash del filtro JWT al limpiar la caché de rutas con JWKs remotos.

- __[CVE-2024-45810](https://github.com/envoyproxy/envoy/security/advisories/GHSA-qm74-x36m-555q)__: (CVSS Score 6.5, Moderate): Envoy causa un crash en `LocalReply` del cliente HTTP asíncrono.

## ¿Estoy afectado?

Estás afectado si utilizas Istio 1.22.0 a 1.22.4 o 1.23.0 a 1.23.1.

Si despliegas un Istio Ingress Gateway, eres potencialmente vulnerable a la manipulación de cabeceras `x-envoy` por fuentes externas. Envoy anteriormente consideraba todas las IPs privadas como internas
por defecto y, como resultado, no saneaba las cabeceras de fuentes externas con IPs privadas. Envoy añadió soporte para el flag `envoy.reloadable_features.explicit_internal_address_config`
para no confiar explícitamente en todas las IPs. Envoy e Istio actualmente deshabilitan el flag por defecto por compatibilidad con versiones anteriores. En futuras versiones de Envoy e Istio, el flag
`envoy.reloadable_features.explicit_internal_address_config` se habilitará por defecto. El flag de Envoy puede configurarse a nivel de toda la mesh o por proxy mediante [ProxyConfig](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig)
en `runtimeValues`.

Ejemplo de configuración a nivel de mesh:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
{{< /text >}}

Ejemplo de configuración por proxy:

{{< text yaml >}}
annotations:
  proxy.istio.io/config: |
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
{{< /text >}}

Ten en cuenta que los campos de ProxyConfig no se configuran dinámicamente; los cambios requerirán un reinicio de los workloads para tener efecto.

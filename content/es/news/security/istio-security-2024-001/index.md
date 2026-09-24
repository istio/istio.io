---
title: ISTIO-SECURITY-2024-001
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy.
cves: [CVE-2024-23322, CVE-2024-23323, CVE-2024-23324, CVE-2024-23325, CVE-2024-23327]
cvss: "8.6"
vector: "AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:N/A:N"
releases: ["Todos de los lanzamientos antes de 1.19.0", "1.19.0 a 1.19.6", "1.20.0 a 1.20.2"]
publishdate: 2024-02-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

**Nota**: En el momento de la publicación, los siguientes avisos de seguridad aún no han sido publicados, pero deberían publicarse en breve.

- __[CVE-2024-23322](https://github.com/envoyproxy/envoy/security/advisories/GHSA-6p83-mfmh-qv38)__: (CVSS Score 7.5, High): Envoy causa un crash cuando se produce un tiempo de espera de solicitud por intento dentro del intervalo de backoff en estado inactivo.
- __[CVE-2024-23323](https://github.com/envoyproxy/envoy/security/advisories/GHSA-x278-4w4x-r7ch)__: (CVSS Score 4.3, Moderate): Uso excesivo de CPU cuando el matcher de plantillas URI está configurado usando regex.
- __[CVE-2024-23324](https://github.com/envoyproxy/envoy/security/advisories/GHSA-gq3v-vvhj-96j6)__: (CVSS Score 8.6, High): Ext auth puede ser eludido cuando el filtro del protocolo Proxy establece metadatos UTF-8 inválidos.
- __[CVE-2024-23325](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5m7c-mrwr-pm26)__: (CVSS Score 7.5, High): Envoy causa un crash cuando se utiliza un tipo de dirección no compatible con el SO.
- __[CVE-2024-23327](https://github.com/envoyproxy/envoy/security/advisories/GHSA-4h5x-x9vh-m29j)__: (CVSS Score 7.5, High): Crash en el protocolo proxy cuando el tipo de comando es LOCAL.

## ¿Estoy afectado?

La mayoría del comportamiento explotable está relacionado con el uso del Protocolo PROXY, utilizado principalmente en escenarios de gateway. Si tú o tus usuarios tienen el Protocolo PROXY habilitado, ya sea mediante `EnvoyFilter` o anotaciones de [configuración de proxy](/docs/ops/configuration/traffic-management/network-topologies/#proxy-protocol), hay exposición potencial.

Además del uso del protocolo PROXY, el uso del [operador de comandos](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage.html#command-operators) `%DOWNSTREAM_PEER_IP_SAN%` en los logs de acceso presenta exposición potencial.

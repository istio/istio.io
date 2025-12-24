---
title: ISTIO-SECURITY-2025-001
subtitle: Бюлетень безпеки
description: CVE, про які повідомляє Envoy.
cves: [CVE-2025-55162, CVE-2025-54588]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.27.0", "1.26.0 to 1.26.3", "1.25.0 to 1.25.4"]
publishdate: 2025-09-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2025-55162](https://github.com/envoyproxy/envoy/security/advisories/GHSA-95j4-hw7f-v2rh)__: (CVSS score 6.3, Moderate): Маршрут OAuth2 Filter Signout не очищає файли cookie через відсутність прапорця "secure;".
- __[CVE-2025-54588](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g9vw-6pvx-7gmw)__: (CVSS score 7.5, High): Використання після звільнення в кеші DNS

## Чи це впливає на мене? {#am-i-impacted}

Ви зазнаєте впливу, якщо використовуєте Istio 1.27.0, 1.26.0 до 1.26.3 або 1.25.0 до 1.25.4 і використовуєте файли cookie з префіксом `__Secure-` або `__Host-`, або використовуєте `EnvoyFilter` з `dynamic_forward_proxy`.

---
title: ISTIO-SECURITY-2024-007
subtitle: Бюлетень безпеки
description: CVE, про які повідомляє Envoy.
cves: [CVE-2024-53269, CVE-2024-53270, CVE-2024-53271]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 to 1.22.6", "1.23.0 to 1.23.3", "1.24.0 to 1.24.1"]
publishdate: 2024-12-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE {#cve}

### CVE Envoy {#envoy-cves}

- __[CVE-2024-53269](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mfqp-7mmj-rm53)__: (CVSS Score 4.5, Помірний): Happy Eyeballs: Перевірте, що `additional_address` є IP-адресами, замість того, щоб аварійно завершувати роботу при сортуванні.
- __[CVE-2024-53270](https://github.com/envoyproxy/envoy/security/advisories/GHSA-q9qv-8j52-77p3)__: (CVSS Score 7.5, Високий): HTTP/1: перевантаження надсилання призводить до аварійного завершення роботи, коли запит скидається заздалегідь.
- __[CVE-2024-53271](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rmm5-h2wv-mg4f)__: (CVSS Score 7.1, Високий): HTTP/1.1: кілька проблем з `envoy.reloadable_features.http1_balsa_delay_reset`.

## Чи це впливає на мене? {#am-i-impacted}

Це впливає на вас, якщо використовуєте Istio 1.22.0 до 1.22.6, 1.23.0 до 1.23.3 або 1.24 до 1.24.1, будь ласка, оновіться негайно. Якщо ви створили власний `EnvoyFilter` для увімкнення менеджера перевантаження, уникайте використання точки скидання навантаження `http1_server_abort_dispatch`.

---
title: ISTIO-SECURITY-2025-003
subtitle: Бюлетень безпеки
description: CVE, про які повідомляє Envoy.
cves: [CVE-2025-66220, CVE-2025-64527, CVE-2025-64763]
cvss: "8.1"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N"
releases: ["1.28.0", "1.27.0 to 1.27.3", "1.26.0 to 1.26.6"]
publishdate: 2025-12-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE {#cve}

### CVE Envoy {#envoy-cves}

- __[CVE-2025-66220](https://nvd.nist.gov/vuln/detail/CVE-2025-66220)__: (оцінка CVSS 8.1, Високий): TLS сертифікатний матчер для `match_typed_subject_alt_names` може некоректно трактувати сертифікати з `OTHERNAME` SAN, що містять вбудований null байт, як валідні.
- __[CVE-2025-64527](https://nvd.nist.gov/vuln/detail/CVE-2025-64527)__: (оцінка CVSS 6.5, Середній): Envoy аварійно завершується при налаштованій JWT автентифікації з віддаленим отриманням JWKS.
- __[CVE-2025-64763](https://nvd.nist.gov/vuln/detail/CVE-2025-64763)__: (оцінка CVSS 5.3, Середній): Потенційний request smuggling від early data після CONNECT upgrade.

## Чи це впливає на мене? {#am-i-impacted}

Якщо ви використовуєте Istio для прийому WebSocket-трафіку, ви потенційно вразливі до контрабанди запитів з ранніх даних після апгрейду CONNECT. Ви також можете бути вразливі, якщо використовуєте власні сертифікати з SAN `OTHERNAME` або власну автентифікацію JWT з віддаленим отриманням JWKS через `EnvoyFilter`.

---
title: ISTIO-SECURITY-2025-002
subtitle: Бюлетень безпеки
description: CVE, про які повідомляє Envoy.
cves: [CVE-2025-55162, CVE-2025-54588]
cvss: "6.6"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.27.0 to 1.27.1", "1.26.0 to 1.26.5"]
publishdate: 2025-10-20
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE {#cve}

### CVE Envoy {#envoy-cves}

- __[CVE-2025-62504](https://nvd.nist.gov/vuln/detail/CVE-2025-62504)__: (оцінка CVSS 6.5, Середній): Lua змінене досить велике тіло відповіді спричинить аварійне завершення Envoy.
- __[CVE-2025-62409](https://nvd.nist.gov/vuln/detail/CVE-2025-62409)__: (оцінка CVSS 6.6, Середній): Великі запити та відповіді можуть спричинити аварійне завершення пулу TCP зʼєднань.

## Чи це впливає на мене? {#am-i-impacted}

Ви зазнаєте впливу, якщо використовуєте Lua через `EnvoyFilter`, який повертає надмірно велике тіло відповіді, що перевищує `per_connection_buffer_limit_bytes` (за замовчуванням 1MB), або якщо у вас є великі запити та відповіді, де зʼєднання може бути закрите, але дані від upstream все ще надсилаються.

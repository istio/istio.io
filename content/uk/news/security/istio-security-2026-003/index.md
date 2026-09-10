---
title: ISTIO-SECURITY-2026-003
subtitle: Бюлетень безпеки
description: Виправлення безпеки Istio для обходу авторизації та SSRF.
cves: [CVE-2026-39350, CVE-2026-41413]
cvss: "5.4"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:L/A:N"
releases: ["1.29.0 to 1.29.1", "1.28.0 to 1.28.5"]
publishdate: 2026-04-20
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE {#cve}

### CVE Istio {#istio-cves}

- __[CVE-2026-39350](https://nvd.nist.gov/vuln/detail/CVE-2026-39350)__ / __[GHSA-9gcg-w975-3rjh](https://github.com/istio/istio/security/advisories/GHSA-9gcg-w975-3rjh)__: (оцінка CVSS 5.4, Середній): Інʼєкція regex у `serviceAccounts` `AuthorizationPolicy` через неекрановані крапки.
  Повідомив [Wernerina](https://github.com/Wernerina).

- __[CVE-2026-41413](https://nvd.nist.gov/vuln/detail/CVE-2026-41413)__ / __[GHSA-fgw5-hp8f-xfhc](https://github.com/istio/istio/security/advisories/GHSA-fgw5-hp8f-xfhc)__: (оцінка CVSS 5.0, Середній): SSRF через `jwksUri` `RequestAuthentication`.
  Повідомив [KoreaSecurity](https://github.com/KoreaSecurity), [1seal](https://github.com/1seal), [AKiileX](https://github.com/AKiileX).

## Чи це впливає на мене? {#am-i-impacted}

Всі користувачі, що запускають зачеплені версії Istio, потенційно зазнають впливу:

- Вплив **Оминання авторизації** актуальний, якщо ви використовуєте ресурси `AuthorizationPolicy`, що вказують `serviceAccounts`, що містять крапки. Атакуючий міг оминути політику `ALLOW` або проскочити крізь політику `DENY`, використовуючи службовий обліковий запис з іменем, що використовує інтерпретацію regex wildcard.

- Вплив **SSRF** актуальний, якщо ви дозволяєте користувачам або автоматизованим системам створювати ресурси `RequestAuthentication`. Атакуючий міг надати `jwksUri`, що вказує на внутрішні метадані сервіси або локальні порти, потенційно передаючи чутливі внутрішні дані до панелі управління через xDS конфігурацію.

## Застереження {#mitigation}

- Для користувачів Istio 1.29: Оновіться до **1.29.2** або пізнішої.
- Для користувачів Istio 1.28: Оновіться до **1.28.6** або пізнішої.

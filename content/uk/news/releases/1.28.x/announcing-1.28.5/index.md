---
title: Анонс Istio 1.28.5
linktitle: 1.28.5
subtitle: Патч-реліз
description: Патч-реліз Istio 1.28.5.
publishdate: 2026-03-10
release: 1.28.5
aliases:
    - /news/announcing-1.28.5
---

Цей реліз містить виправлення безпеки. Ця примітка до релізу описує, що змінилося між Istio 1.28.4 та 1.28.5.

{{< relnote >}}

## Оновлення безпеки {#security-update}

Для отримання додаткової інформації див. [ISTIO-SECURITY-2026-001](/news/security/istio-security-2026-001).

### Envoy CVEs {#envoy-cves}

- [CVE-2026-26308](https://nvd.nist.gov/vuln/detail/CVE-2026-26308) (CVSS score 7.5, High): Fix multivalue header bypass in RBAC.
- [CVE-2026-26311](https://nvd.nist.gov/vuln/detail/CVE-2026-26311) (CVSS score 5.9, Medium): HTTP decode methods blocked after downstream reset.
- [CVE-2026-26310](https://nvd.nist.gov/vuln/detail/CVE-2026-26310) (CVSS score 5.9, Medium): Fix crash in `getAddressWithPort()` with scoped IPv6 address.
- [CVE-2026-26309](https://nvd.nist.gov/vuln/detail/CVE-2026-26309) (CVSS score 5.3, Medium): JSON off-by-one write fix.
- [CVE-2026-26330](https://nvd.nist.gov/vuln/detail/CVE-2026-26330) (CVSS score 5.3, Medium): Ratelimit response phase fix.

### Istio CVEs {#istio-cves}

- **[CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838)** / **[GHSA-974c-2wxh-g4ww](https://github.com/istio/istio/security/advisories/GHSA-974c-2wxh-g4ww)**: (CVSS score 6.9, Medium): Debug Endpoints Allow Cross-Namespace Proxy Data Access.
  Повідомив [1seal](https://github.com/1seal).
- **[CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837)** / **[GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c)**: (CVSS score 8.7, High): JWKS Resolver Failure May Allow Authentication Bypass Using Known Default Keys.
  Повідомив [1seal](https://github.com/1seal).

### Виправлення безпеки Istio {#istio-security-fixes}

- **Виправлено**: для точок доступу налагодження XDS на порту 15010 у відкритому тексті тепер потрібна автентифікація, що запобігає неавтентифікованому доступу до конфігурації проксі.
  Повідомлено [1seal](https://github.com/1seal).
- **Виправлено** потенційну уразливість SSRF під час завантаження образів `WasmPlugin` шляхом перевірки URL-адрес сфери дії токенів на предʼявника.
  Повідомив [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Виправлено**: для точок доступу налагодження HTTP на порту 15014 запроваджено авторизацію на основі просторів імен, що запобігає міжпросторовому доступу до даних проксі.
  Повідомлено [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Додано** можливість вказувати авторизовані простори імен для точок доступу для налагодження, коли `ENABLE_DEBUG_ENDPOINT_AUTH=true`. Увімкніть цю функцію, встановивши для `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` список авторизованих просторів імен, розділених комами. Системний простір імен (зазвичай `istio-system`) завжди авторизований.

## Зміни {#changes}

- **Виправлено** проблему, через яку конфігурації `InferencePool` втрачалися під час об’єднання `VirtualService`, коли до одного й того самого шлюзу було підключено кілька `HTTPRoutes`, що посилалися на різні `InferencePools`.
  ([Тікет #58392](https://github.com/istio/istio/issues/58392))

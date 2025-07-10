---
title: Анонс Istio 1.24.6
linktitle: 1.24.6
subtitle: Патч-реліз
description: Патч-реліз Istio 1.24.6.
publishdate: 2025-05-13
release: 1.24.6
---


Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.24.5 та Istio 1.24.6.

{{< relnote >}}

## Оновлення безпеки {#security-updates}

- [CVE-2025-46821](https://nvd.nist.gov/vuln/detail/CVE-2025-46821) (CVSS Score 5.3, Medium): Обхід дозволу `uri_template` RBAC.

Якщо ви використовуєте `**` у полі шляху `AuthorizationPolicy`, рекомендується оновити до Istio 1.24.6.

## Зміни {#changes}

- **Виправлено** проблему, коли валідаційний веб-хук неправильно повідомляв про попередження, коли `ServiceEntry` налаштовував `workloadSelector` з DNS-розвʼязанням.
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **Видалено** обмеження, при якому теґ версії працював лише тоді, коли `istiodRemote` не був увімкнений у чарті helm istiod. Теґи версії тепер працюють, якщо вказано `revisionTags`, незалежно від того, чи увімкнено `istiodRemote`, чи ні.
  ([Issue #54743](https://github.com/istio/istio/issues/54743))

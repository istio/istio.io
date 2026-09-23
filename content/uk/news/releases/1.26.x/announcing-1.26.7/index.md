---
title: Анонс Istio 1.26.7
linktitle: 1.26.7
subtitle: Патч-реліз
description: Патч-реліз Istio 1.26.7.
publishdate: 2025-12-03
release: 1.26.7
aliases:
    - /news/announcing-1.26.7
---

Цей реліз містить виправлення помилок для покращення надійності. Ця примітка до релізу описує, що змінилося між Istio 1.26.6 та Istio 1.26.7.

Цей реліз впроваджує оновлення безпеки, описані в нашому пості від 3 грудня, [`ISTIO-SECURITY-2025-001`](/news/security/istio-security-2025-003).

{{< relnote >}}

## Зміни {#changes}

- **Виправлено** витік goroutine в мультикластері, через який колекції krt з даними з віддалених кластерів залишалися в пам’яті навіть після видалення цього кластера. ([Тікет #57269](https://github.com/istio/istio/issues/57269))

- **Виправлено** проблему, через яку ресурси Envoy Secret могли застрягати у стані `WARMING`, коли на один і той самий секрет Kubernetes посилалися об’єкти Istio Gateway, використовуючи як формат `secret-name`, так і формат `namespace/secret-name`. ([Тікет #58146](https://github.com/istio/istio/issues/58146))

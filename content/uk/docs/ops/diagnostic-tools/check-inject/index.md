---
title: Перевірка інʼєкції Sidecar Istio за допомогою Istioctl Check-Inject
description: Дізнайтеся, як використовувати istioctl check-inject, щоб перевірити, чи належним чином увімкнено інʼєкцію sidecar Istio у ваших розгортаннях.
weight: 45
keywords: [istioctl, injection, kubernetes]
owner: istio/wg-user-experience-maintainers
test: no
---

`istioctl experimental check-inject` — це діагностичний інструмент, який допомагає перевірити, чи конкретні вебхуки будуть виконувати інʼєкцію sidecar Istio у ваших podʼах. Використовуйте цей інструмент, щоб перевірити, чи конфігурація інʼєкції sidecar правильно застосована до живого кластера.

## Швидкий старт {#quick-start}

Щоб перевірити, чому інʼєкція sidecar Istio відбулася/не відбулася (або відбудеться/не відбудеться) для конкретного podʼа, запустіть:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> <pod-name>
{{< /text >}}

Для deployment, запустіть:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> deploy/<deployment-name>
{{< /text >}}

Або для пар міток:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n <namespace> -l <label-key>=<label-value>
{{< /text >}}

Наприклад, якщо у вас є deployment з назвою `httpbin` в просторі імен `hello` та pod з назвою `httpbin-1234` з міткою `app=httpbin`, наступні команди еквівалентні:

{{< text syntax=bash >}}
$ istioctl experimental check-inject -n hello httpbin-1234
$ istioctl experimental check-inject -n hello deploy/httpbin
$ istioctl experimental check-inject -n hello -l app=httpbin
{{< /text >}}

Приклад результатів:

{{< text plain >}}
WEBHOOK                      REVISION  INJECTED      REASON
istio-revision-tag-default   default   ✔             Namespace label istio-injection=enabled matches
istio-sidecar-injector-1-18  1-18      ✘             No matching namespace labels (istio.io/rev=1-18) or pod labels (istio.io/rev=1-18)
{{< /text >}}

Якщо поле `INJECTED` відмічено як `✔`, вебхук в цьому рядку виконає інʼєкцію, з вказанням причини, чому вебхук виконає інʼєкцію sidecar.

Якщо поле `INJECTED` відмічено як `✘`, вебхук в цьому рядку не виконає інʼєкцію, і також буде вказана причину.

Можливі причини, чому вебхук не виконає інʼєкцію або інʼєкція матиме помилки:

1. **Відсутність відповідних міток простору імен або podʼів**: Переконайтеся, що правильні мітки встановлені на просторі імен або podʼі.

2. **Відсутність відповідних міток простору імен або podʼів для конкретної версії**: Встановіть правильні мітки, щоб відповідати бажаній версії Istio.

3. **Мітка поду, що перешкоджає інʼєкції**: Видаліть мітку або встановіть її на відповідне значення.

4. **Мітка простору імен, що перешкоджає інʼєкції**: Змініть мітку на відповідне значення.

5. **Кілька вебхуків, що виконують інʼєкцію sidecar**: Переконайтеся, що лише один вебхук увімкнено для інʼєкції або встановіть відповідні мітки на простір імен або pod, щоб націлити конкретний вебхук.

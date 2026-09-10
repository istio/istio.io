---
title: "Останні новини щодо міграції нашого реєстру контейнерів"
description: Що ви можете зробити сьогодні, щоб ваші кластери не постраждали від виведення з експлуатації `gcr.io/istio-release` та `registry.istio.io`.
publishdate: 2026-07-23
attribution: Steven Jin (Microsoft)
keywords: [Istio,Container Registry]
---

В [попередньому дописі в блозі](/blog/2026/retirement-of-gcr.io/), ми оголосили, що Istio виведе з експлуатації реєстр контейнерів `gcr.io/istio-release` наприкінці 2026 року та перейде на `registry.istio.io/release` як новий дім для образів Istio. Первісний дизайн передбачав, що `registry.istio.io/release` буде Cloudflare worker, який проксуватиме запити до будь-якого реєстру, сумісного з OCI, що дозволяє нам змінювати реєстри без будь-яких перебоїв для користувачів Istio. Наразі ми проксуємо до `gcr.io/istio-release`.

Як зазначалося раніше, ми виводимо з експлуатації `gcr.io/istio-release` наприкінці 2026 року. З обмеженим бюджетом на інфраструктуру на 2027 рік, ми плануємо використовувати безкоштовні платформи для розміщення контейнерів для хостингу образів Istio. На жаль, проксування через Cloudflare означає, що весь трафік проходить через кілька вихідних IP-адрес, що активує політики обмеження швидкості на безкоштовних платформах для хостингу контейнерів.

Після обговорень з платформами для хостингу щодо цього обмеження, ми прийняли складне рішення вивести з експлуатації `registry.istio.io/release`. Ми продовжимо хостинг `registry.istio.io/release` до кінця 2026 року. Як завжди, ми будемо публікувати образи Istio на `docker.io/istio` і плануємо публікувати на дзеркалах у майбутньому.

## Чи це впливає на мене? {#am-i-affected}

Типово, встановлення Istio 1.30 використовує `registry.istio.io/release` як реєстр контейнерів. Усі інші версії Istio типово використовують `docker.io/istio`. Ви можете перевірити, чи це впливає на вас, за допомогою наступної команди:

{{< text bash >}}
$ kubectl get pods --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.containers[].image | startswith("registry.istio.io/release")) | "\(.metadata.namespace)/\(.metadata.name)"'
{{< /text >}}

Вищенаведена команда покаже усі поди, які використовують образи, розміщені на `registry.istio.io/release`. Якщо такі поди є, вам, ймовірно, доведеться робити міграцію.

Зверніть увагу, що ми все ще виводимо з експлуатації `gcr.io/istio-release` наприкінці 2026 року, як зазначалося в попередньому дописі, тому вам слід перевірити використання `gcr.io/istio-release` також.

## Що робити сьогодні {#what-to-do-today}

Хоча ми плануємо зберігати образи на `registry.istio.io/release` та `gcr.io/istio-release` до кінця 2026 року, ми радимо вам мігрувати на `docker.io/istio` якомога швидше. Ще краще — налаштувати кеш із проксуванням для забезпечення максимальної доступності.

### Використання `istioctl` {#using-istioctl}

Якщо ви встановлюєте Istio за допомогою `istioctl`, ви можете оновити конфігурацію `IstioOperator` наступним чином:

{{< text yaml >}}

# istiooperator.yaml

apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:

#

  hub: docker.io/istio  # or your pull-through cache

# Все інше може залишатися без змін, якщо ви не посилаєтеся на образи `gcr.io/istio-release` в інших місцях

{{< /text >}}

І встановіть Istio, використовуючи цю конфігурацію:

{{< text bash >}}
$ istioctl install -f istiooperator.yaml
{{< /text >}}

Або ви можете передати реєстр як аргумент командного рядка

{{< text bash >}}
$ istioctl install --set hub=docker.io/istio # or your pull-through cache
{{< /text >}}

### Використання Helm {#using-helm}

Якщо ви встановлюєте Istio за допомогою Helm, оновіть свій файл значень наступним чином:

{{< text yaml >}}

#

hub: docker.io/istio  # or your pull-through cache
global:
  hub: docker.io/istio  # or your pull-through cache

# Все інше може залишатися без змін, якщо ви не посилаєтеся на образи `gcr.io/istio-release` в інших місцях

{{< /text >}}

Потім оновіть свою установку Helm за допомогою нового файлу значень.

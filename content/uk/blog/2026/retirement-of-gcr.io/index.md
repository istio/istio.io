---
title: "Istio здійснює міграцію реєстрів контейнерів"
description: Що ви можете зробити сьогодні, щоб ваші кластери не постраждали від виведення з експлуатації `gcr.io/istio-release`.
publishdate: 2026-03-23
attribution: Steven Jin (Microsoft), John Howard (Solo.io)
keywords: [Istio,Helm,Container Registry]
---

{{< warning >}}
Інформацію в цьому дописі оновлено. Див. [Оновлення щодо міграції нашого реєстру контейнерів](../retirement-of-gcr.io-follow-up/) для отримання останніх рекомендацій.
{{< /warning >}}

Через зміни в моделі фінансування Istio образи Istio більше не будуть доступні на `gcr.io/istio-release` починаючи з 1 січня 2027 року. Тобто кластери, які посилаються на образи, розміщені на `gcr.io/istio-release`, можуть не змогти створювати нові поди в 2027 році.

Насправді ми повністю мігруємо всі артефакти Istio з Google Cloud, включно з Helm-чартами. Подальші повідомлення охоплюватимуть міграцію Helm-чартів та інших артефактів. Цей допис зосереджено на тому, що ви можете зробити сьогодні у відповідь на міграцію реєстру контейнерів у 2027 році.

## Чи це впливає на мене? {#am-i-affected}

Типово, встановлення Istio використовують Docker Hub (`docker.io/istio`) як реєстр контейнерів, але багато користувачів обирають використання дзеркала `gcr.io/istio-release`. Ви можете перевірити, чи використовуєте ви дзеркало, за допомогою наступної команди.

{{< text bash >}}
$ kubectl get pods --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.containers[].image | startswith("gcr.io/istio-release")) | "\(.metadata.namespace)/\(.metadata.name)"'
{{< /text >}}

Вищенаведена команда покаже усі поди, які використовують образи, розміщені на `gcr.io/istio-release`. Якщо такі поди є, вам, ймовірно, доведеться робити міграцію.

{{< tip >}}
Навіть якщо ви використовуєте Docker Hub як свій реєстр, ми радимо вам мігрувати на `registry.istio.io` на випадок, якщо образи Istio більше не будуть доступні на Docker Hub у майбутньому.
Див. нижче для отримання додаткової інформації.
{{< /tip >}}

## Що робити сьогодні {#what-to-do-today}

Хоча ми плануємо зберігати образи на `gcr.io/istio-release` до кінця 2026 року, ми створили `registry.istio.io` як новий дім для образів Istio. Будь ласка, мігруйте на використання `registry.istio.io` якомога швидше.

### Використання `istioctl` {#using-istioctl}

Якщо ви встановлюєте Istio за допомогою `istioctl`, ви можете оновити свою конфігурацію `IstioOperator` таким чином:

{{< text yaml >}}

# istiooperator.yaml

apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:

#

  hub: registry.istio.io/release

# Все інше може залишатися без змін, якщо ви не посилаєтеся на образи `gcr.io/istio-release` в інших місцях

{{< /text >}}

і встановіть Istio за допомогою цієї конфігурації

{{< text bash >}}
$ istioctl install -f istiooperator.yaml
{{< /text >}}

Альтернативно, ви можете передати реєстр як аргумент командного рядка

{{< text bash >}}
$ istioctl install --set hub=registry.istio.io/release # the rest of your arguments
{{< /text >}}

### Використання Helm {#using-helm}

Якщо ви встановлюєте Istio за допомогою Helm, оновіть свій файл значень таким чином:

{{< text yaml >}}

#

hub: registry.istio.io/release
global:
  hub: registry.istio.io/release

# Все інше може залишатися без змін, якщо ви не посилаєтеся на образи `gcr.io/istio-release` в інших місцях

{{< /text >}}

Потім оновіть свою установку Helm за допомогою нового файлу значень.

### Приватні дзеркала {#private-mirrors}

Ваша організація може витягувати образи з `gcr.io/istio-release`, завантажувати їх у приватний реєстр і посилатися на приватний реєстр у вашій установці Istio. Цей процес все ще працюватиме, але вам доведеться витягувати образи з `registry.istio.io/release` замість `gcr.io/istio-release`.

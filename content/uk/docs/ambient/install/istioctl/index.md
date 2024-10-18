---
title: Встановлення за допомогою istioctl
description: Встановіть Istio з підтримкою режиму оточення за допомогою інструмента командного рядка istioctl.
weight: 10
keywords: [istioctl,ambient]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
Керуйтесь цим посібником для встановлення та налаштування Istio mesh з підтримкою ambient режиму. Якщо ви новачок в Istio і просто хочете спробувати його, дотримуйтесь [інструкцій для швидкого старту](/docs/ambient/getting-started) замість цього.
{{< /tip >}}

Цей посібник з установки використовує інструмент командного рядка [istioctl](/docs/reference/commands/istioctl/). `istioctl`, як і інші методи встановлення, надає багато можливостей для налаштування. Крім того, він пропонує перевірку введення користувачем для запобігання помилок під час установки та містить багато інструментів для аналізу та налаштування після установки.

Використовуючи ці інструкції, ви можете вибрати будь-який з вбудованих
[профілів конфігурації](/docs/setup/additional-setup/config-profiles/)
та додатково налаштувати конфігурацію відповідно до ваших потреб.

Команда `istioctl` підтримує повний API [`IstioOperator`](/docs/reference/config/istio.operator.v1alpha1/) за допомогою опцій інструменту командного рядка для окремих налаштувань або передачі YAML-файлу, що містить ресурс `IstioOperator` {{<gloss CRD>}}custom resource{{</gloss>}}.

## Попередні вимоги {#prerequisites}

Перед початком, перевірте наступні вимоги:

1. [Завантажте реліз Istio](/docs/setup/additional-setup/download-istio-release/).
1. Виконайте будь-які необхідні [платформо-специфічні налаштування](/docs/ambient/install/platform-prerequisites/).

## Встановлення або оновлення CRD API шлюзу Kubernetes {#install-or-upgrade-the-kubernetes-gateway-api-crds}

{{< boilerplate gateway-api-install-crds >}}

## Встановлення Istio з використанням профілю ambient {#install-istio-using-the-ambient-profile}

`istioctl` підтримує кілька [профілів конфігурації](/docs/setup/additional-setup/config-profiles/), які включають різні стандартні параметри, та можуть бути налаштовані відповідно до ваших операційних потреб. Підтримка ambient режиму включена в профіль `ambient`. Встановіть Istio за допомогою наступної команди:

{{< text syntax=bash snip_id=install_ambient >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

Ця команда встановлює профіль `ambient` в кластер, визначений у вашій
конфігурації Kubernetes.

## Налаштування та зміна профілів {#configure-and-modify-profiles}

API установки Istio задокументований у довіднику [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/). Ви можете використовувати опцію `--set` для `istioctl install` для зміни окремих параметрів установки або вказати свій власний конфігураційний файл за допомогою `-f`.

Повні відомості про використання та налаштування установок `istioctl` доступні в [документації з встановлення Sidecar](/docs/setup/install/istioctl/).

## Видалення Istio {#uninstall-istio}

Щоб повністю видалити Istio з кластера, виконайте наступну команду:

{{< text syntax=bash snip_id=uninstall >}}
$ istioctl uninstall --purge -y
{{< /text >}}

{{< warning >}}
Опціональний прапорець `--purge` видалить всі ресурси Istio, включаючи ресурси кластерного рівня, які можуть бути спільними з іншими панелями управління Istio.
{{< /warning >}}

Альтернативно, щоб видалити лише конкретну панель управління Istio, виконайте наступну команду:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall <ваші оригінальні параметри установки>
{{< /text >}}

Простір імен панелі управління (наприклад, `istio-system`) стандартно не видаляється. Якщо він більше не потрібен, використовуйте наступну команду для його видалення:

{{< text syntax=bash snip_id=remove_namespace >}}
$ kubectl delete namespace istio-system
{{< /text >}}

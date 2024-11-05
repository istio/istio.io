---
title: Як розпочати
description: Як розгорнути та встановити Istio в режимі оточення.
weight: 2
aliases:
  - /uk/docs/ops/ambient/getting-started
  - /uk/latest/docs/ops/ambient/getting-started
owner: istio/wg-networking-maintainers
skip_list: true
test: yes
---

Цей посібник дозволяє швидко оцінити режим {{< gloss "ambient" >}}ambient{{< /gloss >}} в Istio. Для продовження вам знадобиться кластер Kubernetes. Якщо у вас немає кластера, ви можете використовувати [kind](/docs/setup/platform-setup/kind) або будь-яку іншу [підтримувану платформу Kubernetes](/docs/setup/platform-setup).

Ці кроки вимагають наявності {{< gloss "кластер" >}}кластера{{< /gloss >}}, який працює на [підтримуваній версії](/docs/releases/supported-releases#support-status-of-istio-releases) Kubernetes ({{< supported_kubernetes_versions >}}).

## Завантаження Istio CLI {#download-the-istio-cli}

Istio сконфігуровано за допомогою інструмента командного рядка `istioctl`. Завантажте його та демонстраційні застосунки Istio:

{{< text syntax=bash snip_id=none >}}
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-{{< istio_full_version >}}
$ export PATH=$PWD/bin:$PATH
{{< /text >}}

Перевірте, чи можете ви запустити `istioctl`, спробувавши вивести версію команди. На цьому етапі Istio ще не встановлено у вашому кластері, тому ви побачите, що жоден з podʼів не готовий.

{{< text syntax=bash snip_id=none >}}
$ istioctl version
no ready Istio pods in "istio-system"
{{< istio_full_version >}}
{{< /text >}}

## Встановлення Istio у ваш кластер {#install-istio-on-to-your-cluster}

`istioctl` підтримує кілька [профілів конфігурації](/docs/setup/additional-setup/config-profiles/), які включають різні стандартні параметри та можуть бути налаштовані відповідно до ваших операційних потреб. Підтримка режиму оточення включена в профіль `ambient`. Встановіть Istio за допомогою наступної команди:

{{< text syntax=bash snip_id=install_ambient >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

Може знадобитися кілька хвилин, щоб компоненти Istio були встановлені. Як тільки установка буде завершена, ви отримаєте наступний результат, який вказує на те, що всі компоненти були успішно встановлені.

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

{{< tip >}}
Ви можете перевірити встановлені компоненти за допомогою команди `istioctl verify-install`.
{{< /tip >}}

## Встановлення CRD для Kubernetes Gateway API {#install-the-kubernetes-gateway-api-crds}

{{< boilerplate gateway-api-install-crds >}}

Ви використовуватимете Kubernetes Gateway API для налаштування маршрутизації трафіку.

## Подальші кроки {#next-steps}

Вітаємо! Ви успішно встановили Istio з підтримкою режиму оточення. Перейдіть до наступного кроку, щоб [встановити демонстраційний застосунок і додати його до сервісної мережі в режимі оточення](/docs/ambient/getting-started/deploy-sample-app/).

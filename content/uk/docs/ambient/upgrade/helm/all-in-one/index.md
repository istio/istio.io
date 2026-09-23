---
title: Оновлення за допомогою Helm (просте)
description: Оновлення інсталяції в режимі ambient за допомогою Helm з використанням одного чарту
weight: 5
owner: istio/wg-environments-maintainers
test: yes
draft: true
---

Слідуйте цьому керівництву, щоб оновити та налаштувати інсталяцію в режимі ambient за допомогою [Helm](https://helm.sh/docs/). Це керівництво передбачає, що ви вже виконали [встановлення в режимі ambient за допомогою Helm та чарту обгортки ambient](/docs/ambient/install/helm/all-in-one) з попередньою версією Istio.

{{< warning >}}
Зверніть увагу, що ці інструкції з оновлення застосовуються лише у випадку, якщо ви оновлюєте інсталяцію Helm, створену за допомогою чарту обгортки ambient. Якщо ви встановили за допомогою окремих компонентних чартів Helm, дивіться [відповідні документи з оновлення](docs/ambient/upgrade/helm)
{{< /warning >}}

## Розуміння оновлень в режимі ambient {#understanding-ambient-mode-upgrades}

{{< warning >}}
Зверніть увагу, що якщо ви встановлюєте все як частину цього чарту обгортки, ви можете лише оновити або видалити ambient за допомогою цього чарту обгортки; ви не можете оновити або видалити компоненти окремо.
{{< /warning >}}

## Передумови {#prerequisites}

### Підготовка до оновлення {#prepare-for-the-upgrade}

Перед оновленням Istio ми рекомендуємо завантажити нову версію istioctl та запустити `istioctl x precheck`, щоб переконатися, що оновлення сумісне з вашим середовищем. Вивід повинен виглядати приблизно так:

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

Тепер оновіть репозиторій Helm:

{{< text syntax=bash snip_id=update_helm >}}
$ helm repo update istio
{{< /text >}}

### Оновлення панелі управління та панелі даних Istio в режимі ambient {#upgrade-the-istio-ambient-control-plane-and-data-plane}

{{< warning >}}
Оновлення за допомогою чарту обгортки на місці короткочасно порушить весь трафік в ambient mesh на вузлі, **навіть з використанням ревізій**. На практиці період порушення є дуже коротким вікном, що в основному впливає на довготривалі зʼєднання.

Рекомендується використовувати кордонування вузлів та синьо-зелені пули вузлів для зменшення ризику під час оновлень у промисловому середовищі. Дивіться документацію вашого постачальника Kubernetes для деталей.
{{< /warning >}}

Чарт `ambient` оновлює всі компоненти панелі даних та панелі управління Istio, необхідні для ambient, використовуючи чарт обгортку Helm, який складається з окремих чартів компонентів.

Якщо ви налаштували свою інсталяцію istiod, ви можете повторно використовувати файл `values.yaml` з попередніх оновлень або інсталяцій, щоб зберегти налаштування.

{{< text syntax=bash snip_id=upgrade_ambient_aio >}}
$ helm upgrade istio-ambient istio/ambient -n istio-system --wait
{{< /text >}}

### Оновлення вручну розгорнутого чарту шлюзу (опціонально) {#upgrade-manually-deployed-gateway-chart}

`Gateway`, які були [розгорнуті вручну](/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment), повинні бути оновлені окремо за допомогою Helm:

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

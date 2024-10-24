---
title: Завантаження випуску Istio
description: Отримайте файли, необхідні для встановлення та вивчення Istio.
weight: 30
keywords: [profiles,install,release,istioctl]
owner: istio/wg-environments-maintainers
test: n/a
---

Кожен реліз Istio містить _архів релізу_, який містить:

- бінарний файл [`istioctl`](/docs/ops/diagnostic-tools/istioctl/)
- [профілі установки](/docs/setup/additional-setup/config-profiles/) та [Helm чарти](/docs/setup/install/helm)
- приклади, включаючи застосунок [Bookinfo](/docs/examples/bookinfo/)

Архів релізу створюється для кожної підтримуваної архітектури процесора та операційної системи.

## Завантаження Istio {#download}

1. Перейдіть на сторінку [релізів Istio]({{< istio_release_url >}}), щоб завантажити файл установки для вашої ОС, або завантажте та розпакуйте останній реліз автоматично (Linux або macOS):

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

    {{< tip >}}
    Команда вище завантажує останній реліз (числовий) Istio. Ви можете передати змінні в командному рядку, щоб завантажити конкретну версію або щоб перевизначити архітектуру процесора. Наприклад, щоб завантажити Istio {{< istio_full_version >}} для архітектури x86_64, виконайте:

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_full_version >}} TARGET_ARCH=x86_64 sh -
    {{< /text >}}

    {{< /tip >}}

2. Перейдіть до теки пакету Istio. Наприклад, якщо пакет має назву `istio-{{< istio_full_version >}}`:

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    Тека установки містить:

    - Демонстраційні застосунки в `samples/`
    - Бінарний файл клієнта [`istioctl`](/docs/reference/commands/istioctl) у теці `bin/`.

3. Додайте клієнта `istioctl` до вашого шляху (Linux або macOS):

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

---
title: Налаштування локального компʼютера
overview: Налаштуйте свій локальний компʼютер для навчання.
weight: 3
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

У цьому модулі ви підготуєте свій локальний компʼютер для навчання.

1. Встановіть [`curl`](https://curl.haxx.se/download.html).

2. Встановіть [Node.js](https://nodejs.org/en/download/).

3. Встановіть [Docker](https://docs.docker.com/install/).

4. Встановіть [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

5. Встановіть змінну середовища `KUBECONFIG` для файлу конфігурації, який ви отримали від інструкторів або створили самостійно в попередньому модулі.

    {{< text bash >}}
    $ export KUBECONFIG=<файл, який ви отримали або створили в попередньому модулі>
    {{< /text >}}

6. Перевірте, що конфігурація була застосована, вивівши поточний простір імен:

    {{< text bash >}}
    $ kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
    tutorial
    {{< /text >}}

    Ви повинні побачити у виводі імʼя простору імен, виділеного для вас інструкторами або виділеного вами самостійно в попередньому модулі.

7. Завантажте один з [архівів релізів Istio](https://github.com/istio/istio/releases) і витягніть інструмент командного рядка `istioctl` з теки `bin`, і перевірте, чи можете ви виконати `istioctl` за допомогою наступної команди:

    {{< text bash >}}
    $ istioctl version
    client version: 1.22.0
    control plane version: 1.22.0
    data plane version: 1.22.0 (4 proxies)
    {{< /text >}}

Вітаємо, ви налаштували свій локальний компʼютер!

Ви готові [запустити один сервіс локально](/docs/examples/microservices-istio/single/).

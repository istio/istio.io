---
title: Встановлення за допомогою Helm
linktitle: Встановлення за допомогою Helm
description: Інструкція по встановленню та налаштуванню Istio в кластері Kubernetes за допомогою Helm.
weight: 30
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
test: yes
---

Дотримуйтесь цього посібника, щоб встановити та налаштувати сервісну мережу Istio за допомогою [Helm](https://helm.sh/docs/).

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-prereqs >}}

## Кроки встановлення {#installation-steps}

Цей розділ описує процедуру встановлення Istio за допомогою Helm. Загальний синтаксис для встановлення за допомогою Helm:

{{< text syntax=bash snip_id=none >}}
$ helm install <release> <chart> --namespace <namespace> --create-namespace [--set <other_parameters>]
{{< /text >}}

Змінні, що вказані в команді, мають наступні значення:

* `<chart>` — Шлях до упакованого чарту, шлях до теки розпакованого чарту або URL.
* `<release>` — Імʼя для ідентифікації та управління Helm-чартом після встановлення.
* `<namespace>` — Простір імен, в якому буде встановлено чарт.

Стандартне значення конфігурації можна змінити, використовуючи один або кілька параметрів `--set <parameter>=<value>`. Альтернативно, ви можете вказати кілька параметрів у власному файлі значень, використовуючи аргумент `--values <file>`.

{{< tip >}}
Ви можете показати стандатні значення конфігураційних параметрів, використовуючи команду `helm show values <chart>`, або звернутися до документації чарту на `artifacthub` за посиланнями [Custom Resource Definition parameters](https://artifacthub.io/packages/helm/istio-official/base?modal=values), [Istiod chart configuration parameters](https://artifacthub.io/packages/helm/istio-official/istiod?modal=values) та [Gateway chart configuration parameters](https://artifacthub.io/packages/helm/istio-official/gateway?modal=values).
{{< /tip >}}

1. Встановіть базовий чарт Istio, який містить кластерні Custom Resource Definitions (CRDs), які повинні бути встановлені перед розгортанням панелі управління Istio:

    {{< warning >}}
    При виконанні встановлення з ревізією базовий чарт вимагає вказання значення `--set defaultRevision=<revision>` для функціонування перевірки ресурсів. Нижче ми встановлюємо ревізію `default`, тому вказуємо `--set defaultRevision=default`.
    {{< /warning >}}

    {{< text syntax=bash snip_id=install_base >}}
    $ helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace
    {{< /text >}}

1. Перевірте установку CRD за допомогою команди `helm ls`:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED                                 STATUS   CHART        APP VERSION
    istio-base istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed base-{{< istio_full_version >}}  {{< istio_full_version >}}
    {{< /text >}}

    У виводі знайдіть запис для `istio-base` і переконайтесь, що статус встановлений на `deployed`.

1. Якщо ви плануєте використовувати чарт Istio CNI, зробіть це зараз. Див. [Встановлення Istio за допомогою втулка CNI](/docs/setup/additional-setup/cni/#installing-with-helm) для отримання додаткової інформації.

1. Встановіть чарт виявлення Istio, який розгортає сервіс `istiod`:

    {{< text syntax=bash snip_id=install_discovery >}}
    $ helm install istiod istio/istiod -n istio-system --wait
    {{< /text >}}

1. Перевірте установку чарту виявлення Istio:

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED                                 STATUS   CHART         APP VERSION
    istio-base istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed base-{{< istio_full_version >}}   {{< istio_full_version >}}
    istiod     istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed istiod-{{< istio_full_version >}} {{< istio_full_version >}}
    {{< /text >}}

1. Отримайте статус встановленого Helm-чарту, щоб переконатися, що він розгорнутий:

    {{< text syntax=bash >}}
    $ helm status istiod -n istio-system
    NAME: istiod
    LAST DEPLOYED: Fri Jan 20 22:00:44 2023
    NAMESPACE: istio-system
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    "istiod" successfully installed!

    To learn more about the release, try:
      $ helm status istiod
      $ helm get all istiod

    Next steps:
      * Deploy a Gateway: https://istio.io/latest/docs/setup/additional-setup/gateway/
      * Try out our tasks to get started on common configurations:
        * https://istio.io/latest/docs/tasks/traffic-management
        * https://istio.io/latest/docs/tasks/security/
        * https://istio.io/latest/docs/tasks/policy-enforcement/
        * https://istio.io/latest/docs/tasks/policy-enforcement/
      * Review the list of actively supported releases, CVE publications and our hardening guide:
        * https://istio.io/latest/docs/releases/supported-releases/
        * https://istio.io/latest/news/security/
        * https://istio.io/latest/docs/ops/best-practices/security/

    For further documentation see https://istio.io website

    Tell us how your install/upgrade experience went at https://forms.gle/99uiMML96AmsXY5d6
    {{< /text >}}

1. Перевірте, чи успішно встановлено сервіс `istiod` та чи працюють його podʼи:

    {{< text syntax=bash >}}
    $ kubectl get deployments -n istio-system --output wide
    NAME     READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                         SELECTOR
    istiod   1/1     1            1           10m   discovery    docker.io/istio/pilot:{{< istio_full_version >}}   istio=pilot
    {{< /text >}}

1. (Додатково) Встановіть ingress gateway:

    {{< text syntax=bash snip_id=install_ingressgateway >}}
    $ kubectl create namespace istio-ingress
    $ helm install istio-ingress istio/gateway -n istio-ingress --wait
    {{< /text >}}

    Див. [Встановлення Gateway](/docs/setup/additional-setup/gateway/) для отримання детальної документації з встановлення Gateway.

    {{< warning >}}
    Простір імен, у якому розгортаються Gateway, не повинен мати мітку `istio-injection=disabled`. Див. [Контроль політики інʼєкцій](/docs/setup/additional-setup/sidecar-injection/#controlling-the-injection-policy) для отримання додаткової інформації.
    {{< /warning >}}

{{< tip >}}
Див. [Розширені налаштування чартів Helm](/docs/setup/additional-setup/customize-installation-helm/) для отримання детальної документації про те, як використовувати Helm post-renderer для налаштування Helm-чартів.
{{< /tip >}}

## Оновлення конфігурації Istio {#updating-your-istio-configuration}

Ви можете вказати параметри перевизначення для будь-кого з чартів Istio Helm, використаних вище, і слідувати робочому процесу оновлення Helm, щоб налаштувати встановлення вашої меш-мережі Istio. Доступні параметри конфігурації можна знайти за допомогою команди `helm show values istio/<chart>`; наприклад, `helm show values istio/gateway`.

### Міграція з установок без Helm {#migrating-from-non-helm-installations}

Якщо ви переходите з версії Istio, встановленої за допомогою `istioctl`, на Helm (Istio 1.5 або раніше), вам потрібно видалити ваші поточні ресурси панелі управління Istio та перевстановити Istio за допомогою Helm, як описано вище. При видаленні поточної установки Istio не слід видаляти Custom Resource Definitions (CRDs) Istio, оскільки це може призвести до втрати ваших власних ресурсів Istio.

{{< warning >}}
Рекомендується зробити резервну копію ваших ресурсів Istio за допомогою наведених вище кроків перед видаленням поточної установки Istio у вашому кластері.
{{< /warning >}}

Ви можете слідувати крокам, наведеним у [посібнику з видалення Istioctl](/docs/setup/install/istioctl#uninstall-istio).

### Видалення {#uninstall}

Ви можете видалити Istio та її компоненти, видаливши встановлені раніше чарти.

1. Перевірте всі встановлені чарти Istio в просторі імен `istio-system`:

    {{< text syntax=bash snip_id=helm_ls >}}
    $ helm ls -n istio-system
    NAME       NAMESPACE    REVISION UPDATED                                 STATUS   CHART         APP VERSION
    istio-base istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed base-{{< istio_full_version >}}   {{< istio_full_version >}}
    istiod     istio-system 1        2024-04-17 22:14:45.964722028 +0000 UTC deployed istiod-{{< istio_full_version >}} {{< istio_full_version >}}
    {{< /text >}}

2. (Необовʼязково) Видаліть будь-які встановлені чарти шлюзів Istio:

    {{< text syntax=bash snip_id=delete_delete_gateway_charts >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

3. Видаліть чарт виявлення Istio:

    {{< text syntax=bash snip_id=helm_delete_discovery_chart >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

4. Видаліть базовий чарт Istio:

    {{< tip >}}
    За задумом, видалення чарту через Helm не видаляє встановлені Custom Resource Definitions (CRDs), встановлені через чарт.
    {{< /tip >}}

    {{< text syntax=bash snip_id=helm_delete_base_chart >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

5. Видаліть простір імен `istio-system`:

    {{< text syntax=bash snip_id=delete_istio_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

### Видалення ресурсів з мітками стабільної версії {#uninstall-stable-revision-label-resources}

Якщо ви вирішите продовжити використовувати стару панель управління замість завершення оновлення, ви можете видалити новішу версію та її мітку, спочатку виконавши команду:

{{< text syntax=bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags-mwc.yaml --set revisionTags={prod-canary} --set revision=canary -n istio-system | kubectl delete -f -
{{< /text >}}

Після цього ви повинні видалити версію Istio, на яку вона посилалася, слідуючи процедурі видалення, описаній вище.

Якщо ви встановили шлюз(и) для цієї версії за допомогою оновлень на місці, вам також потрібно вручну перевстановити шлюз(и) для попередньої версії. Видалення попередньої версії та її міток не поверне автоматично раніше оновлені шлюзи.

### (Опціонально) Видалення CRD, встановлених Istio {#optional-deleting-crds-installed-by-istio}

Видалення CRD назавжди видаляє всі ресурси Istio, які ви створили у вашому кластері. Щоб видалити CRD Istio, встановлені у вашому кластері:

{{< text syntax=bash >}}
$ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
{{< /text >}}

## Генерація маніфесту перед встановленням {#generate-a-manifest-before-installation}

Ви можете згенерувати маніфести для кожного компонента перед встановленням Istio, використовуючи команду `helm template`. Наприклад, щоб згенерувати маніфест, який можна встановити за допомогою `kubectl` для компонента `istiod`:

{{< text syntax=bash snip_id=none >}}
$ helm template istiod istio/istiod -n istio-system --kube-version {версія Kubernetes цільового кластера} > istiod.yaml
{{< /text >}}

Згенерований маніфест можна використовувати для перевірки того, що саме встановлюється, а також для відстеження змін у маніфесті з часом.

{{< tip >}}
Будь-які додаткові прапорці або перевизначення значень, які ви зазвичай використовуєте для встановлення, також повинні бути передані команді `helm template`.
{{< /tip >}}

Щоб встановити маніфест, згенерований вище, який створить компонент `istiod` у цільовому кластері:

{{< text syntax=bash snip_id=none >}}
$ kubectl apply -f istiod.yaml
{{< /text >}}

{{< warning >}}
Якщо ви намагаєтеся встановити та керувати Istio за допомогою `helm template`, зверніть увагу на наступні застереження:

1. Простір імен Istio (стандартно `istio-system`) повинен бути створений вручну.

1. Ресурси можуть не встановлюватися з тією ж послідовністю залежностей, як при `helm install`.

1. Цей метод не тестується як частина випусків Istio.

1. Хоча `helm install` автоматично виявляє налаштування середовища з вашого контексту Kubernetes, `helm template` не може це робити, оскільки він працює офлайн, що може призвести до несподіваних результатів. Зокрема, ви повинні переконатися, що ви дотримуєтеся [цих кроків](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens), якщо ваше середовище Kubernetes не підтримує токени сторонніх службових облікових записів.

1. `kubectl apply` згенерованого маніфесту може показувати тимчасові помилки через те, що ресурси не доступні в кластері в правильному порядку.

1. `helm install` автоматично видаляє будь-які ресурси, які повинні бути видалені при зміні конфігурації (наприклад, якщо ви видаляєте шлюз). Це не відбувається, коли ви використовуєте `helm template` з `kubectl`, і ці ресурси повинні бути видалені вручну.

{{< /warning >}}

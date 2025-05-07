---
title: Оновлення з Helm
linktitle: Оновлення з Helm
description: Інструкція з оновлення Istio за допомогою Helm.
weight: 27
keywords: [kubernetes, helm]
owner: istio/wg-environments-maintainers
test: yes
---

Слідуйте цьому посібнику для оновлення та налаштування сервісної мережі Istio за допомогою [Helm](https://helm.sh/docs/). Цей посібник передбачає, що ви вже виконали [встановлення за допомогою Helm](/docs/setup/install/helm) для попередньої незначної або патч-версії Istio.

{{< boilerplate helm-preamble >}}

{{< boilerplate helm-prereqs >}}

## Кроки для оновлення {#upgrade-steps}

Перед оновленням Istio рекомендується виконати команду `istioctl x precheck`, щоб переконатися, що оновлення сумісне з вашим середовищем.

{{< text bash >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

### Оновлення Canary (рекомендовано) {#canary-upgrade-recommended}

Ви можете встановити версію canary панелі управління Istio, щоб перевірити, чи нова версія сумісна з вашою поточною конфігурацією та панеллю даних за допомогою наведених нижче кроків:

{{< warning >}}
Зверніть увагу, що коли ви встановлюєте версію canary сервісу `istiod`, ресурси кластера з базового чарту спільно використовуються між вашими основними та canary установками.
{{< /warning >}}

{{< boilerplate crd-upgrade-123 >}}

1. Оновіть визначення власних ресурсів Kubernetes ({{< gloss CRD>}}CRD{{</ gloss >}}):

    {{< text bash >}}
    $ helm upgrade istio-base istio/base -n istio-system
    {{< /text >}}

2. Встановіть канаркову версію чарту виявлення Istio, встановивши ревізію:

    {{< text bash >}}
    $ helm install istiod-canary istio/istiod \
        --set revision=canary \
        -n istio-system
    {{< /text >}}

3. Перевірте, що у вашому кластері встановлено дві версії `istiod`:

    {{< text bash >}}
    $ kubectl get pods -l app=istiod -L istio.io/rev -n istio-system
      NAME                            READY   STATUS    RESTARTS   AGE   REV
      istiod-5649c48ddc-dlkh8         1/1     Running   0          71m   default
      istiod-canary-9cc9fd96f-jpc7n   1/1     Running   0          34m   canary
    {{< /text >}}

4. Якщо ви використовуєте [шлюзи Istio](/docs/setup/additional-setup/gateway/#deploying-a-gateway), встановіть версію canary чарту шлюзу, встановивши значення revision:

    {{< text bash >}}
    $ helm install istio-ingress-canary istio/gateway \
        --set revision=canary \
        -n istio-ingress
    {{< /text >}}

5. Перевірте, що у вашому кластері встановлено дві версії шлюзу `istio-ingress`:

    {{< text bash >}}
    $ kubectl get pods -L istio.io/rev -n istio-ingress
      NAME                                    READY   STATUS    RESTARTS   AGE     REV
      istio-ingress-754f55f7f6-6zg8n          1/1     Running   0          5m22s   default
      istio-ingress-canary-5d649bd644-4m8lp   1/1     Running   0          3m24s   canary
    {{< /text >}}

    Ознайомтеся з [Оновленням шлюзів](/docs/setup/additional-setup/gateway/#canary-upgrade-advanced) для докладної документації про оновлення canary шлюзів.

6. Слідуйте крокам [тут](/docs/setup/upgrade/canary/#data-plane), щоб протестувати або перенести поточні робочі навантаження для використання canary панелі управління.

7. Коли ви підтвердите та перенесете свої робочі навантаження для використання canary панелі управління, ви можете видалити стару панель управління:

    {{< text bash >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

8. Оновіть знов базовий чарт Istio, цього разу зробивши нову `canary` версію стандартною для всього кластера:

    {{< text bash >}}
    $ helm upgrade istio-base istio/base --set defaultRevision=canary -n istio-system
    {{< /text >}}

### Мітки стабільної версії {#stable-revision-labels}

{{< boilerplate revision-tags-preamble >}}

#### Використання {#usage}

{{< boilerplate revision-tags-usage >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-stable}" --set revision={{< istio_previous_version_revision >}}-1 -n istio-system | kubectl apply -f -
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-canary}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< warning >}}
Ці команди створюють нові ресурси `MutatingWebhookConfiguration` у вашому кластері, однак ним не володіє жоден чарт Helm через те, що `kubectl` вручну застосовує шаблони. Ознайомтеся з інструкціями нижче для видалення міток версій.
{{< /warning >}}

{{< boilerplate revision-tags-middle >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-stable}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< boilerplate revision-tags-prologue >}}

#### Стандартний теґ {#default-tag}

{{< boilerplate revision-tags-default-intro >}}

{{< text bash >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{default}" --set revision={{< istio_full_version_revision >}} -n istio-system | kubectl apply -f -
{{< /text >}}

{{< boilerplate revision-tags-default-outro >}}

### Оновлення на місці {#in-place-upgrade}

Ви можете виконати оновлення на місці Istio у вашому кластері за допомогою
робочого процесу оновлення Helm.

{{< warning >}}
Додайте файл перевизначення значень або власні параметри до наведених нижче команд, щоб зберегти вашу конфігурацію під час оновлення Helm.
{{< /warning >}}

{{< boilerplate crd-upgrade-123 >}}

1. Оновіть базовий чарт Istio:

    {{< text bash >}}
    $ helm upgrade istio-base istio/base -n istio-system
    {{< /text >}}

1. Оновіть чарт виявлення Istio:

    {{< text bash >}}
    $ helm upgrade istiod istio/istiod -n istio-system
    {{< /text >}}

1. (Необовʼязково) Оновіть чарти шлюзів, встановлені у вашому кластері:

    {{< text bash >}}
    $ helm upgrade istio-ingress istio/gateway -n istio-ingress
    {{< /text >}}

## Видалення {#uninstall}

Будь ласка, ознайомтеся з розділом видалення в нашому [посібнику з встановлення Helm](/docs/setup/install/helm/#uninstall).

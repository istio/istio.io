---
title: Канаркові оновлення
description: Оновлення Istio шляхом запуску канаркового розгортання нової панелі управління.
weight: 10
keywords: [kubernetes,upgrading,canary]
owner: istio/wg-environments-maintainers
test: yes
---

Оновлення Istio можна виконати, спочатку запустивши канаркове розгортання нової панелі управління, що дозволяє вам контролювати ефект від оновлення на невеликому відсотку навантажень перед міграцією всього трафіку на нову версію. Це значно безпечніше, ніж [оновлення на місці](/docs/setup/upgrade/in-place/) і є рекомендованим методом оновлення.

При установці Istio можна використовувати параметр `revision` для розгортання кількох незалежних панелей управління одночасно. Канаркову версію оновлення можна запустити, встановивши панель управління нової версії Istio поряд з попередньою, використовуючи інший параметр `revision`. Кожна ревізія є повною реалізацією панелі управління Istio з власним `Deployment`, `Service` тощо.

## Перед оновленням {#before-you-upgrade}

Перед оновленням Istio рекомендується виконати команду `istioctl x precheck`, щоб переконатися, що оновлення сумісне з вашим середовищем.

{{< text bash >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out https://istio.io/latest/docs/setup/getting-started/
{{< /text >}}

{{< idea >}}

При використанні оновлень на основі ревізій підтримується перехід через дві мінорні версії (наприклад, оновлення безпосередньо з версії `1.15` до `1.17`). Це на відміну від оновлень на місці, де необхідно оновлюватися до кожної проміжної мінорної версії.

{{< /idea >}}

## Панель управління {#control-plane}

Щоб встановити нову ревізію з назвою `canary`, потрібно встановити поле `revision` наступним чином:

{{< tip >}}
В операційному середовищі кращим варіантом назви ревізії буде відповідність версії Istio. Однак вам потрібно замінити символи `.` у назві ревізії, наприклад, `revision={{< istio_full_version_revision >}}` для Istio `{{< istio_full_version >}}`, оскільки `.` не є допустимим символом для назви ревізії.
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set revision=canary
{{< /text >}}

Після виконання команди у вас буде два розгортання панелей управління і сервіси, що працюють поруч:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-htddg    1/1     Running   0          47s
istiod-canary-84c8d4dcfb-skcfv   1/1     Running   0          25s
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n istio-system -l app=istiod
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
istiod-{{< istio_previous_version_revision >}}-1   ClusterIP   10.96.93.151     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   109s
istiod-canary   ClusterIP   10.104.186.250   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP   87s
{{< /text >}}

Ви також побачите, що є дві конфігурації інжектора sidecar контейнерів, включаючи нову ревізію.

{{< text bash >}}
$ kubectl get mutatingwebhookconfigurations
NAME                            WEBHOOKS   AGE
istio-sidecar-injector-{{< istio_previous_version_revision >}}-1   2          2m16s
istio-sidecar-injector-canary   2          114s
{{< /text >}}

## Панель даних {#data-plane}

Ознайомтеся з [Канарковим оновленням Gateway](/docs/setup/additional-setup/gateway/#canary-upgrade-advanced), щоб дізнатися, як запускати ревізійно специфічні екземпляри шлюзу Istio. У цьому прикладі, оскільки ми використовуємо профіль Istio `default`, шлюзи Istio не запускають ревізійно специфічні екземпляри, а замість цього оновлюються на місці для використання нової ревізії панелі управління. Ви можете перевірити, що шлюз `istio-ingress` використовує ревізію `canary`, виконавши наступну команду:

{{< text bash >}}
$ istioctl proxy-status | grep "$(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items..metadata.name}')" | awk -F '[[:space:]][[:space:]]+' '{print $8}'
istiod-canary-6956db645c-vwhsk
{{< /text >}}

Однак, проста установка нової ревізії не вплине на наявні sidecar проксі. Щоб оновити їх, потрібно налаштувати їх на нову панель управління `istiod-canary`. Це контролюється під час інʼєкції sidecar контейнерів на основі мітки простору імен `istio.io/rev`.

Створіть простір імен `test-ns` з увімкненим `istio-injection`. У просторі імен `test-ns` розгорніть демонстраційний pod `sleep`:

1. Створіть простір імен `test-ns`.

    {{< text bash >}}
    $ kubectl create ns test-ns
    {{< /text >}}

2. Позначте простір імен за допомогою мітки `istio-injection`.

    {{< text bash >}}
    $ kubectl label namespace test-ns istio-injection=enabled
    {{< /text >}}

3. Запустіть демонстраційний pod `sleep` у просторі імен `test-ns`.

    {{< text bash >}}
    $ kubectl apply -n test-ns -f samples/sleep/sleep.yaml
    {{< /text >}}

Щоб оновити простір імен `test-ns`, видаліть мітку `istio-injection` і додайте мітку `istio.io/rev`, щоб вказати на ревізію `canary`. Мітка `istio-injection` повинна бути видалена, оскільки вона має перевагу над міткою `istio.io/rev` для зворотної сумісності.

{{< text bash >}}
$ kubectl label namespace test-ns istio-injection- istio.io/rev=canary
{{< /text >}}

Після оновлення простору імен вам потрібно перезапустити podʼи, щоб запустити повторну ін’єкцію. Один зі способів перезапустити всі podʼи у просторі імен `test-ns` — це використання:

{{< text bash >}}
$ kubectl rollout restart deployment -n test-ns
{{< /text >}}

Коли інʼєкції будуть повторно додані до podʼів, podʼи будуть налаштовані на використання панелі управління `istiod-canary`. Ви можете перевірити це за допомогою `istioctl proxy-status`.

{{< text bash >}}
$ istioctl proxy-status | grep "\.test-ns "
{{< /text >}}

Вивід покаже всі podʼи у просторі імен, які використовують ревізію canary.

## Мітки стабільних ревізій {#stable-revision-labels}

{{< tip >}}
Якщо ви використовуєте Helm, зверніться до [документації з оновлення з Helm](/docs/setup/upgrade/helm).
{{</ tip >}}

{{< boilerplate revision-tags-preamble >}}

### Використання {#usage}

{{< boilerplate revision-tags-usage >}}

1. Встановіть дві ревізії панелі управління:

    {{< text bash >}}
    $ istioctl install --revision={{< istio_previous_version_revision >}}-1 --set profile=minimal --skip-confirmation
    $ istioctl install --revision={{< istio_full_version_revision >}} --set profile=minimal --skip-confirmation
    {{< /text >}}

2. Створіть мітки `stable` та `canary` ревізій і асоціюйте їх з відповідними ревізіями:

    {{< text bash >}}
    $ istioctl tag set prod-stable --revision {{< istio_previous_version_revision >}}-1
    $ istioctl tag set prod-canary --revision {{< istio_full_version_revision >}}
    {{< /text >}}

3. Позначте простори імен для застосунків мітками, щоб вони відповідали відповідним міткам ревізій:

    {{< text bash >}}
    $ kubectl create ns app-ns-1
    $ kubectl label ns app-ns-1 istio.io/rev=prod-stable
    $ kubectl create ns app-ns-2
    $ kubectl label ns app-ns-2 istio.io/rev=prod-stable
    $ kubectl create ns app-ns-3
    $ kubectl label ns app-ns-3 istio.io/rev=prod-canary
    {{< /text >}}

4. Запустіть демонстраційний pod `sleep` в кожному просторі імен:

    {{< text bash >}}
    $ kubectl apply -n app-ns-1 -f samples/sleep/sleep.yaml
    $ kubectl apply -n app-ns-2 -f samples/sleep/sleep.yaml
    $ kubectl apply -n app-ns-3 -f samples/sleep/sleep.yaml
    {{< /text >}}

5. Перевірте відповідність застосунку до панелі управління за допомогою команди `istioctl proxy-status`:

    {{< text bash >}}
    $ istioctl ps
    NAME                                CLUSTER        CDS        LDS        EDS        RDS        ECDS         ISTIOD                             VERSION
    sleep-78ff5975c6-62pzf.app-ns-3     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-s8zfg     {{< istio_full_version >}}
    sleep-78ff5975c6-8kxpl.app-ns-1     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-n72r2      {{< istio_previous_version >}}.1
    sleep-78ff5975c6-8q7m6.app-ns-2     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-{{< istio_previous_version_revision >}}-1-bdf5948d5-n72r2      {{< istio_previous_version_revision >}}.1
    {{< /text >}}

{{< boilerplate revision-tags-middle >}}

{{< text bash >}}
$ istioctl tag set prod-stable --revision {{< istio_full_version_revision >}} --overwrite
{{< /text >}}

{{< boilerplate revision-tags-prologue >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n app-ns-1
$ kubectl rollout restart deployment -n app-ns-2
{{< /text >}}

Перевірте відповідність застосунку до панелі управління за допомогою команди `istioctl proxy-status`:

{{< text bash >}}
$ istioctl ps
NAME                                                   CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                             VERSION
sleep-5984f48bc7-kmj6x.app-ns-1                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
sleep-78ff5975c6-jldk4.app-ns-3                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
sleep-7cdd8dccb9-5bq5n.app-ns-2                        Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-{{< istio_full_version_revision >}}-7f6fc6cfd6-jsktb     {{< istio_full_version >}}
{{< /text >}}

### Стандартний теґ {#default-tag}

{{< boilerplate revision-tags-default-intro >}}

{{< text bash >}}
$ istioctl tag set default --revision {{< istio_full_version_revision >}}
{{< /text >}}

{{< boilerplate revision-tags-default-outro >}}

## Видалення старої панелі управління {#uninstall-old-control-plane}

Після оновлення як панелі управління, так і панелі даних, ви можете видалити стару панель управління. Наприклад, наступна команда видаляє панель управління ревізії `{{< istio_previous_version_revision >}}-1`:

{{< text bash >}}
$ istioctl uninstall --revision {{< istio_previous_version_revision >}}-1 -y
{{< /text >}}

Якщо стара панель управління не має мітки ревізії, видаліть її, використовуючи оригінальні параметри установки, наприклад:

{{< text bash >}}
$ istioctl uninstall -f manifests/profiles/default.yaml -y
{{< /text >}}

Перевірте, що стара панель управління була видалена, і в кластері залишилася тільки нова:

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-canary-55887f699c-t8bh8   1/1     Running   0          27m
{{< /text >}}

Зверніть увагу, що наведені вище інструкції видалили лише ресурси для вказаної ревізії панелі управління, але не ресурси, що використовуються у кластері, які використовуються разом іншими панелямі управління. Щоб повністю видалити Istio, ознайомтеся з [посібником з видалення](/docs/setup/install/istioctl/#uninstall-istio).

## Видалення панелі управління Canary {#uninstall-canary-control-plane}

Якщо ви вирішите повернутися до старої панелі управління, замість завершення оновлення Canary, ви можете видалити ревізію Canary, використовуючи:

{{< text bash >}}
$ istioctl uninstall --revision=canary -y
{{< /text >}}

Однак у цьому випадку вам спочатку потрібно вручну перевстановити шлюзи для попередньої ревізії, оскільки команда видалення не відновить автоматично оновлені шлюзи.

{{< tip >}}
Переконайтеся, що ви використовуєте версію `istioctl`, відповідну старій панелі управління, для перевстановлення старих шлюзів і, щоб уникнути простоїв, переконайтеся, що старі шлюзи працюють перед продовженням видалення Canary.
{{< /tip >}}

## Очищення {#cleanup}

1. Видаліть створені мітки ревізій:

    {{< text bash >}}
    $ istioctl tag remove prod-stable
    $ istioctl tag remove prod-canary
    {{< /text >}}

2. Видаліть простори імен, що використовувалися для оновлення Canary з мітками ревізій:

    {{< text bash >}}
    $ kubectl delete ns istio-system test-ns
    {{< /text >}}

3. Видаліть простори імен, що використовувалися для оновлення Canary з мітками ревізій:

    {{< text bash >}}
    $ kubectl delete ns istio-system app-ns-1 app-ns-2 app-ns-3
    {{< /text >}}

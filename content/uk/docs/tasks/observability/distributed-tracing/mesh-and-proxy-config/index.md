---
title: Налаштування трейсингу за допомогою MeshConfig та анотацій Pod
description: Як налаштувати параметри трейсингу за допомогою MeshConfig та анотацій Pod.
weight: 60
keywords: [telemetry,tracing]
aliases:
 - /uk/docs/tasks/observability/distributed-tracing/configurability/
 - /uk/docs/tasks/observability/distributed-tracing/configurability/mesh-and-proxy-config/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
status: Beta
---

{{< boilerplate telemetry-tracing-tips >}}

Istio надає можливість налаштувати розширені параметри трейсингу, такі як швидкість вибірки та додавання власних теґів до відрізків (span). Вибірка є бета-функцією, але додавання власних теґів і довжина теґів трейсингу вважаються у розробці для цього випуску.

## Перед початком {#before-you-begin}

1. Переконайтеся, що ваші застосунки передають заголовки трейсингу, як описано [тут](/docs/tasks/observability/distributed-tracing/overview/).

1. Слідуйте керівництву з установки трейсингу, яке розташоване в розділі [Інтеграції](/docs/ops/integrations/) відповідно до вашого вибраного бекенду трейсингу, щоб встановити відповідний застосунок та налаштувати ваші проксі Istio для надсилання трейсів на розгортання трейсингу.

## Доступні конфігурації трейсингу {#available-tracing-configurations}

Ви можете налаштувати наступні параметри трейсингу в Istio:

1. Випадкова швидкість вибірки для відсотка запитів, які будуть вибрані для генерації трейсів.

1. Максимальна довжина шляху запиту після якої шлях буде обрізаний для звітування. Це може бути корисно для обмеження зберігання даних трейсів, особливо якщо ви збираєте трейси на вхідних шлюзах.

1. Додавання власних теґів до відрізків. Ці теґи можуть бути додані на основі статичних літеральних значень, значень середовища або полів з заголовків запитів. Це може бути використано для введення додаткової інформації у відрізки, специфічні для вашого середовища.

Налаштувати параметри трейсингу можна двома способами:

1. Глобально за допомогою опцій `MeshConfig`.

1. За допомогою анотацій на кожний pod для налаштування під конкретне робоче навантаження.

{{< warning >}}
Щоб нова конфігурація трейсингу набула чинності для будь-якого з цих варіантів, вам потрібно перезапустити podʼи, в які вставлені проксі Istio.
{{< /warning >}}

{{< warning >}}
Будь-які анотації podʼів, додані для конфігурації трейсингу, перевизначають глобальні налаштування. Щоб зберегти будь-які глобальні налаштування, ви повинні скопіювати їх з
глобальної конфігурації мережі до анотацій podʼа разом зі специфічними налаштуваннями для робочого навантаження. Особливо, переконайтеся, що адреса бекенду трейсингу завжди вказана в анотаціях, щоб забезпечити правильну передачу трейсів для робочого навантаження.
{{< /warning >}}

## Установка {#installation}

Використання цих функцій відкриває нові можливості для управління трейсами у вашому середовищі.

В цьому прикладі ми будемо вибирати всі трейси та додавати теґ з назвою `clusterID` за допомогою змінної середовища `ISTIO_META_CLUSTER_ID`, вставленої у ваш pod. Буде використано лише перші 256 символів значення.

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 100.0
        max_path_tag_length: 256
        custom_tags:
          clusterID:
            environment:
              name: ISTIO_META_CLUSTER_ID
EOF
$ istioctl install -f ./tracing.yaml
{{< /text >}}

### Використання `MeshConfig` для налаштування трейсингу {#using-meshconfig-for-trace-settings}

Всі параметри трейсингу можуть бути налаштовані глобально через `MeshConfig`. Для спрощення конфігурації, рекомендовано створити один YAML файл, який можна передати команді `istioctl install -f`.

{{< text yaml >}}
cat <<'EOF' > tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 10
        custom_tags:
          my_tag_header:
            header:
              name: host
EOF
{{< /text >}}

### Використання анотації `proxy.istio.io/config` для налаштування трейсингу {#using-proxyistioioconfig-annotation-for-trace-settings}

Ви можете додати анотацію `proxy.istio.io/config` до специфікації метаданих вашого Podʼа  для перевизначення будь-яких мережевих налаштувань трейсингу. Наприклад, щоб змінити розгортання `curl`, яке постачається з Istio, ви додасте наступне до `samples/curl/curl.yaml`:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        ...
        proxy.istio.io/config: |
          tracing:
            sampling: 10
            custom_tags:
              my_tag_header:
                header:
                  name: host
    spec:
      ...
{{< /text >}}

## Налаштування вибірки трейсів {#customizing-trace-sampling}

Опція швидкості вибірки може бути використана для контролю відсотка запитів, які повідомляються вашій системі трейсингу. Це повинно бути налаштоване залежно від вашого трафіку в мережі та кількості даних трейсингу, які ви хочете зібрати. Стандартно, швидкість вибірки становить 1%.

{{< warning >}}
Раніше рекомендувалося змінювати параметр `values.pilot.traceSampling` під час налаштування мережі або змінювати змінну середовища `PILOT_TRACE_SAMPLE` в розгортанні istiod. Хоча цей метод зміни вибірки продовжує працювати, наполегливо рекомендується використовувати наступний метод замість цього.

У випадку, якщо вказано обидва параметри, значення, вказане в `MeshConfig`, перевизначить будь-яке інше налаштування.
{{< /warning >}}

Щоб змінити стандартну випадкову вибірку на 50, додайте наступну опцію до вашого
файлу `tracing.yaml`.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 50
{{< /text >}}

Швидкість вибірки повинна бути в межах від 0.0 до 100.0 з точністю 0.01. Наприклад, щоб трейсити 5 запитів з кожних 10000, використовуйте значення 0.05 тут.

## Налаштування теґів трейсингу {#customizing-tracing-tags}

Власні теґи можуть бути додані до відрізків (span) на основі літералів, змінних середовища та заголовків клієнтських запитів для надання додаткової інформації у відрізках, специфічних для вашого середовища.

{{< warning >}}
Не існує обмеження на кількість власних теґів, які ви можете додати, але імена теґів повинні бути унікальними.
{{< /warning >}}

Ви можете налаштувати теґи, використовуючи будь-який з трьох підтримуваних варіантів нижче.

1. Літерал представляє статичне значення, яке додається до кожного відрізку.

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_literal:
                literal:
                  value: <VALUE>
    {{< /text >}}

1. Змінні середовища можуть бути використані, де значення власного теґу заповнюється з змінної середовища проксі робочого навантаження.

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_env:
                environment:
                  name: <ENV_VARIABLE_NAME>
                  defaultValue: <VALUE>      # необовʼязково
    {{< /text >}}

    {{< warning >}}
    Для додавання власних теґів на основі змінних середовища, вам потрібно змінити ConfigMap `istio-sidecar-injector` у вашому кореневому просторі системи Istio.
    {{< /warning >}}

1. Опція заголовка клієнтського запиту може бути використана для заповнення значення теґу з вхідного заголовка клієнтського запиту.

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_header:
                header:
                  name: <CLIENT-HEADER>
                  defaultValue: <VALUE>      # необовʼязково
    {{< /text >}}

## Налаштування довжини теґів трейсингу {#customizing-tracing-tag-length}

Стандартно, максимальна довжина шляху запиту, включеного як частина теґа `HttpUrl`, становить 256. Щоб змінити цю максимальну довжину, додайте наступне до вашого файлу `tracing.yaml`.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        max_path_tag_length: <VALUE>
{{< /text >}}

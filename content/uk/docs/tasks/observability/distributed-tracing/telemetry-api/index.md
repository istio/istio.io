---
title: Налаштування трейсингу за допомогою Telemetry API
description: Як налаштувати параметри трейсингу за допомогою Telemetry API.
weight: 2
keywords: [телеметрія,трейсинг,telemetry,tracing]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio надає можливість налаштувати розширені параметри трейсингу, такі як швидкість відбору і додавання власних теґів до звітів про відрізки (span). Це завдання показує, як налаштувати параметри трейсингу за допомогою Telemetry API.

## Перед початком {#before-you-begin}

1. Переконайтеся, що ваші застосунки пропагують заголовки трейсингу, як описано [тут](/docs/tasks/observability/distributed-tracing/overview/).

1. Дотримуйтесь посібника з установки трейсингу, розташованого в розділі [Інтеграції](/docs/ops/integrations/), залежно від вашого вибраного бекенду трейсингу, щоб встановити відповідне програмне забезпечення та налаштувати постачальника розширення.

## Установка {#installation}

В цьому прикладі ми надсилатимемо трейси до [`zipkin`](/docs/ops/integrations/zipkin/), тому переконайтеся, що він встановлений:

### Налаштування постачальника розширення {#configure-an-extension-provider}

Встановіть Istio з [постачальником розширення](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider), посилаючись на сервіс Zipkin:

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # відключіть застарілі параметри трейсингу MeshConfig
    extensionProviders:
    - name: "zipkin"
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
EOF
$ istioctl install -f ./tracing.yaml --skip-confirmation
{{< /text >}}

### Увімкнення трейсингу {#enable-tracing}

Увімкніть трейсинг, застосувавши наступну конфігурацію:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: "zipkin"
EOF
{{< /text >}}

### Перевірка результатів {#verify-the-results}

Ви можете перевірити результати за допомогою [Zipkin UI](/docs/tasks/observability/distributed-tracing/zipkin/).

## Налаштування {#customization}

## Налаштування відбору трейсів {#customizing-trace-sampling}

Параметр швидкості відбору можна використовувати для контролю відсотка запитів, які надсилаються до вашої системи трейсингу. Це потрібно налаштувати залежно від вашого трафіку в мережі та обсягу даних трейсингу, які ви хочете збирати. Стандартно швидкість відбору становить 1%.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: "zipkin"
    randomSamplingPercentage: 100.00
EOF
{{< /text >}}

### Налаштування теґів трейсингу {#customizing-tracing-tags}

Власні теґи можуть бути додані до відрізків на основі літералів, змінних середовища та заголовків запитів клієнтів для надання додаткової інформації у відрізках, специфічних для вашого середовища.

{{< warning >}}
Немає обмежень на кількість власних теґів, які ви можете додати, але імена теґів повинні бути унікальними.
{{< /warning >}}

Ви можете налаштувати теґи, використовуючи один з трьох підтримуваних варіантів нижче.

1. Літерал представляє статичне значення, яке додається до кожного відрізку.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
    name: mesh-default
    namespace: istio-system
    spec:
      tracing:
      - providers:
        - name: "zipkin"
        randomSamplingPercentage: 100.00
        customTags:
          "provider":
            literal:
              value: "zipkin"
    {{< /text >}}

1. Змінні середовища можна використовувати, де значення власного теґу заповнюється зі змінної середовища проксі навантаження.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
          - name: "zipkin"
          randomSamplingPercentage: 100.00
          customTags:
            "cluster_id":
              environment:
                name: ISTIO_META_CLUSTER_ID
                defaultValue: Kubernetes # необов'язково
    {{< /text >}}

    {{< warning >}}
    Щоб додати власні теґи на основі змінних середовища, потрібно змінити ConfigMap `istio-sidecar-injector` у вашому кореневому просторі імен Istio.
    {{< /warning >}}

1. Опція заголовків запитів клієнтів може бути використана для заповнення значення теґу з вхідного заголовка запиту клієнта.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
          - name: "zipkin"
          randomSamplingPercentage: 100.00
          customTags:
            my_tag_header:
              header:
                name: <CLIENT-HEADER>
                defaultValue: <VALUE>      # необов'язково
    {{< /text >}}

### Налаштування довжини теґів трейсингу {#customizing-tracing-tag-length}

Стандартно максимальна довжина для шляху запиту, включеного в теґ відрізку `HttpUrl`, становить 256. Щоб змінити цю максимальну довжину, додайте наступне до вашого файлу `tracing.yaml`.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # відключіть застарілі параметри трейсингу через `MeshConfig`
    extensionProviders:
    - name: "zipkin"
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
        maxTagLength: <VALUE>
{{< /text >}}

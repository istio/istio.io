---
title: Симуляція дій
description: Показує, як виконати симуляцію використання політики авторизації без її застосування.
weight: 65
keywords: [security,access-control,rbac,authorization,dry-run]
owner: istio/wg-security-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Ця задача показує, як налаштувати політику авторизації Istio, використовуючи нову [експериментальну анотацію `istio.io/dry-run`](/docs/reference/config/annotations/) для симуляції політики без фактичного її застосування.

Анотація dry-run дозволяє краще зрозуміти вплив політики авторизації перед її застосуванням до операційного трафіку. Це допомагає зменшити ризик порушення операційного трафіку, викликаного некоректною політикою авторизації.

## Перед початком {#before-you-begin}

Перед початком цієї задачі виконайте наступні кроки:

* Ознайомтесь з [поняттями авторизації Istio](/docs/concepts/security/#authorization).

* Дотримуйтесь [інструкції з встановлення Istio](/docs/setup/install) для встановлення.

* Розгорніть Zipkin для перевірки результатів симуляції. Дотримуйтесь [завдання Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/) для встановлення Zipkin у кластер.

* Розгорніть Prometheus для перевірки результатів симуляції метрик. Дотримуйтесь [завдання Prometheus](/docs/tasks/observability/metrics/querying-metrics/) для встановлення Prometheus у кластер.

* Розгорніть тестові робочі навантаження:

    Ця задача використовує два робочих навантаження, `httpbin` та `curl`, обидва розгорнуті в просторі імен `foo`. Обидва робочих навантаження працюють з sidecar проксі Envoy. Створіть простір імен `foo` і розгорніть робочі навантаження за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/curl/curl.yaml@ -n foo
    {{< /text >}}

* Увімкніть рівень журналів налагодження проксі для перевірки результатів симуляції журналювання:

    {{< text bash >}}
    $ istioctl proxy-config log deploy/httpbin.foo --level "rbac:debug" | grep rbac
    rbac: debug
    {{< /text >}}

* Перевірте, чи може `curl` отримати доступ до `httpbin` за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
Якщо ви не бачите очікуваного результату під час виконання задачі, повторіть спробу через кілька секунд. Кешування і затримка поширення можуть спричинити деяку затримку.
{{< /warning >}}

## Створення політики симуляції {#create-dry-run-policy}

1. Створіть політику авторизації з анотацією симуляції `"istio.io/dry-run": "true"` за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-path-headers
      annotations:
        "istio.io/dry-run": "true"
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            paths: ["/headers"]
    EOF
    {{< /text >}}

    Ви також можете використовувати наступну команду для швидкої зміни наявної політики авторизації в режим симуляції:

    {{< text bash >}}
    $ kubectl annotate --overwrite authorizationpolicies deny-path-headers -n foo istio.io/dry-run='true'
    {{< /text >}}

1. Перевірте, що запити до шляху `/headers` дозволені, оскільки політика створена в режимі симуляції, запустіть наступну команду для надсилання 20 запитів від `curl` до `httpbin`, запит включає заголовок `X-B3-Sampled: 1`, щоб завжди активувати трасування Zipkin:

    {{< text bash >}}
    $ for i in {1..20}; do kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/headers -H "X-B3-Sampled: 1" -s -o /dev/null -w "%{http_code}\n"; done
    200
    200
    200
    ...
    {{< /text >}}

## Перевірка результатів симуляції в журналі проксі {#check-dry-run-result-in-proxy-log}

Результати симуляції можна знайти в журналі налагодження проксі у форматі `shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]`. Запустіть наступну команду для перевірки журналу:

{{< text bash >}}
$ kubectl logs "$(kubectl -n foo -l app=httpbin get pods -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo | grep "shadow denied"
2021-11-19T20:20:48.733099Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
2021-11-19T20:21:45.502199Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
2021-11-19T20:22:33.065348Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
...
{{< /text >}}

Також дивіться [посібник з усунення неполадок](/docs/ops/common-problems/security-issues/#ensure-proxies-enforce-policies-correctly) для отримання додаткових відомостей про журналювання.

## Перевірка результатів симуляції в метриках за допомогою Prometheus {#check-dry-run-result-in-metric-using-prometheus}

1. Відкрийте дашборд Prometheus за допомогою наступної команди:

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

1. В Prometheus знайдіть наступну метрику:

    {{< text plain >}}
    envoy_http_inbound_0_0_0_0_80_rbac{authz_dry_run_action="deny",authz_dry_run_result="denied"}
    {{< /text >}}

1. Перевірте результат запиту метрики наступним чином:

    {{< text plain >}}
    envoy_http_inbound_0_0_0_0_80_rbac{app="httpbin",authz_dry_run_action="deny",authz_dry_run_result="denied",instance="10.44.1.11:15020",istio_io_rev="default",job="kubernetes-pods",kubernetes_namespace="foo",kubernetes_pod_name="httpbin-74fb669cc6-95qm8",pod_template_hash="74fb669cc6",security_istio_io_tlsMode="istio",service_istio_io_canonical_name="httpbin",service_istio_io_canonical_revision="v1",version="v1"}  20
    {{< /text >}}

1. Запитана метрика має значення `20` (можливо, ви знайдете інше значення залежно від кількості надісланих запитів. Це очікується, якщо значення більше за 0). Це означає, що політика симуляції застосована до робочого навантаження `httpbin` на порту `80` і відповідала одному запиту. Політика б відхилила запит, якби він не був у режимі симуляції.

1. Наступний знімок з екрана Prometheus:

    {{< image width="100%" link="./prometheus.png" caption="Prometheus" >}}

## Перевірка результатів симуляції в трасуванні за допомогою Zipkin {#check-dry-run-result-in-tracing-using-zipkin}

1. Відкрийте Zipkin за допомогою наступної команди:

    {{< text bash >}}
    $ istioctl dashboard zipkin
    {{< /text >}}

2. Знайдіть результат трасування для запиту від `curl` до `httpbin`. Спробуйте надіслати ще кілька запитів, якщо ви не бачите результат трасування через затримку в Zipkin.

3. У результаті трасування ви повинні знайти наступні власні теґи, що вказують на те, що запит відхилено політикою симуляції `deny-path-headers` у просторі імен `foo`:

    {{< text plain >}}
    istio.authorization.dry_run.deny_policy.name: ns[foo]-policy[deny-path-headers]-rule[0]
    istio.authorization.dry_run.deny_policy.result: denied
    {{< /text >}}

4. Наступний знімок з екрана Zipkin:

    {{< image width="100%" link="./trace.png" caption="Zipkin" >}}

## Підсумок {#summary}

Журнал налагодження проксі, метрика Prometheus та результати трасування Zipkin вказують на те, що політика симуляції відхилить запит. Ви можете далі змінювати політику, якщо результат симуляції не відповідає очікуванням.

Рекомендується зберігати політику симуляції деякий додатковий час, щоб вона могла бути перевірена з більшим обсягом операційного трафіку.

Коли ви будете впевнені у результаті симуляції, ви можете вимкнути режим симуляції, щоб політика почала фактично відхиляти запити. Це можна зробити одним з наступних способів:

* Повністю видалити анотацію симуляції; або

* Змінити значення анотації симуляції на `false`.

## Обмеження {#limitations}

Анотація симуляції наразі є експериментальною і має наступні обмеження:

* Анотація симуляції наразі підтримує лише політики ALLOW і DENY;

* Будуть два окремі результати симуляції (тобто журнал, метрика і теґ трасування) для політик ALLOW і DENY через те, що політики ALLOW і DENY виконуються окремо в проксі. Ви повинні враховувати обидва результати симуляції, оскільки запит може бути дозволений політикою ALLOW, але все ще відхилений іншою політикою DENY;

* Результати симуляції в журналі проксі, метриках і трасуванні надаються для ручного усунення неполадок і не повинні використовуватися як API, оскільки вони можуть змінюватися в будь-який час без попереднього повідомлення.

## Очищення {#clean-up}

1. Видаліть простір імен `foo` з вашої конфігурації:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

1. Видаліть Prometheus і Zipkin, якщо вони більше не потрібні.

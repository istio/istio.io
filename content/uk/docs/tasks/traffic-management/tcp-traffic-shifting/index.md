---
title: Перемикання трафіку TCP
description: Показує, як перенести TCP-трафік зі старої на нову версію TCP-сервісу.
weight: 31
keywords: [traffic-management,tcp-traffic-shifting]
aliases:
    - /uk/docs/tasks/traffic-management/tcp-version-migration.html
owner: istio/wg-networking-maintainers
test: yes
---
Це завдання показує, як перенести TCP-трафік зі одної версії мікросервісу на іншу.

Поширений випадок використання — це поступове перенесення TCP трафіку зі старої версії мікросервісу на нову. В Istio ви досягаєте цієї мети, конфігуруючи послідовність правил маршрутизації, які перенаправляють відсоток TCP трафіку з одного призначення на інше.

У цьому завданні ви направите 100% TCP трафіку до `tcp-echo:v1`. Потім ви направите 20% TCP трафіку до `tcp-echo:v2`, використовуючи функцію маршрутизації за коефіцієнтами в Istio.

{{< boilerplate gateway-api-gamma-experimental >}}

## Перш ніж почати {#before-you-begin}

* Налаштуйте Istio, дотримуючись інструкцій у [керівництві з встановлення](/docs/setup/).

* Ознайомтеся з документацією [Управління трафіком](/docs/concepts/traffic-management).

## Налаштування тестового середовища {#set-up-the-test-environment}

1.  Щоб почати, створіть простір імен для тестування перемикання TCP трафіку.

    {{< text bash >}}
    $ kubectl create namespace istio-io-tcp-traffic-shifting
    {{< /text >}}

2.  Розгорніть демонстраційний застосунок [sleep]({{< github_tree >}}/samples/sleep), який буде використовуватися як джерело тестових запитів.

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

3.  Розгорніть версії `v1` і `v2` мікросервісу `tcp-echo`.

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-services.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

## Застосування маршрутизації TCP на основі коефіцієнтів {#apply-weight-based-tcp-routing}

1.  Направте весь TCP трафік до версії `v1` мікросервісу `tcp-echo`.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/gateway-api/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1)  Визначте ingress IP та port:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Дотримуйтесь інструкцій [Визначення ingress IP та портів](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports), щоб встановити змінні оточення `TCP_INGRESS_PORT` та `INGRESS_HOST`.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Використовуйте наступні команди для встановлення змінних оточення `SECURE_INGRESS_PORT` та `INGRESS_HOST`:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting
$ export INGRESS_HOST=$(kubectl get gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting -o jsonpath='{.status.addresses[0].value}')
$ export TCP_INGRESS_PORT=$(kubectl get gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting -o jsonpath='{.spec.listeners[?(@.name=="tcp-31400")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Переконайтеся, що служба `tcp-echo` працює, надіславши до неї деякий TCP-трафік.

    {{< text bash >}}
    $ export SLEEP=$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})
    $ for i in {1..20}; do \
    kubectl exec "$SLEEP" -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
    done
    one Mon Nov 12 23:24:57 UTC 2022
    one Mon Nov 12 23:25:00 UTC 2022
    one Mon Nov 12 23:25:02 UTC 2022
    one Mon Nov 12 23:25:05 UTC 2022
    one Mon Nov 12 23:25:07 UTC 2022
    one Mon Nov 12 23:25:10 UTC 2022
    one Mon Nov 12 23:25:12 UTC 2022
    one Mon Nov 12 23:25:15 UTC 2022
    one Mon Nov 12 23:25:17 UTC 2022
    one Mon Nov 12 23:25:19 UTC 2022
    ...
    {{< /text >}}

    Зверніть увагу, що всі мітки часу мають префікс _one_, що означає, що весь трафік було перенаправлено на `v1` версію сервісу `tcp-echo`.

4)  Передайте 20% трафіку з `tcp-echo:v1` на `tcp-echo:v2` за допомогою наступної команди:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/tcp-echo-20-v2.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/gateway-api/tcp-echo-20-v2.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5) Зачекайте кілька секунд, поки нові правила поширяться, а потім підтвердіть, що правило було замінено:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash yaml >}}
$ kubectl get virtualservice tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
apiVersion: networking.istio.io/v1
kind: VirtualService
  ...
spec:
  ...
  tcp:
  - match:
    - port: 31400
    route:
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v1
      weight: 80
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v2
      weight: 20
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get tcproute tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
  ...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: tcp-echo-gateway
    sectionName: tcp-31400
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: tcp-echo-v1
      port: 9000
      weight: 80
    - group: ""
      kind: Service
      name: tcp-echo-v2
      port: 9000
      weight: 20
...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6)  Надішліть ще трохи TCP-трафіку до мікросервісу `tcp-echo`.

    {{< text bash >}}
    $ export SLEEP=$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})
    $ for i in {1..20}; do \
    kubectl exec "$SLEEP" -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
    done
    one Mon Nov 12 23:38:45 UTC 2022
    two Mon Nov 12 23:38:47 UTC 2022
    one Mon Nov 12 23:38:50 UTC 2022
    one Mon Nov 12 23:38:52 UTC 2022
    one Mon Nov 12 23:38:55 UTC 2022
    two Mon Nov 12 23:38:57 UTC 2022
    one Mon Nov 12 23:39:00 UTC 2022
    one Mon Nov 12 23:39:02 UTC 2022
    one Mon Nov 12 23:39:05 UTC 2022
    one Mon Nov 12 23:39:07 UTC 2022
    ...
    {{< /text >}}

    Тепер ви повинні помітити, що близько 20% міток часу мають префікс _two_, що означає, що 80% TCP-трафіку було перенаправлено на `v1` версію служби `tcp-echo`, а 20% — на `v2`.

## Розуміння того, що відбулося {#understanding-what-happened}

У цьому завданні ви частково мігрували TCP трафік зі старої версії на нову версію
сервісу `tcp-echo`, використовуючи функцію маршрутизації за коефіцієнтами Istio. Зверніть увагу, що це дуже відрізняється від міграції версій за допомогою функцій розгортання платформ оркестрування контейнерів, які використовують масштабування екземплярів для управління трафіком.

За допомогою Istio ви можете дозволити двом версіям сервісу `tcp-echo` масштабуватися вгору і вниз незалежно одна від одної, не впливаючи на розподіл трафіку між ними.

Для отримання додаткової інформації про маршрутизацію версій з автомасштабуванням, ознайомтеся зі статтею в блозі [Canary Deployment з використанням Istio](/blog/2017/0.1-canary/).

## Очищення {#cleanup}

1. Видаліть правила маршрутизації:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/tcp-echo/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/tcp-echo/gateway-api/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) Видаліть демонстраційний застосунок `sleep`, застосунок `tcp-echo` і тестовий простір імен:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-services.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete namespace istio-io-tcp-traffic-shifting
    {{< /text >}}

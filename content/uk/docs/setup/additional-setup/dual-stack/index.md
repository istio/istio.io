---
title: Встановлення Istio у двостековому режимі
description: Встановіть та використовуйте Istio у двостековому режимі на двостековому кластері Kubernetes.
weight: 60
keywords: [dual-stack]
owner: istio/wg-networking-maintainers
test: yes
---

{{< boilerplate alpha >}}

## Передумови {#prerequisites}

* Istio 1.17 або новіший.
* Kubernetes 1.23 або новіший [налаштований для роботи в режимі dual-stack](https://kubernetes.io/docs/concepts/services-networking/dual-stack/).

## Кроки установки {#installation-steps}

Якщо ви хочете використовувати `kind` для вашого тесту, ви можете налаштувати кластер dual-stack за допомогою наступної команди:

{{< text syntax=bash snip_id=none >}}
$ kind create cluster --name istio-ds --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: dual
EOF
{{< /text >}}

Щоб увімкнути dual-stack для Istio, вам потрібно змінити ваш `IstioOperator` або значення Helm наступною конфігурацією.

{{< tabset category-name="dualstack" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_DUAL_STACK: "true"
  values:
    pilot:
      env:
        ISTIO_DUAL_STACK: "true"
    # Наведені нижче значення є необовʼязковими та можуть використовуватися залежно від ваших вимог
    gateways:
      istio-ingressgateway:
        ipFamilyPolicy: RequireDualStack
      istio-egressgateway:
        ipFamilyPolicy: RequireDualStack
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text syntax=yaml snip_id=none >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ISTIO_DUAL_STACK: "true"
values:
  pilot:
    env:
      ISTIO_DUAL_STACK: "true"
  # Наведені нижче значення є необовʼязковими та можуть використовуватися залежно від ваших вимог
  gateways:
    istio-ingressgateway:
      ipFamilyPolicy: RequireDualStack
    istio-egressgateway:
      ipFamilyPolicy: RequireDualStack
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Перевірка {#verification}

1. Створіть три простори імен:

    * `dual-stack`: `tcp-echo` буде слухати на обох IPv4 та IPv6 адресах.
    * `ipv4`: `tcp-echo` буде слухати тільки на IPv4 адресі.
    * `ipv6`: `tcp-echo` буде слухати тільки на IPv6 адресі.

    {{< text bash >}}
    $ kubectl create namespace dual-stack
    $ kubectl create namespace ipv4
    $ kubectl create namespace ipv6
    {{< /text >}}

1. Увімкніть інʼєкцію sidecar у всіх цих просторах імен, а також у просторі імен `default`:

    {{< text bash >}}
    $ kubectl label --overwrite namespace default istio-injection=enabled
    $ kubectl label --overwrite namespace dual-stack istio-injection=enabled
    $ kubectl label --overwrite namespace ipv4 istio-injection=enabled
    $ kubectl label --overwrite namespace ipv6 istio-injection=enabled
    {{< /text >}}

1. Створіть [tcp-echo]({{< github_tree >}}/samples/tcp-echo) розгортання у просторах імен:

    {{< text bash >}}
    $ kubectl apply --namespace dual-stack -f @samples/tcp-echo/tcp-echo-dual-stack.yaml@
    $ kubectl apply --namespace ipv4 -f @samples/tcp-echo/tcp-echo-ipv4.yaml@
    $ kubectl apply --namespace ipv6 -f @samples/tcp-echo/tcp-echo-ipv6.yaml@
    {{< /text >}}

1. Розгорніть [sleep]({{< github_tree >}}/samples/sleep) зразок програми для використання як джерела тестових запитів.

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. Перевірте, чи трафік досягає podʼів dual-stack:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo dualstack | nc tcp-echo.dual-stack 9000"
    hello dualstack
    {{< /text >}}

1. Перевірте, чи трафік досягає podʼів IPv4:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv4 | nc tcp-echo.ipv4 9000"
    hello ipv4
    {{< /text >}}

1. Перевірте, чи трафік досягає podʼів IPv6:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv6 | nc tcp-echo.ipv6 9000"
    hello ipv6
    {{< /text >}}

1. Перевірте слухачів envoy:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl proxy-config listeners "$(kubectl get pod -n dual-stack -l app=tcp-echo -o jsonpath='{.items[0].metadata.name}')" -n dual-stack --port 9000
    {{< /text >}}

    Ви побачите, що слухачі тепер привʼязані до кількох адрес, але тільки для сервісів dual-stack. Інші сервіси будуть слухати тільки на одній IP-адресі.

    {{< text syntax=json snip_id=none >}}
        "name": "fd00:10:96::f9fc_9000",
        "address": {
            "socketAddress": {
                "address": "fd00:10:96::f9fc",
                "portValue": 9000
            }
        },
        "additionalAddresses": [
            {
                "address": {
                    "socketAddress": {
                        "address": "10.96.106.11",
                        "portValue": 9000
                    }
                }
            }
        ],
    {{< /text >}}

1. Перевірте, чи віртуальні вхідні адреси налаштовані на прослуховування як `0.0.0.0`, так і `[::]`.

    {{< text syntax=json snip_id=none >}}
    "name": "virtualInbound",
    "address": {
        "socketAddress": {
            "address": "0.0.0.0",
            "portValue": 15006
        }
    },
    "additionalAddresses": [
        {
            "address": {
                "socketAddress": {
                    "address": "::",
                    "portValue": 15006
                }
            }
        }
    ],
    {{< /text >}}

2. Перевірте, чи точки доступу envoy налаштовані на маршрутизацію як до IPv4, так і до IPv6:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl proxy-config endpoints "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" --port 9000
    ENDPOINT                 STATUS      OUTLIER CHECK     CLUSTER
    10.244.0.19:9000         HEALTHY     OK                outbound|9000||tcp-echo.ipv4.svc.cluster.local
    10.244.0.26:9000         HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
    fd00:10:244::1a:9000     HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
    fd00:10:244::18:9000     HEALTHY     OK                outbound|9000||tcp-echo.ipv6.svc.cluster.local
    {{< /text >}}

Тепер ви можете експериментувати з сервісами dual-stack у вашому середовищі!

## Очищення {#cleanup}

1. Очищення просторів імен і розгортання застосунків

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    $ kubectl delete ns dual-stack ipv4 ipv6
    {{< /text >}}

---
title: Контроль доступу на вході
description: Показує, як налаштувати контроль доступу на вхідному шлюзі.
weight: 50
keywords: [security,access-control,rbac,authorization,ingress,ip,allowlist,denylist]
owner: istio/wg-security-maintainers
test: yes
---

Це завдання показує, як застосувати контроль доступу на основі IP до вхідного шлюзу Istio за допомогою політики авторизації.

{{< boilerplate gateway-api-support >}}

## Перед початком {#before-you-begin}

Перед початком цього завдання зробіть наступне:

* Ознайомтеся з [концепціями авторизації Istio](/docs/concepts/security/#authorization).

* Встановіть Istio за допомогою [посібника з установки Istio](/docs/setup/install/istioctl/).

* Розгорніть навантаження, `httpbin`, у просторі імен `foo` з увімкненою інʼєкцією sidecar:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label namespace foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    {{< /text >}}

* Експонуйте `httpbin` через вхідний шлюз:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Налаштуйте шлюз:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
{{< /text >}}

Увімкніть налагодження RBAC в Envoy для вхідного шлюзу:

{{< text bash >}}
$ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n istio-system --level rbac:debug; done
{{< /text >}}

Слідуйте інструкціям у [Визначення IP-адреси та портів вхідного шлюзу](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports),
щоб визначити змінні середовища `INGRESS_PORT` та `INGRESS_HOST`.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Створіть шлюз:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@ -n foo
{{< /text >}}

Зачекайте, поки шлюз не буде готовий:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw -n foo httpbin-gateway
{{< /text >}}

Увімкніть налагодження RBAC в Envoy для вхідного шлюзу:

{{< text bash >}}
$ kubectl get pods -n foo -o name -l gateway.networking.k8s.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n foo --level rbac:debug; done
{{< /text >}}

Встановіть змінні середовища `INGRESS_PORT` та `INGRESS_HOST`:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* Перевірте, що навантаження `httpbin` і вхідний шлюз працюють як очікувалося, за допомогою цієї команди:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    {{< warning >}}
    Якщо ви не бачите очікуваного результату, слідкуйте за завданням ще раз через кілька секунд. Кешування та затримки поширення можуть спричинити деякі затримки.
    {{< /warning >}}

## Отримання трафіку в Kubernetes та Istio {#getting-traffic-into-kubernetes-and-istio}

Усі методи отримання трафіку в Kubernetes передбачають відкриття порту на всіх робочих вузлах. Основні елементи, які це забезпечують, — це сервіси `NodePort` та `LoadBalancer`. Навіть ресурс Kubernetes `Ingress` повинен бути підкріплений контролером Ingress, який створить або сервіс `NodePort`, або сервіс `LoadBalancer`.

* `NodePort` просто відкриває порт у діапазоні 30000-32767 на кожному робочому вузлі та використовує селектор міток для ідентифікації того, яким Podʼам надсилати трафік. Вам потрібно вручну створити якийсь тип балансувальника навантаження перед вашими робочими вузлами або використовувати Round-Robin DNS.

* `LoadBalancer` подібний до `NodePort`, але також створює специфічний для середовища зовнішній балансувальник навантаження для розподілу трафіку між робочими вузлами. Наприклад, у AWS EKS служба `LoadBalancer` створить Classic ELB з вашими робочими вузлами як цільовими. Якщо ваше середовище Kubernetes не має реалізації `LoadBalancer`, то воно просто поводитиметься як `NodePort`. Вхідний шлюз Istio створює сервіс `LoadBalancer`.

Що робити, якщо Pod, який обробляє трафік з `NodePort` або `LoadBalancer`, не працює на робочому вузлі, який отримав трафік? Kubernetes має власний внутрішній проксі kube-proxy, який отримує пакети та пересилає їх на правильний вузол.

## IP-адреса оригінального клієнта {#source-ip-address-of-the-original-client}

Якщо пакет проходить через зовнішній проксі балансувальник навантаження і/або kube-proxy, то оригінальна IP-адреса клієнта втрачається. Нижченаведені підрозділи описують деякі стратегії збереження оригінальної IP-адреси клієнта для ведення журналу або для безпеки для різних типів балансувальників навантаження:

1. [TCP/UDP проксі балансувальник навантаження](#tcp-proxy)
1. [Мережевий балансувальник навантаження](#network)
1. [HTTP/HTTPS балансувальник навантаження](#http-https)

Для довідки наведено типи балансувальників навантаження, які створює Istio з сервісом `LoadBalancer` у популярних середовищах Kubernetes, що надаються провадерами послуг:

|Хмарний провайдер| Назва балансувальника навантаження | Тип балансувальника навантаження
------------------|------------------------------------|---------------------------------
|AWS EKS          | Classic Elastic Load Balancer      | TCP Proxy
|GCP GKE          | TCP/UDP Network Load Balancer      | Network
|Azure AKS        | Azure Load Balancer                | Network
|IBM IKS/ROKS     | Network Load Balancer              | Network
|DO DOKS          | Load Balancer                      | Network

{{< tip >}}
Ви можете доручити AWS EKS створити мережевий балансувальник навантаження з анотацією на сервісі шлюзу:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
  components:
    ingressGateways:
    - enabled: true
      k8s:
        hpaSpec:
          maxReplicas: 10
          minReplicas: 5
        serviceAnnotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  gatewayClassName: istio
  ...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< /tip >}}

### TCP/UDP проксі балансувальник навантаження {#tcp-proxy}

Якщо ви використовуєте зовнішній балансувальник навантаження TCP/UDP (AWS Classic ELB), він може використовувати [PROXY Protocol](https://www.haproxy.com/blog/haproxy/proxy-protocol/) для вбудовування оригінальної IP-адреси клієнта в дані пакета. Для того щоб це працювало, як зовнішній балансувальник навантаження, так і вхідний шлюз Istio повинні підтримувати PROXY протокол.

Ось приклад конфігурації, який показує, як налаштувати вхідний шлюз на AWS EKS для підтримки PROXY Protocol:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
    defaultConfig:
      gatewayTopology:
        proxyProtocol: {}
  components:
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
      k8s:
        hpaSpec:
          maxReplicas: 10
          minReplicas: 5
        serviceAnnotations:
          service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
        ...
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
    proxy.istio.io/config: '{"gatewayTopology" : { "proxyProtocol": {} }}'
spec:
  gatewayClassName: istio
  ...
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: httpbin-gateway
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: httpbin-gateway-istio
  minReplicas: 5
  maxReplicas: 10
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Мережевий балансувальник навантаження {#network}

Якщо ви використовуєте мережевий балансувальник навантаження TCP/UDP, який зберігає IP-адресу клієнта (AWS Network Load Balancer, GCP External Network Load Balancer, Azure Load Balancer) або використовуєте Round-Robin DNS, ви можете використовувати параметр `externalTrafficPolicy: Local`, щоб також зберегти IP-адресу клієнта всередині Kubernetes, обходячи kube-proxy і запобігаючи надсиланню трафіку на інші вузли.

{{< warning >}}
Для операційних розгортань наполегливо рекомендується **розгорнути Pod вхідного шлюзу на кількох вузлах**, якщо ви вимкаєте `externalTrafficPolicy: Local`. Інакше це створює ситуацію, коли **тільки** вузли з активним Pod вхідного шлюзу зможуть приймати та розподіляти вхідний трафік NLB на решту кластеру, що може призвести до потенційних вузьких місць у трафіку вхідного шлюзу та зменшення можливостей внутрішнього балансування навантаження або навіть повної втрати вхідного трафіку в кластері, якщо підмножина вузлів з Podʼами вхідного шлюзу вийде з ладу. Дивіться [IP-адреса джерела для сервісів з `Type=NodePort`](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-nodeport) для отримання додаткової інформації.
{{< /warning >}}

Оновіть вхідний шлюз, щоб встановити `externalTrafficPolicy: Local`, щоб зберегти
оригінальну IP-адресу джерела клієнта на вхідному шлюзі, використовуючи наступну команду:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl patch svc httpbin-gateway-istio -n foo -p '{"spec":{"externalTrafficPolicy":"Local"}}'
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### HTTP/HTTPS балансувальник навантаження {#http-https}

Якщо ви використовуєте зовнішній балансувальник навантаження HTTP/HTTPS (AWS ALB, GCP), він може вставити оригінальну IP-адресу клієнта в заголовок X-Forwarded-For. Istio може витягти IP-адресу клієнта з цього заголовка за допомогою певної конфігурації. Дивіться [Налаштування топології мережі шлюзу](/docs/ops/configuration/traffic-management/network-topologies/). Швидкий приклад, якщо використовується один балансувальник навантаження перед Kubernetes:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: 1
{{< /text >}}

## Список дозволених та заборонених IP-адрес {#ip-based-allow-list-and-deny-list}

**Коли використовувати `ipBlocks` або `remoteIpBlocks`:** Якщо ви використовуєте заголовок X-Forwarded-For HTTP або PROXY Protocol для визначення оригінальної IP-адреси клієнта, тоді слід використовувати `remoteIpBlocks` у вашій `AuthorizationPolicy`. Якщо ви використовуєте `externalTrafficPolicy: Local`, тоді слід використовувати `ipBlocks` у вашій `AuthorizationPolicy`.

|Тип балансувальника навантаження | Джерело IP-адреси клієнта   | `ipBlocks` проти `remoteIpBlocks`
--------------------------------|-----------------------------|---------------------------
| TCP Proxy                     | PROXY Protocol              | `remoteIpBlocks`
| Мережевий                     | адреса джерела пакета       | `ipBlocks`
| HTTP/HTTPS                    | X-Forwarded-For             | `remoteIpBlocks`

* Наступна команда створює політику авторизації `ingress-policy` для вхідного шлюзу Istio. Ця політика встановлює поле `action` на `ALLOW`, щоб дозволити IP-адреси, вказані в `ipBlocks`, доступ до вхідного шлюзу. IP-адреси, яких немає в списку, будуть заблоковані. `ipBlocks` підтримує як окремі IP-адреси, так і CIDR-нотацію.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* Переконайтеся, що запит до вхідного шлюзу відхилено:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* Призначте IP-адресу вашого клієнта змінній env. Якщо ви її не знаєте, ви можете знайти її в журналах Envoy за допомогою наступної команди:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

***ipBlocks:***

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

***ipBlocks:***

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n foo -o name -l gateway.networking.k8s.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ CLIENT_IP=$(kubectl get pods -n foo -o name -l gateway.networking.k8s.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
192.168.10.15
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* Оновіть `ingress-policy`, щоб додати IP-адресу вашого клієнта:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* Переконайтеся, що запит до вхідного шлюзу дозволено:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

* Оновіть політику авторизації `ingress-policy`, встановивши ключ `action` у значення `DENY`, щоб IP-адреси, вказані в `ipBlocks`, не мали доступу до вхідного шлюзу:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        ipBlocks: ["$CLIENT_IP"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        remoteIpBlocks: ["$CLIENT_IP"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

***ipBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        ipBlocks: ["$CLIENT_IP"]
EOF
{{< /text >}}

***remoteIpBlocks:***

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        remoteIpBlocks: ["$CLIENT_IP"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* Переконайтеся, що запит до вхідного шлюзу відхилено:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

* Ви можете скористатися онлайн-проксі-сервісом для доступу до вхідного шлюзу з іншої клієнтської IP-адреси, щоб переконатися, що запит дозволено.

* Якщо ви не отримуєте очікуваних відповідей, перегляньте журнали вхідного шлюзу, які повинні містити інформацію про налагодження RBAC:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system; done
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get pods -n foo -o name -l gateway.networking.k8s.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo; done
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Очищення {#clean-up}

* Видаліть політику авторизації:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete authorizationpolicy ingress-policy -n istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete authorizationpolicy ingress-policy -n foo
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* Видалити простір імен `foo`:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

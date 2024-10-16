---
title: Налаштування топології мережі шлюзу
description: Як налаштувати топологію мережі шлюзу.
weight: 60
keywords: [traffic-management,ingress,gateway]
owner: istio/wg-networking-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

{{< boilerplate gateway-api-support >}}

## Перенаправлення атрибутів зовнішнього клієнта (IP-адреса, інформація про сертифікат) до цільових навантажень {#forwarding-external-client-attributes-ip-address-certificate-info-to-destination-workloads}

Багато застосунків потребують знання IP-адреси клієнта та інформації про сертифікат для коректної роботи. Видатними прикладами є інструменти для журналювання та аудиту, які потребують заповнення IP-адреси клієнта, та засоби безпеки, такі як WAF (брандмауери вебзастосунків), яким потрібна ця інформація для правильного застосування правил. Здатність надавати атрибути клієнта сервісам давно стала основою зворотних проксі. Для передачі цих атрибутів клієнта до цільових навантажень проксі використовують заголовки `X-Forwarded-For` (XFF) та `X-Forwarded-Client-Cert` (XFCC).

Сучасні мережі дуже різноманітні за своєю природою, але підтримка цих атрибутів є необхідністю незалежно від топології мережі. Ця інформація має зберігатися і передаватися, незалежно від того, чи використовуються хмарні балансувальники навантаження, локальні балансувальники, шлюзи, що безпосередньо підключені до інтернету, шлюзи, які обслуговують багато проміжних проксі, або інші топології розгортання.

Хоча Istio надає [шлюз для вхідного трафіку](/docs/tasks/traffic-management/ingress/ingress-control/), враховуючи різноманіття архітектур, згаданих вище, не можна передбачити розумні стандартні значення, які б підтримували правильне перенаправлення атрибутів клієнта до цільових навантажень. Це стає ще важливішим з зростанням популярності багатокластерних моделей розгортання Istio.

Детальніше про `X-Forwarded-For` дивіться у [RFC](https://tools.ietf.org/html/rfc7239) від IETF.

## Налаштування топологій мережі {#configuring-network-topologies}

Конфігурацію заголовків XFF та XFCC можна встановити глобально для всіх робочих навантажень шлюзу через `MeshConfig` або для конкретного шлюзу за допомогою анотації для podʼа. Наприклад, для глобального налаштування під час встановлення або оновлення з використанням ресурсу `IstioOperator`:

{{< text syntax=yaml snip_id=none >}}
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: <VALUE>
        forwardClientCertDetails: <ENUM_VALUE>
{{< /text >}}

Також можна налаштувати ці параметри, додавши анотацію `proxy.istio.io/config` до специфікації podʼа вашого шлюзу Istio:

{{< text syntax=yaml snip_id=none >}}
...
  metadata:
    annotations:
      "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": <VALUE>, "forwardClientCertDetails": <ENUM_VALUE> } }'
{{< /text >}}

### Налаштування заголовків X-Forwarded-For {#configuring-x-forwarded-for-headers}

Застосунки покладаються на зворотні проксі для передачі атрибутів клієнта в запиті, таких як заголовок `X-Forward-For`. Однак через різноманітність топологій мереж, у яких може бути розгорнуто Istio, потрібно встановити значення `numTrustedProxies` на кількість надійних проксі, що розміщені перед шлюзом Istio, щоб правильно витягти IP-адресу клієнта. Це керує значенням, яке заповнюється шлюзом для вхідного трафіку в заголовку `X-Envoy-External-Address`, яке може надійно використовуватися сервісами для доступу до оригінальної IP-адреси клієнта.

Наприклад, якщо у вас є хмарний балансувальник навантаження та зворотний проксі перед вашим шлюзом Istio, встановіть `numTrustedProxies` на значення `2`.

{{< idea >}}
Зверніть увагу, що всі проксі перед шлюзом Istio повинні аналізувати HTTP-трафік і додавати до заголовка `X-Forwarded-For` на кожному кроці. Якщо кількість записів у заголовку `X-Forwarded-For` менша за кількість налаштованих надійних вузлів, Envoy повертається до використання адреси найближчого downstream як надійної адреси клієнта. Будь ласка, зверніться до [документації Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-for), щоб дізнатися, як визначаються заголовки `X-Forwarded-For` та надійні адреси клієнтів.
{{< /idea >}}

#### Приклад використання можливості X-Forwarded-For з httpbin {#example-using-x-forwarded-for-capability-with-httpbin}

1. Виконайте наступну команду, щоб створити файл з назвою `topology.yaml`, де параметр `numTrustedProxies` встановлено на `2`, та встановіть Istio:

    {{< text syntax=bash snip_id=install_num_trusted_proxies_two >}}
    $ cat <<EOF > topology.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          gatewayTopology:
            numTrustedProxies: 2
    EOF
    $ istioctl install -f topology.yaml
    {{< /text >}}

    {{< idea >}}
    Якщо ви раніше встановили шлюз для вхідного трафіку Istio, перезапустіть усі podʼи цього шлюзу після кроку 1.
    {{</ idea >}}

1. Створіть простір імен `httpbin`:

    {{< text syntax=bash snip_id=create_httpbin_namespace >}}
    $ kubectl create namespace httpbin
    namespace/httpbin created
    {{< /text >}}

1. Встановіть мітку `istio-injection` зі значенням `enabled` для інʼєкції sidecar:

    {{< text syntax=bash snip_id=label_httpbin_namespace >}}
    $ kubectl label --overwrite namespace httpbin istio-injection=enabled
    namespace/httpbin labeled
    {{< /text >}}

1. Розгорніть `httpbin` у просторі імен `httpbin`:

    {{< text syntax=bash snip_id=apply_httpbin >}}
    $ kubectl apply -n httpbin -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Розгорніть шлюз, повʼязаний з `httpbin`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=deploy_httpbin_gateway >}}
$ kubectl apply -n httpbin -f @samples/httpbin/httpbin-gateway.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=deploy_httpbin_k8s_gateway >}}
$ kubectl apply -n httpbin -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@
$ kubectl wait --for=condition=programmed gtw -n httpbin httpbin-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6. Встановіть локальну змінну середовища `GATEWAY_URL` на основі IP-адреси шлюзу для вхідного трафіку Istio:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=export_gateway_url >}}
$ export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=export_k8s_gateway_url >}}
$ export GATEWAY_URL=$(kubectl get gateways.gateway.networking.k8s.io httpbin-gateway -n httpbin -ojsonpath='{.status.addresses[0].value}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7. Виконайте наступну команду `curl`, щоб імітувати запит із проксі-адресами в заголовку `X-Forwarded-For`:

    {{< text syntax=bash snip_id=curl_xff_headers >}}
    $ curl -s -H 'X-Forwarded-For: 56.5.6.7, 72.9.5.6, 98.1.2.3' "$GATEWAY_URL/get?show_env=true"
    {
    "args": {
      "show_env": "true"
    },
      "headers": {
      "Accept": ...
      "Host": ...
      "User-Agent": ...
      "X-Envoy-Attempt-Count": ...
      "X-Envoy-External-Address": "72.9.5.6",
      "X-Forwarded-Client-Cert": ...
      "X-Forwarded-For": "56.5.6.7, 72.9.5.6, 98.1.2.3,10.244.0.1",
      "X-Forwarded-Proto": ...
      "X-Request-Id": ...
    },
      "origin": "56.5.6.7, 72.9.5.6, 98.1.2.3,10.244.0.1",
      "url": ...
    }
    {{< /text >}}

{{< tip >}}
У наведеному вище прикладі значення `$GATEWAY_URL` було визначене як 10.244.0.1. Це може відрізнятися у вашому середовищі.
{{< /tip >}}

Наведений вище результат показує заголовки запиту, які отримало навантаження `httpbin`. Коли шлюз Istio отримав цей запит, він встановив заголовок `X-Envoy-External-Address` на передостанню адресу (`numTrustedProxies: 2`) у заголовку `X-Forwarded-For` з вашої команди curl. Крім того, шлюз додає свою IP-адресу до заголовка `X-Forwarded-For`, перш ніж передати його до навантаження `httpbin`.

### Налаштування заголовків X-Forwarded-Client-Cert {#configuring-x-forwarded-client-cert-headers}

Згідно з [документацією Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert) щодо XFCC:

{{< quote >}}
`x-forwarded-client-cert` (XFCC) — це заголовок проксі, який вказує інформацію про сертифікати клієнтів або проксі, через які пройшов запит, йдучи від клієнта до сервера. Проксі може обирати санітизацію/додавання/пересилання заголовка XFCC перед передачею запиту.
{{< /quote >}}

Щоб налаштувати, як обробляються заголовки XFCC, встановіть `forwardClientCertDetails` у вашому `IstioOperator`:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        forwardClientCertDetails: <ENUM_VALUE>
{{< /text >}}

де `ENUM_VALUE` може мати одне з наступних значень:

| `ENUM_VALUE`          | Опис                                                                                                                                                                   |
|-----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `UNDEFINED`           | Поле не задано.                                                                                                                                                         |
| `SANITIZE`            | Не надсилати заголовок XFCC на наступний хоп.                                                                                                                           |
| `FORWARD_ONLY`        | Якщо зʼєднання з клієнтом є mTLS (взаємний TLS), переслати заголовок XFCC у запиті.                                                                                      |
| `APPEND_FORWARD`      | Якщо зʼєднання з клієнтом є mTLS, додати інформацію про сертифікат клієнта до заголовка XFCC і переслати його.                                                           |
| `SANITIZE_SET`        | Якщо зʼєднання з клієнтом є mTLS, скинути заголовок XFCC з інформацією про сертифікат клієнта та надіслати його на наступний хоп. Це стандартне значення для шлюзу. |
| `ALWAYS_FORWARD_ONLY` | Завжди пересилати заголовок XFCC у запиті, незалежно від того, чи є зʼєднання з клієнтом mTLS.                                                                           |

Детальніше дивіться в [документації Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert) для прикладів використання цієї можливості.

## Протокол PROXY {#proxy-protocol}

[Протокол PROXY](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) дозволяє обмінюватися та зберігати атрибути клієнта між TCP-проксі без використання протоколів L7, таких як HTTP, і заголовків `X-Forwarded-For` та `X-Envoy-External-Address`. Він призначений для сценаріїв, де зовнішній TCP-балансувальник навантаження потребує проксіювати TCP-трафік через шлюз Istio до бекенду TCP-сервісу та все ще надавати атрибути клієнта, такі як IP-адреса джерела, до точок доступу TCP-сервісу.

Протокол PROXY можна ввімкнути за допомогою `EnvoyFilter`.

{{< warning >}}
Протокол PROXY підтримується лише для TCP-трафіку, що передається через Envoy. Деталі та важливі зауваження щодо продуктивності дивіться в [документації Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/ip_transparency#proxy-protocol).

Протокол PROXY не слід використовувати для трафіку L7 або для шлюзів Istio, що знаходяться за балансувальниками навантаження L7.
{{< /warning >}}

Якщо ваш зовнішній TCP-балансувальник налаштований на пересилання TCP-трафіку та використання протоколу PROXY, слухач TCP на шлюзі Istio також має бути налаштований на приймання протоколу PROXY. Щоб увімкнути протокол PROXY на всіх TCP-слухачах на шлюзах, встановіть `proxyProtocol` у вашому `IstioOperator`. Наприклад:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        proxyProtocol: {}
{{< /text >}}

Альтернативно, розгорніть шлюз із наступною анотацією podʼа:

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "proxyProtocol": {} }}'
{{< /text >}}

IP-адреса клієнта отримується з протоколу PROXY шлюзом і встановлюється (або додається) в заголовки `X-Forwarded-For` і `X-Envoy-External-Address`. Зверніть увагу, що протокол PROXY є взаємовиключним з заголовками L7, такими як `X-Forwarded-For` та `X-Envoy-External-Address`. Якщо протокол PROXY використовується разом із конфігурацією `gatewayTopology`, перевага надається `numTrustedProxies` та отриманому заголовку `X-Forwarded-For` для визначення довірених адрес клієнтів, а інформація про клієнта протоколу PROXY буде ігнорована.

Зазначте, що наведений приклад лише налаштовує шлюз для приймання вхідного TCP-трафіку з протоколом PROXY — для налаштування Envoy на використання протоколу PROXY при взаємодії з upstream-сервісами дивіться [документацію Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/ip_transparency#proxy-protocol).

---
title: Зовнішня авторизація
description: Показує, як інтегрувати та делегувати контроль доступу до зовнішньої системи авторизації.
weight: 35
keywords: [security,access-control,rbac,authorization,custom, opa, oauth, oauth2-proxy]
owner: istio/wg-security-maintainers
test: yes
---

Це завдання показує, як налаштувати політику авторизації Istio, використовуючи нове значення для [поля action](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action), `CUSTOM`, для делегування контролю доступу зовнішній системі авторизації. Це можна використовувати для інтеграції з [OPA авторизацією](https://www.openpolicyagent.org/docs/envoy), [`oauth2-proxy`](https://github.com/oauth2-proxy/oauth2-proxy), власним зовнішнім сервером авторизації та іншим.

## Перед початком {#before-you-begin}

Перш ніж розпочати це завдання, виконайте наступне:

* Прочитайте [концепції авторизації Istio](/docs/concepts/security/#authorization).

* Дотримуйтесь [посібника з установки Istio](/docs/setup/install/istioctl/) для встановлення Istio.

* Розгорніть тестові робочі навантаження:

    Це завдання використовує два робочі навантаження, `httpbin` та `curl`, обидва розгорнуті в просторі імен `foo`. Обидва робочі навантаження працюють з sidecar проксі Envoy. Розгорніть простір імен `foo` і робочі навантаження за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/curl/curl.yaml@ -n foo
    {{< /text >}}

* Перевірте, чи `curl` може отримати доступ до `httpbin` за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
Якщо ви не бачите очікуваного результату під час виконання завдання, спробуйте ще раз через кілька секунд. Кешування та затримка в поширенні можуть спричинити деяку затримку.
{{< /warning >}}

## Розгортання зовнішнього авторизатора {#deploy-the-external-authorizer}

Спочатку вам потрібно розгорнути зовнішній авторизатор. Для цього просто розгорніть зразок зовнішнього авторизатора в окремому podʼі в межах mesh.

1. Виконайте наступну команду для розгортання демонстраційного зовнішнього авторизатора:

    {{< text bash >}}
    $ kubectl apply -n foo -f {{< github_file >}}/samples/extauthz/ext-authz.yaml
    service/ext-authz created
    deployment.apps/ext-authz created
    {{< /text >}}

1. Переконайтеся, що демонстраційний зовнішній авторизатор працює:

    {{< text bash >}}
    $ kubectl logs "$(kubectl get pod -l app=ext-authz -n foo -o jsonpath={.items..metadata.name})" -n foo -c ext-authz
    2021/01/07 22:55:47 Starting HTTP server at [::]:8000
    2021/01/07 22:55:47 Starting gRPC server at [::]:9000
    {{< /text >}}

Альтернативно, ви також можете розгорнути зовнішній авторизатор як окремий контейнер в тому ж podʼі застосунку, якому потрібна зовнішня авторизація, або навіть розгорнути його поза mesh. У будь-якому випадку, вам також потрібно створити ресурс service entry для реєстрації сервісу в mesh та забезпечити його доступність для проксі.

Нижче наведено приклад service entry для зовнішнього авторизатора, розгорнутого як окремий контейнер у тому ж podʼі застосунку, якому потрібна зовнішня авторизація.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-authz-grpc-local
spec:
  hosts:
  - "external-authz-grpc.local" # Імʼя сервісу, яке буде використовуватися у провайдері розширення в конфігурації mesh.
  endpoints:
  - address: "127.0.0.1"
  ports:
  - name: grpc
    number: 9191 # Номер порту, який буде використовуватися у провайдері розширення в конфігурації mesh.
    protocol: GRPC
  resolution: STATIC
{{< /text >}}

## Визначення зовнішнього авторизатора {#define-the-external-authorizer}

Щоб використовувати дію `CUSTOM` в політиці авторизації, необхідно визначити зовнішній авторизатор, який дозволено використовувати в mesh. Це наразі визначено в [провайдері розширення](https://github.com/istio/api/blob/a205c627e4b955302bbb77dd837c8548e89e6e64/mesh/v1alpha1/config.proto#L534) в конфігурації mesh.

На цей момент єдиний підтримуваний тип провайдера розширення — це провайдер [Envoy `ext_authz`](https://www.envoyproxy.io/docs/envoy/v1.16.2/intro/arch_overview/security/ext_authz_filter). Зовнішній авторизатор повинен реалізовувати відповідний API перевірки Envoy `ext_authz`.

У цьому завданні ви використовуватимете [зразок зовнішнього авторизатора]({{< github_tree >}}/samples/extauthz), який дозволяє запити з заголовком `x-ext-authz: allow`.

1. Відредагуйте конфігурацію mesh за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl edit configmap istio -n istio-system
    {{< /text >}}

2. В редакторі додайте визначення провайдерів розширень, як показано нижче:

    Наведений вміст визначає двох зовнішніх провайдерів `sample-ext-authz-grpc` та `sample-ext-authz-http`, що використовують той самий сервіс `ext-authz.foo.svc.cluster.local`. Сервіс реалізує як HTTP, так і gRPC API перевірки, як визначено фільтром Envoy `ext_authz`. Ви розгорнете цей сервіс на наступному етапі.

    {{< text yaml >}}
    data:
      mesh: |-
        # Додайте наступний вміст для визначення зовнішніх авторизаторів.
        extensionProviders:
        - name: "sample-ext-authz-grpc"
          envoyExtAuthzGrpc:
            service: "ext-authz.foo.svc.cluster.local"
            port: "9000"
        - name: "sample-ext-authz-http"
          envoyExtAuthzHttp:
            service: "ext-authz.foo.svc.cluster.local"
            port: "8000"
            includeRequestHeadersInCheck: ["x-ext-authz"]
    {{< /text >}}

    Альтернативно, ви можете змінити провайдера розширення для керування поведінкою фільтра `ext_authz` в таких аспектах, як які заголовки передавати зовнішньому авторизатору, які заголовки передавати до бекенду застосунку, статус, який слід повертати
    у разі помилки, та інше. Наприклад, наступне визначає провайдера розширення, який може використовуватися з [`oauth2-proxy`](https://github.com/oauth2-proxy/oauth2-proxy):

    {{< text yaml >}}
    data:
      mesh: |-
        extensionProviders:
        - name: "oauth2-proxy"
          envoyExtAuthzHttp:
            service: "oauth2-proxy.foo.svc.cluster.local"
            port: "4180" # Стандартний порт, що використовується oauth2-proxy.
            includeRequestHeadersInCheck: ["authorization", "cookie"] # заголовки, що передаються oauth2-proxy у запиті перевірки.
            headersToUpstreamOnAllow: ["authorization", "path", "x-auth-request-user", "x-auth-request-email", "x-auth-request-access-token"] # заголовки, що передаються на бекенд застосунку, коли запит дозволений.
            headersToDownstreamOnAllow: ["set-cookie"] # заголовки, що повертаються клієнту, коли запит дозволений.
            headersToDownstreamOnDeny: ["content-type", "set-cookie"] # заголовки, що повертаються клієнту, коли запит відхилений.
    {{< /text >}}

## Увімкнення зовнішнього авторизатора {#enable-with-external-authorization}

Зовнішній авторизатор тепер готовий до використання політикою авторизації.

1. Увімкніть зовнішню авторизацію за допомогою наступної команди:

    Наступна команда застосовує політику авторизації зі значенням дії `CUSTOM` для робочого навантаження `httpbin`. Політика вмикає зовнішню авторизацію для запитів до шляху `/headers` з використанням зовнішнього авторизатора, визначеного командою `sample-ext-authz-grpc`.

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: ext-authz
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: CUSTOM
      provider:
        # Імʼя провайдера має збігатися з імʼям провайдера, визначеним у конфігурації mesh.
        # Ви також можете замінити його на sample-ext-authz-http, щоб протестувати визначення іншого зовнішнього авторизатора.
        name: sample-ext-authz-grpc
      rules:
      # Правила визначають, коли запускати зовнішній авторизатор.
      - to:
        - operation:
            paths: ["/headers"]
    EOF
    {{< /text >}}

    У процесі виконання запити до шляху `/headers` навантаження `httpbin` будуть призупинені фільтром `ext_authz`, і буде надіслано запит на перевірку до зовнішнього авторизатора, щоб визначити, чи слід дозволити, чи відхилити запит.

1. Перевірте, що запит до шляху `/headers` з заголовком `x-ext-authz: deny` відхилено демонстраційним сервером `ext_authz`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -H "x-ext-authz: deny" -s
    denied by ext_authz for not found header `x-ext-authz: allow` in the request
    {{< /text >}}

1. Перевірте, що запит до шляху `/headers` з заголовком `x-ext-authz: allow` дозволено демонстраційним сервером `ext_authz`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -H "x-ext-authz: allow" -s | jq '.headers'
    ...
      "X-Ext-Authz-Check-Result": [
        "allowed"
      ],
    ...
    {{< /text >}}

1. Перевірте, що запит до шляху `/ip` є дозволеним і не викликає зовнішню авторизацію:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/ip" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

2. Перевірте журнал демонстраційного сервера `ext_authz`, щоб переконатися, що він був викликаний двічі (для двох запитів). Перший запит було дозволено, а другий — відхилено:

    {{< text bash >}}
    $ kubectl logs "$(kubectl get pod -l app=ext-authz -n foo -o jsonpath={.items..metadata.name})" -n foo -c ext-authz
    2021/01/07 22:55:47 Starting HTTP server at [::]:8000
    2021/01/07 22:55:47 Starting gRPC server at [::]:9000
    2021/01/08 03:25:00 [gRPCv3][denied]: httpbin.foo:8000/headers, attributes: source:{address:{socket_address:{address:"10.44.0.22"  port_value:52088}}  principal:"spiffe://cluster.local/ns/foo/sa/curl"}  destination:{address:{socket_address:{address:"10.44.3.30"  port_value:80}}  principal:"spiffe://cluster.local/ns/foo/sa/httpbin"}  request:{time:{seconds:1610076306  nanos:473835000}  http:{id:"13869142855783664817"  method:"GET"  headers:{key:":authority"  value:"httpbin.foo:8000"}  headers:{key:":method"  value:"GET"}  headers:{key:":path"  value:"/headers"}  headers:{key:"accept"  value:"*/*"}  headers:{key:"content-length"  value:"0"}  headers:{key:"user-agent"  value:"curl/7.74.0-DEV"}  headers:{key:"x-b3-sampled"  value:"1"}  headers:{key:"x-b3-spanid"  value:"377ba0cdc2334270"}  headers:{key:"x-b3-traceid"  value:"635187cb20d92f62377ba0cdc2334270"}  headers:{key:"x-envoy-attempt-count"  value:"1"}  headers:{key:"x-ext-authz"  value:"deny"}  headers:{key:"x-forwarded-client-cert"  value:"By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=dd14782fa2f439724d271dbed846ef843ff40d3932b615da650d028db655fc8d;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/curl"}  headers:{key:"x-forwarded-proto"  value:"http"}  headers:{key:"x-request-id"  value:"9609691a-4e9b-9545-ac71-3889bc2dffb0"}  path:"/headers"  host:"httpbin.foo:8000"  protocol:"HTTP/1.1"}}  metadata_context:{}
    2021/01/08 03:25:06 [gRPCv3][allowed]: httpbin.foo:8000/headers, attributes: source:{address:{socket_address:{address:"10.44.0.22"  port_value:52184}}  principal:"spiffe://cluster.local/ns/foo/sa/curl"}  destination:{address:{socket_address:{address:"10.44.3.30"  port_value:80}}  principal:"spiffe://cluster.local/ns/foo/sa/httpbin"}  request:{time:{seconds:1610076300  nanos:925912000}  http:{id:"17995949296433813435"  method:"GET"  headers:{key:":authority"  value:"httpbin.foo:8000"}  headers:{key:":method"  value:"GET"}  headers:{key:":path"  value:"/headers"}  headers:{key:"accept"  value:"*/*"}  headers:{key:"content-length"  value:"0"}  headers:{key:"user-agent"  value:"curl/7.74.0-DEV"}  headers:{key:"x-b3-sampled"  value:"1"}  headers:{key:"x-b3-spanid"  value:"a66b5470e922fa80"}  headers:{key:"x-b3-traceid"  value:"300c2f2b90a618c8a66b5470e922fa80"}  headers:{key:"x-envoy-attempt-count"  value:"1"}  headers:{key:"x-ext-authz"  value:"allow"}  headers:{key:"x-forwarded-client-cert"  value:"By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=dd14782fa2f439724d271dbed846ef843ff40d3932b615da650d028db655fc8d;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/curl"}  headers:{key:"x-forwarded-proto"  value:"http"}  headers:{key:"x-request-id"  value:"2b62daf1-00b9-97d9-91b8-ba6194ef58a4"}  path:"/headers"  host:"httpbin.foo:8000"  protocol:"HTTP/1.1"}}  metadata_context:{}
    {{< /text >}}

    З журналу також видно, що mTLS увімкнено для з'єднання між фільтром `ext-authz` і демонстраційним сервером `ext-authz`, оскільки принципала джерела заповнено значенням `spiffe://cluster.local/ns/foo/sa/curl`.

    Тепер ви можете застосувати іншу політику авторизації для демонстраційного сервера `ext-authz`, щоб контролювати, кому дозволено доступ до нього.

## Очищення {#clean-up}

1. Видаліть простір імен `foo` з вашої конфігурації:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

1. Видаліть визначення постачальника послуг розширення з конфігурації mesh.

## Очікувані результати {#performance-expectations}

Дивіться [порівняльний аналіз ефективності](https://github.com/istio/tools/tree/master/perf/benchmark/configs/istio/ext_authz).

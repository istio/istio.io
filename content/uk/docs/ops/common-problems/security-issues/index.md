---
title: Проблеми безпеки
description: Техніки для вирішення поширених проблем з аутентифікацією, авторизацією та загальною безпекою в Istio.
force_inline_toc: true
weight: 20
keywords: [security,citadel]
aliases:
    - /uk/help/ops/security/repairing-citadel
    - /uk/help/ops/troubleshooting/repairing-citadel
    - /uk/docs/ops/troubleshooting/repairing-citadel
owner: istio/wg-security-maintainers
test: n/a
---

## Неправильна автентифікація кінцевого користувача {#end-user-authentication-fails}

В Istio ви можете включити автентифікацію для кінцевих користувачів через [політики автентифікації запитів](/docs/tasks/security/authentication/authn-policy/#end-user-authentication). Дотримуйтесь цих кроків для усунення несправностей у специфікації політики.

1. Якщо `jwksUri` не вказано, переконайтеся, що видавець JWT має формат url, і що `url + /.well-known/openid-configuration` можна відкрити в оглядачі; наприклад, якщо видавець JWT — `https://accounts.google.com`, переконайтеся, що `https://accounts.google.com/.well-known/openid-configuration` є дійсним url і його можна відкрити в браузері.

    {{< text yaml >}}
    apiVersion: security.istio.io/v1
    kind: RequestAuthentication
    metadata:
      name: "example-3"
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
    {{< /text >}}

1. Якщо токен JWT розміщено в заголовку Authorization у http запитах, переконайтеся, що токен JWT є дійсним (не прострочений тощо). Поля в токені JWT можна декодувати за допомогою онлайн інструментів для парсингу JWT, наприклад, [jwt.io](https://jwt.io/).

1. Перевірте конфігурацію проксі Envoy для цільового навантаження, використовуючи команду `istioctl proxy-config`.

    З застосованою вище політикою використовуйте наступну команду для перевірки конфігурації `listener` на вхідному порту `80`. Ви повинні побачити фільтр `envoy.filters.http.jwt_authn` з налаштуваннями, що відповідають видавцю та JWKS, як зазначено в політиці.

    {{< text bash >}}
    $ POD=$(kubectl get pod -l app=httpbin -n foo -o jsonpath={.items..metadata.name})
    $ istioctl proxy-config listener ${POD} -n foo --port 80 --type HTTP -o json
    <redacted>
                                {
                                    "name": "envoy.filters.http.jwt_authn",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.config.filter.http.jwt_authn.v2alpha.JwtAuthentication",
                                        "providers": {
                                            "origins-0": {
                                                "issuer": "testing@secure.istio.io",
                                                "localJwks": {
                                                    "inlineString": "*redacted*"
                                                },
                                                "payloadInMetadata": "testing@secure.istio.io"
                                            }
                                        },
                                        "rules": [
                                            {
                                                "match": {
                                                    "prefix": "/"
                                                },
                                                "requires": {
                                                    "requiresAny": {
                                                        "requirements": [
                                                            {
                                                                "providerName": "origins-0"
                                                            },
                                                            {
                                                                "allowMissing": {}
                                                            }
                                                        ]
                                                    }
                                                }
                                            }
                                        ]
                                    }
                                },
    <redacted>
    {{< /text >}}

## Авторизація занадто обмежувальна або надто ліберальна {#authorization-is-too-restrictive-or-permissive}

### Переконайтесь, що в YAML файлі політики немає помилок {#make-sure-there-are-no-typos-in-the-policy-yaml-file}

Одна з поширених помилок — це випадкове вказання кількох елементів у YAML. Розглянемо наступну політику як приклад:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: example
  namespace: foo
spec:
  action: ALLOW
  rules:
  - to:
    - operation:
        paths:
        - /foo
  - from:
    - source:
        namespaces:
        - foo
{{< /text >}}

Ви можете очікувати, що політика дозволить запити, якщо шлях `/foo` **і** простір імен джерела `foo`. Однак, насправді політика дозволяє запити, якщо шлях `/foo` **або** простір імен джерела `foo`, що є більш ліберальним.

У синтаксисі YAML, `-` перед `from:` означає, що це новий елемент у списку. Це створює 2 правила в політиці замість 1. В політиці авторизації кілька правил мають семантику `OR`.

Щоб виправити проблему, просто видаліть зайвий `-`, щоб політика мала тільки 1 правило, яке дозволяє запити, якщо шлях `/foo` **і** простір імен джерела `foo`, що є більш обмежувальним.

### Переконайтесь, що ви НЕ використовуєте тільки HTTP-поля на TCP портах {#make-sure-you-are-not-using-http-only-fields-on-tcp-ports}

Політика авторизації буде більш обмежувальною, оскільки тільки HTTP-поля (наприклад, `host`, `path`, `headers`, JWT тощо) не існують у чистих TCP зʼєднаннях.

У випадку політики `ALLOW` ці поля ніколи не збігаються. У випадку дій `DENY` і `CUSTOM` ці поля вважаються завжди збігаються. Остаточний ефект — це більш обмежувальна політика, яка може спричинити несподівані відмови.

Перевірте визначення сервісу Kubernetes, щоб переконатися, що порт [названий правильним протоколом](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection). Якщо ви використовуєте тільки HTTP-поля на порту, переконайтесь, що імʼя порту має префікс `http-`.

### Переконайтесь, що політика застосована до правильних цілей {#make-sure-the-policy-is-applied-to-the-correct-target}

Перевірте селектор навантаження і простір імен, щоб підтвердити, що вона застосована до правильних цілей. Ви можете визначити діючу політику авторизації, запустивши `istioctl x authz check POD-NAME.POD-NAMESPACE`.

### Зверніть увагу на дію, зазначену в політиці {#pay-attention-to-the-action-specified-in-the-policy}

- Якщо не вказано, стандартна політика використовує дію `ALLOW`.

- Коли навантаження має кілька дій (`CUSTOM`, `ALLOW` і `DENY`), застосованих одночасно, всі дії повинні бути задоволені, щоб дозволити запит. Іншими словами, запит відхиляється, якщо будь-яка з дій відмовляє, і дозволяється тільки якщо всі дії дозволяють.

- Дія `AUDIT` не забезпечує контроль доступу і не відхиляє запит у будь-яких випадках.

Читайте [неявне включення авторизації](/docs/concepts/security/#implicit-enablement) для отримання докладної інформації про порядок оцінки.

## Переконайтесь, що Istiod приймає політики {#ensure-istiod-accepts-the-policies}

Istiod конвертує та розподіляє ваші політики авторизації до проксі. Наступні кроки допоможуть переконатися, що Istiod працює як очікується:

1. Запустіть наступну команду для включення журналювання налагодження в istiod:

    {{< text bash >}}
    $ istioctl admin log --level authorization:debug
    {{< /text >}}

2. Отримайте журнал Istiod за допомогою наступної команди:

    {{< tip >}}
    Вам, ймовірно, потрібно спочатку видалити, а потім повторно застосувати ваші політики авторизації, щоб згенерувати налагоджувальний вивід для цих політик.
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l app=istiod -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system
    {{< /text >}}

3. Перевірте вивід і переконайтеся, що помилок немає. Наприклад, ви можете побачити щось подібне до наступного:

    {{< text plain >}}
    2021-04-23T20:53:29.507314Z info ads Push debounce stable[31] 1: 100.981865ms since last change, 100.981653ms since last push, full=true
    2021-04-23T20:53:29.507641Z info ads XDS: Pushing:2021-04-23T20:53:29Z/23 Services:15 ConnectedEndpoints:2  Version:2021-04-23T20:53:29Z/23
    2021-04-23T20:53:29.507911Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.508077Z debug authorization Processed authorization policy for curl-557747455f-6dxbl.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.508128Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 1 DENY actions, 0 ALLOW actions, 0 AUDIT actions
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on HTTP filter chain successfully
        * built 1 HTTP filters for DENY action
        * added 1 HTTP filters to filter chain 0
        * added 1 HTTP filters to filter chain 1
    2021-04-23T20:53:29.508158Z debug authorization Processed authorization policy for curl-557747455f-6dxbl.foo with details:
        * found 0 DENY actions, 0 ALLOW actions, 0 AUDIT actions
    2021-04-23T20:53:29.509097Z debug authorization Processed authorization policy for curl-557747455f-6dxbl.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.509167Z debug authorization Processed authorization policy for curl-557747455f-6dxbl.foo with details:
        * found 0 DENY actions, 0 ALLOW actions, 0 AUDIT actions
    2021-04-23T20:53:29.509501Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 0 CUSTOM actions
    2021-04-23T20:53:29.509652Z debug authorization Processed authorization policy for httpbin-74fb669cc6-lpscm.foo with details:
        * found 1 DENY actions, 0 ALLOW actions, 0 AUDIT actions
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on HTTP filter chain successfully
        * built 1 HTTP filters for DENY action
        * added 1 HTTP filters to filter chain 0
        * added 1 HTTP filters to filter chain 1
        * generated config from rule ns[foo]-policy[deny-path-headers]-rule[0] on TCP filter chain successfully
        * built 1 TCP filters for DENY action
        * added 1 TCP filters to filter chain 2
        * added 1 TCP filters to filter chain 3
        * added 1 TCP filters to filter chain 4
    2021-04-23T20:53:29.510903Z info ads LDS: PUSH for node:curl-557747455f-6dxbl.foo resources:18 size:85.0kB
    2021-04-23T20:53:29.511487Z info ads LDS: PUSH for node:httpbin-74fb669cc6-lpscm.foo resources:18 size:86.4kB
    {{< /text >}}

    Це показує, що Istiod згенерував:

    - Конфігурацію HTTP-фільтра з політикою `ns[foo]-policy[deny-path-headers]-rule[0]` для навантаження `httpbin-74fb669cc6-lpscm.foo`.

    - Конфігурацію TCP-фільтра з політикою `ns[foo]-policy[deny-path-headers]-rule[0]` для навантаження `httpbin-74fb669cc6-lpscm.foo`.

## Переконайтесь, що Istiod коректно розподіляє політики до проксі {#ensure-istiod-distributes-policies-to-proxies-correctly}

Istiod розподіляє політики авторизації до проксі. Наступні кроки допоможуть вам переконатися, що Istiod працює як очікується:

{{< tip >}}
Команда нижче припускає, що ви розгорнули `httpbin`. Вам слід замінити `"-l app=httpbin"` на ваш фактичний pod, якщо ви не використовуєте `httpbin`.
{{< /tip >}}

1. Запустіть наступну команду, щоб отримати дамп конфігурації проксі для навантаження `httpbin`:

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- pilot-agent request GET config_dump
    {{< /text >}}

1. Перевірте журнал і переконайтеся, що:

    - Журнал містить фільтр `envoy.filters.http.rbac` для забезпечення політики авторизації на кожен вхідний запит.
    - Istio оновлює фільтр відповідно після оновлення вашої політики авторизації.

1. Наступний вивід означає, що проксі `httpbin` активував фільтр `envoy.filters.http.rbac` з правилами, які забороняють будь-кому доступ до шляху `/headers`.

    {{< text plain >}}
    {
     "name": "envoy.filters.http.rbac",
     "typed_config": {
      "@type": "type.googleapis.com/envoy.extensions.filters.http.rbac.v3.RBAC",
      "rules": {
       "action": "DENY",
       "policies": {
        "ns[foo]-policy[deny-path-headers]-rule[0]": {
         "permissions": [
          {
           "and_rules": {
            "rules": [
             {
              "or_rules": {
               "rules": [
                {
                 "url_path": {
                  "path": {
                   "exact": "/headers"
                  }
                 }
                }
               ]
              }
             }
            ]
           }
          }
         ],
         "principals": [
          {
           "and_ids": {
            "ids": [
             {
              "any": true
             }
            ]
           }
          }
         ]
        }
       }
      },
      "shadow_rules_stat_prefix": "istio_dry_run_allow_"
     }
    },
    {{< /text >}}

## Переконайтесь, що проксі коректно застосовують політики {#ensure-proxies-enforce-policies-correctly}

Проксі зрештою застосовують політики авторизації. Наступні кроки допоможуть вам переконатися, що проксі працює як очікується:

{{< tip >}}
Команда нижче припускає, що ви розгорнули `httpbin`. Вам слід замінити `"-l app=httpbin"` на ваш фактичний pod, якщо ви не використовуєте `httpbin`.
{{< /tip >}}

1. Увімкніть журналювання налагодження авторизації в проксі за допомогою наступної команди:

    {{< text bash >}}
    $ istioctl proxy-config log deploy/httpbin --level "rbac:debug"
    {{< /text >}}

1. Перевірте, чи ви бачите наступний вихід:

    {{< text plain >}}
    active loggers:
      ... ...
      rbac: debug
      ... ...
    {{< /text >}}

1. Надішліть кілька запитів до навантаження `httpbin`, щоб згенерувати журнали.

1. Виведіть журнали проксі за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=httpbin -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

1. Перевірте вивід і переконайтеся, що:

    - У виводі журналу показано або `enforced allowed`, або `enforced denied`, залежно від того, чи запит був дозволений або відхилений відповідно.

    - Ваша політика авторизації очікує дані, отримані з запиту.

1. Наступний приклад виводу для запиту на шляху `/httpbin`:

    {{< text plain >}}
    ...
    2021-04-23T20:43:18.552857Z debug envoy rbac checking request: requestedServerName: outbound_.8000_._.httpbin.foo.svc.cluster.local, sourceIP: 10.44.3.13:46180, directRemoteIP: 10.44.3.13:46180, remoteIP: 10.44.3.13:46180,localAddress: 10.44.1.18:80, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/foo/sa/curl, dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin:8000'
    ':path', '/headers'
    ':method', 'GET'
    ':scheme', 'http'
    'user-agent', 'curl/7.76.1-DEV'
    'accept', '*/*'
    'x-forwarded-proto', 'http'
    'x-request-id', '672c9166-738c-4865-b541-128259cc65e5'
    'x-envoy-attempt-count', '1'
    'x-b3-traceid', '8a124905edf4291a21df326729b264e9'
    'x-b3-spanid', '21df326729b264e9'
    'x-b3-sampled', '0'
    'x-forwarded-client-cert', 'By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=d64cd6750a3af8685defbbe4dd8c467ebe80f6be4bfe9ca718e81cd94129fc1d;Subject="";URI=spiffe://cluster.local/ns/foo/sa/curl'
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
        fields {
          key: "source.namespace"
          value {
            string_value: "foo"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
        fields {
          key: "source.user"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
      }
    }

    2021-04-23T20:43:18.552910Z debug envoy rbac enforced denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
    ...
    {{< /text >}}

    Запис `enforced denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]` означає, що запит відхилено політикою `ns[foo]-policy[deny-path-headers]-rule[0]`.

1. Наступний приклад виводу для політики авторизації у [режимі dry-run](/docs/tasks/security/authorization/authz-dry-run):

    {{< text plain >}}
    ...
    2021-04-23T20:59:11.838468Z debug envoy rbac checking request: requestedServerName: outbound_.8000_._.httpbin.foo.svc.cluster.local, sourceIP: 10.44.3.13:49826, directRemoteIP: 10.44.3.13:49826, remoteIP: 10.44.3.13:49826,localAddress: 10.44.1.18:80, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/foo/sa/curl, dnsSanPeerCertificate: , subjectPeerCertificate: , headers: ':authority', 'httpbin:8000'
    ':path', '/headers'
    ':method', 'GET'
    ':scheme', 'http'
    'user-agent', 'curl/7.76.1-DEV'
    'accept', '*/*'
    'x-forwarded-proto', 'http'
    'x-request-id', 'e7b2fdb0-d2ea-4782-987c-7845939e6313'
    'x-envoy-attempt-count', '1'
    'x-b3-traceid', '696607fc4382b50017c1f7017054c751'
    'x-b3-spanid', '17c1f7017054c751'
    'x-b3-sampled', '0'
    'x-forwarded-client-cert', 'By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=d64cd6750a3af8685defbbe4dd8c467ebe80f6be4bfe9ca718e81cd94129fc1d;Subject="";URI=spiffe://cluster.local/ns/foo/sa/curl'
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
        fields {
          key: "source.namespace"
          value {
            string_value: "foo"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
        fields {
          key: "source.user"
          value {
            string_value: "cluster.local/ns/foo/sa/curl"
          }
        }
      }
    }

    2021-04-23T20:59:11.838529Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
    2021-04-23T20:59:11.838538Z debug envoy rbac no engine, allowed by default
    ...
    {{< /text >}}

    Запис `shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]` означає, що запит буде відхилений політикою **dry-run** `ns[foo]-policy[deny-path-headers]-rule[0]`.

    Запис `no engine, allowed by default` означає, що запит фактично дозволений, оскільки політика dry-run є єдиною політикою на навантаженні.

## Помилки з ключами та сертифікатами {#keys-and-certificates-errors}

Якщо ви підозрюєте, що деякі з ключів і/або сертифікатів, що використовуються Istio, є некоректними, ви можете перевірити вміст з будь-якого podʼа:

{{< text bash >}}
$ istioctl proxy-config secret curl-8f795f47d-4s4t7
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           138092480869518152837211547060273851586     2020-11-11T16:39:48Z     2020-11-10T16:39:48Z
ROOTCA            CA             ACTIVE     true           288553090258624301170355571152070165215     2030-11-08T16:34:52Z     2020-11-10T16:34:52Z
{{< /text >}}

Передавши прапорець `-o json`, ви можете передати повний вміст сертифіката до `openssl` для аналізу його вмісту:

{{< text bash >}}
$ istioctl proxy-config secret curl-8f795f47d-4s4t7 -o json | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            99:59:6b:a2:5a:f4:20:f4:03:d7:f0:bc:59:f5:d8:40
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = k8s.cluster.local
        Validity
            Not Before: Jun  4 20:38:20 2018 GMT
            Not After : Sep  2 20:38:20 2018 GMT
...
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/my-ns/sa/my-sa
...
{{< /text >}}

Переконайтесь, що показаний сертифікат містить дійсну інформацію. Зокрема, поле `Subject Alternative Name` повинно бути `URI:spiffe://cluster.local/ns/my-ns/sa/my-sa`.

## Помилки Mutual TLS {#mutual-tls-errors}

Якщо ви підозрюєте проблеми з mutual TLS, спочатку переконайтесь, що istiod працює коректно, а по-друге, що [ключі та сертифікати доставляються](#keys-and-certificates-errors) до sidecarʼів правильно.

Якщо все здається в порядку, наступний крок — перевірити, чи застосована правильна [політика автентифікації](/docs/tasks/security/authentication/authn-policy/) і чи є правильні правила призначення.

Якщо ви підозрюєте, що sidecar з боку клієнта може неправильно надсилати трафік mutual TLS або plaintext, перевірте [панель Grafana Workload](/docs/ops/integrations/grafana/). Чи вихідні запити анотовані, чи використовується mTLS. Після перевірки, якщо ви вважаєте, що sidecar з боку клієнта поводиться неналежно, повідомте про проблему на GitHub.

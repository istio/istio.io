---
title: Налагодження Envoy і Istiod
description: Описує інструменти та методи діагностики проблем із конфігурацією Envoy, повʼязаних з управлінням трафіком.
weight: 20
keywords: [debug,proxy,status,config,pilot,envoy]
aliases:
    - /uk/help/ops/traffic-management/proxy-cmd
    - /uk/help/ops/misc
    - /uk/help/ops/troubleshooting/proxy-cmd
owner: istio/wg-user-experience-maintainers
test: no
---

Istio надає дві дуже корисні команди для діагностики проблем із конфігурацією управління трафіком: команди [`proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status) та [`proxy-config`](/docs/reference/commands/istioctl/#istioctl-proxy-config). Команда `proxy-status` дозволяє отримати огляд вашої мережі та визначити проксі, що спричиняє проблему. Потім команду `proxy-config` можна використовувати для перевірки конфігурації Envoy та діагностики проблеми.

Якщо ви хочете спробувати команди, описані нижче, ви можете:

* Мати кластер Kubernetes з встановленим Istio і Bookinfo (як описано в [кроках установки](/docs/setup/getting-started/) і [кроках установки Bookinfo](/docs/examples/bookinfo/#deploying-the-application)).

АБО

* Використовувати подібні команди для свого застосунку, що працює в кластері Kubernetes.

## Отримання огляду вашої мережі {#get-an-overview-of-your-mesh}

Команда `proxy-status` дозволяє отримати загальну картину вашої мережі. Якщо ви підозрюєте, що один з ваших sidecar-проксі не отримує конфігурацію або знаходиться поза синхронізацією, команда `proxy-status` це покаже.

{{< text bash >}}
$ istioctl proxy-status
NAME                                                   CDS        LDS        EDS        RDS          ISTIOD                      VERSION
details-v1-558b8b4b76-qzqsg.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
istio-ingressgateway-66c994c45c-cmb7x.istio-system     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-6cf8d4f9cb-wm7x6     1.7.0
productpage-v1-6987489c74-nc7tj.default                SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
prometheus-7bdc59c94d-hcp59.istio-system               SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
ratings-v1-7dc98c7588-5m6xj.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
reviews-v1-7f99cc4496-rtsqn.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
reviews-v2-7d79d5bd5d-tj6kf.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
reviews-v3-7dbcdcbc56-t8wrx.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
{{< /text >}}

Якщо якийсь проксі відсутній у цьому списку, це означає, що він наразі не підключений до екземпляру Istiod, і тому не отримує конфігурації.

* `SYNCED` означає, що Envoy підтвердив отримання останньої конфігурації, надісланої {{< gloss >}}Istiod{{< /gloss >}}.
* `NOT SENT` означає, що Istiod нічого не надсилав Envoy. Зазвичай це тому, що Istiod не має, що надіслати.
* `STALE` означає, що Istiod надіслав оновлення Envoy, але не отримав підтвердження. Це зазвичай свідчить про проблеми з мережею між Envoy та Istiod або помилки у самому Istio.

## Отримання відмінностей між Envoy та Istiod {#retrieve-diffs-between-envoy-and-istiod}

Команда `proxy-status` також може використовуватися для отримання відмінностей між конфігурацією, завантаженою Envoy, та конфігурацією, яку надсилає Istiod, вказавши ідентифікатор проксі. Це допоможе визначити, що саме знаходиться поза синхронізацією та де може бути проблема.

{{< text bash json >}}
$ istioctl proxy-status details-v1-6dcc6fbb9d-wsjz4.default
--- Istiod Clusters
+++ Envoy Clusters
@@ -374,36 +374,14 @@
             "edsClusterConfig": {
                "edsConfig": {
                   "ads": {

                   }
                },
                "serviceName": "outbound|443||public-cr0bdc785ce3f14722918080a97e1f26be-alb1.kube-system.svc.cluster.local"
-            },
-            "connectTimeout": "1.000s",
-            "circuitBreakers": {
-               "thresholds": [
-                  {
-
-                  }
-               ]
-            }
-         }
-      },
-      {
-         "cluster": {
-            "name": "outbound|53||kube-dns.kube-system.svc.cluster.local",
-            "type": "EDS",
-            "edsClusterConfig": {
-               "edsConfig": {
-                  "ads": {
-
-                  }
-               },
-               "serviceName": "outbound|53||kube-dns.kube-system.svc.cluster.local"
             },
             "connectTimeout": "1.000s",
             "circuitBreakers": {
                "thresholds": [
                   {

                   }

Listeners Match
Routes Match (RDS last loaded at Tue, 04 Aug 2020 11:52:54 IST)
{{< /text >}}

Тут ви можете побачити, що listeners і routes збігаються, але кластери не синхронізовані.

## Глибоке занурення у конфігурацію Envoy {#deep-dive-into-envoy-configuration}

Команда `proxy-config` використовується для перевірки того, як налаштований конкретний екземпляр Envoy. Це дозволяє точно визначити проблеми, які неможливо виявити, просто переглядаючи конфігурацію Istio та власні ресурси. Щоб отримати базовий огляд кластерів, listeners або routes для конкретного podʼа, використовуйте наступну команду (замінюючи `clusters` на `listeners` або `routes`, якщо це необхідно):

{{< text bash >}}
$ istioctl proxy-config clusters <pod_name>
{{< /text >}}

Ця команда виведе список кластерів, які використовуються Envoy у зазначеному podʼі, що допоможе виявити відмінності або проблеми, які можуть спричиняти несправності у маршрутизації трафіку або інших аспектах роботи проксі.

{{< text bash >}}
$ istioctl proxy-config cluster -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
SERVICE FQDN                                                               PORT      SUBSET     DIRECTION     TYPE           DESTINATION RULE
BlackHoleCluster                                                           -         -          -             STATIC
agent                                                                      -         -          -             STATIC
details.default.svc.cluster.local                                          9080      -          outbound      EDS            details.default
istio-ingressgateway.istio-system.svc.cluster.local                        80        -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local                        443       -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local                        15021     -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local                        15443     -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      443       -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      853       -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      15010     -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      15012     -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      15014     -          outbound      EDS
kube-dns.kube-system.svc.cluster.local                                     53        -          outbound      EDS
kube-dns.kube-system.svc.cluster.local                                     9153      -          outbound      EDS
kubernetes.default.svc.cluster.local                                       443       -          outbound      EDS
...
productpage.default.svc.cluster.local                                      9080      -          outbound      EDS
prometheus_stats                                                           -         -          -             STATIC
ratings.default.svc.cluster.local                                          9080      -          outbound      EDS
reviews.default.svc.cluster.local                                          9080      -          outbound      EDS
sds-grpc                                                                   -         -          -             STATIC
xds-grpc                                                                   -         -          -             STRICT_DNS
zipkin                                                                     -         -          -             STRICT_DNS
{{< /text >}}

Щоб налагодити Envoy, вам потрібно розуміти, як взаємодіють кластери, слухачі (listeners), маршрути (routes) та точки доступу (endpoints) Envoy. Ми будемо використовувати команду `proxy-config` з прапорцем `-o json` і фільтрами, щоб відстежити, як Envoy вирішує, куди надсилати запит з podʼа `productpage` до podʼа `reviews` на `reviews:9080`.

1. Якщо ви запитаєте звіт про слухачів на podʼі, ви помітите, що Istio генерує наступні listeners:
    * Слухач на `0.0.0.0:15006`, який отримує весь вхідний трафік до podʼа, і слухач на `0.0.0.0:15001`, який отримує весь вихідний трафік з podʼа, а потім передає запит віртуальному слухачу.
    * Віртуальний слухач на кожну IP-адресу сервісу для не-HTTP вихідного TCP/HTTPS трафіку.
    * Віртуальний слухач на IP-адресу podʼа для кожного відкритого порту для вхідного трафіку.
    * Віртуальний слухач на `0.0.0.0` для кожного HTTP-порту для вихідного HTTP-трафіку.

    Ці слухачі забезпечують передачу трафіку між podʼами в сервісній мережі, керуючи різними типами зʼєднань і трафіком.

    {{< text bash >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs
    ADDRESS       PORT  MATCH                                            DESTINATION
    10.96.0.10    53    ALL                                              Cluster: outbound|53||kube-dns.kube-system.svc.cluster.local
    0.0.0.0       80    App: HTTP                                        Route: 80
    0.0.0.0       80    ALL                                              PassthroughCluster
    10.100.93.102 443   ALL                                              Cluster: outbound|443||istiod.istio-system.svc.cluster.local
    10.111.121.13 443   ALL                                              Cluster: outbound|443||istio-ingressgateway.istio-system.svc.cluster.local
    10.96.0.1     443   ALL                                              Cluster: outbound|443||kubernetes.default.svc.cluster.local
    10.100.93.102 853   App: HTTP                                        Route: istiod.istio-system.svc.cluster.local:853
    10.100.93.102 853   ALL                                              Cluster: outbound|853||istiod.istio-system.svc.cluster.local
    0.0.0.0       9080  App: HTTP                                        Route: 9080
    0.0.0.0       9080  ALL                                              PassthroughCluster
    0.0.0.0       9090  App: HTTP                                        Route: 9090
    0.0.0.0       9090  ALL                                              PassthroughCluster
    10.96.0.10    9153  App: HTTP                                        Route: kube-dns.kube-system.svc.cluster.local:9153
    10.96.0.10    9153  ALL                                              Cluster: outbound|9153||kube-dns.kube-system.svc.cluster.local
    0.0.0.0       15001 ALL                                              PassthroughCluster
    0.0.0.0       15006 Addr: 10.244.0.22/32:15021                       inbound|15021|mgmt-15021|mgmtCluster
    0.0.0.0       15006 Addr: 10.244.0.22/32:9080                        Inline Route: /*
    0.0.0.0       15006 Trans: tls; App: HTTP TLS; Addr: 0.0.0.0/0       Inline Route: /*
    0.0.0.0       15006 App: HTTP; Addr: 0.0.0.0/0                       Inline Route: /*
    0.0.0.0       15006 App: Istio HTTP Plain; Addr: 10.244.0.22/32:9080 Inline Route: /*
    0.0.0.0       15006 Addr: 0.0.0.0/0                                  InboundPassthroughClusterIpv4
    0.0.0.0       15006 Trans: tls; App: TCP TLS; Addr: 0.0.0.0/0        InboundPassthroughClusterIpv4
    0.0.0.0       15010 App: HTTP                                        Route: 15010
    0.0.0.0       15010 ALL                                              PassthroughCluster
    10.100.93.102 15012 ALL                                              Cluster: outbound|15012||istiod.istio-system.svc.cluster.local
    0.0.0.0       15014 App: HTTP                                        Route: 15014
    0.0.0.0       15014 ALL                                              PassthroughCluster
    0.0.0.0       15021 ALL                                              Inline Route: /healthz/ready*
    10.111.121.13 15021 App: HTTP                                        Route: istio-ingressgateway.istio-system.svc.cluster.local:15021
    10.111.121.13 15021 ALL                                              Cluster: outbound|15021||istio-ingressgateway.istio-system.svc.cluster.local
    0.0.0.0       15090 ALL                                              Inline Route: /stats/prometheus*
    10.111.121.13 15443 ALL                                              Cluster: outbound|15443||istio-ingressgateway.istio-system.svc.cluster.local
    {{< /text >}}

2. З наведеного вище звіту видно, що кожен sidecar має слухача, привʼязаного до `0.0.0.0:15006`, куди IP tables маршрутизує весь вхідний трафік до podʼа, і слухача, привʼязаного до `0.0.0.0:15001`, куди IP tables маршрутизує весь вихідний трафік з podʼа. Слухач на `0.0.0.0:15001` передає запит віртуальному слухачу, який найкраще відповідає початковому призначенню запиту, якщо він зможе знайти відповідний. В іншому випадку він надсилає запит до `PassthroughCluster`, який безпосередньо зʼєднується з кінцевим призначенням.

    {{< text bash json >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs --port 15001 -o json
    [
        {
            "name": "virtualOutbound",
            "address": {
                "socketAddress": {
                    "address": "0.0.0.0",
                    "portValue": 15001
                }
            },
            "filterChains": [
                {
                    "filters": [
                        {
                            "name": "istio.stats",
                            "typedConfig": {
                                "@type": "type.googleapis.com/udpa.type.v1.TypedStruct",
                                "typeUrl": "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                                "value": {
                                    "config": {
                                        "configuration": "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n",
                                        "root_id": "stats_outbound",
                                        "vm_config": {
                                            "code": {
                                                "local": {
                                                    "inline_string": "envoy.wasm.stats"
                                                }
                                            },
                                            "runtime": "envoy.wasm.runtime.null",
                                            "vm_id": "tcp_stats_outbound"
                                        }
                                    }
                                }
                            }
                        },
                        {
                            "name": "envoy.tcp_proxy",
                            "typedConfig": {
                                "@type": "type.googleapis.com/envoy.config.filter.network.tcp_proxy.v2.TcpProxy",
                                "statPrefix": "PassthroughCluster",
                                "cluster": "PassthroughCluster"
                            }
                        }
                    ],
                    "name": "virtualOutbound-catchall-tcp"
                }
            ],
            "trafficDirection": "OUTBOUND",
            "hiddenEnvoyDeprecatedUseOriginalDst": true
        }
    ]
    {{< /text >}}

3. Наш запит є вихідним HTTP-запитом на порт `9080`, що означає, що він передається до віртуального слухача на `0.0.0.0:9080`. Цей слухач потім шукає конфігурацію маршруту у своєму налаштованому RDS (Route Discovery Service). У цьому випадку він буде шукати маршрут `9080` в RDS, налаштованому Istiod (через ADS — Aggregated Discovery Service).

    {{< text bash json >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs -o json --address 0.0.0.0 --port 9080
    ...
    "rds": {
        "configSource": {
            "ads": {},
            "resourceApiVersion": "V3"
        },
        "routeConfigName": "9080"
    }
    ...
    {{< /text >}}

4. Конфігурація маршруту для порту `9080` має лише віртуальний хост для кожного сервісу. Оскільки наш запит спрямований до сервісу `reviews`, Envoy вибере віртуальний хост, який відповідає домену запиту. Після того, як домен узгоджено, Envoy шукає перший маршрут, який відповідає запиту. У цьому випадку немає жодної складної маршрутизації, тому є лише один маршрут, який відповідає всім запитам. Цей маршрут вказує Envoy на надсилання запиту до кластера `outbound|9080||reviews.default.svc.cluster.local`.

    {{< text bash json >}}
    $ istioctl proxy-config routes productpage-v1-6c886ff494-7vxhs --name 9080 -o json
    [
        {
            "name": "9080",
            "virtualHosts": [
                {
                    "name": "reviews.default.svc.cluster.local:9080",
                    "domains": [
                        "reviews.default.svc.cluster.local",
                        "reviews",
                        "reviews.default.svc",
                        "reviews.default",
                        "10.98.88.0",
                    ],
                    "routes": [
                        {
                            "name": "default",
                            "match": {
                                "prefix": "/"
                            },
                            "route": {
                                "cluster": "outbound|9080||reviews.default.svc.cluster.local",
                                "timeout": "0s",
                            }
                        }
                    ]
    ...
    {{< /text >}}

5. Цей кластер налаштований для отримання асоційованих точок доступу від Istiod (через ADS). Тому Envoy використовуватиме поле `serviceName` як ключ для пошуку списку точок доступу та проксіювання запиту до однієї з них.

    {{< text bash json >}}
    $ istioctl proxy-config cluster productpage-v1-6c886ff494-7vxhs --fqdn reviews.default.svc.cluster.local -o json
    [
        {
            "name": "outbound|9080||reviews.default.svc.cluster.local",
            "type": "EDS",
            "edsClusterConfig": {
                "edsConfig": {
                    "ads": {},
                    "resourceApiVersion": "V3"
                },
                "serviceName": "outbound|9080||reviews.default.svc.cluster.local"
            },
            "connectTimeout": "10s",
            "circuitBreakers": {
                "thresholds": [
                    {
                        "maxConnections": 4294967295,
                        "maxPendingRequests": 4294967295,
                        "maxRequests": 4294967295,
                        "maxRetries": 4294967295
                    }
                ]
            },
        }
    ]
    {{< /text >}}

6. Щоб переглянути точки доступу, які наразі доступні для цього кластера, використовуйте команду `proxy-config endpoints`.

    {{< text bash json >}}
    $ istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster "outbound|9080||reviews.default.svc.cluster.local"
    ENDPOINT            STATUS      OUTLIER CHECK     CLUSTER
    172.17.0.7:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.8:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.9:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    {{< /text >}}

## Інспектування конфігурації bootstrap {#inspecting-bootstrap-configuration}

До цього ми розглядали конфігурацію, отриману (переважно) від Istiod, однак Envoy потребує деякої конфігурації bootstrap, яка включає інформацію, наприклад, де можна знайти Istiod. Щоб переглянути це, використовуйте наступну команду:

{{< text bash json >}}
$ istioctl proxy-config bootstrap -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
{
    "bootstrap": {
        "node": {
            "id": "router~172.30.86.14~istio-ingressgateway-7d6874b48f-qxhn5.istio-system~istio-system.svc.cluster.local",
            "cluster": "istio-ingressgateway",
            "metadata": {
                    "CLUSTER_ID": "Kubernetes",
                    "EXCHANGE_KEYS": "NAME,NAMESPACE,INSTANCE_IPS,LABELS,OWNER,PLATFORM_METADATA,WORKLOAD_NAME,MESH_ID,SERVICE_ACCOUNT,CLUSTER_ID",
                    "INSTANCE_IPS": "10.244.0.7",
                    "ISTIO_PROXY_SHA": "istio-proxy:f98b7e538920abc408fbc91c22a3b32bc854d9dc",
                    "ISTIO_VERSION": "1.7.0",
                    "LABELS": {
                                "app": "istio-ingressgateway",
                                "chart": "gateways",
                                "heritage": "Tiller",
                                "istio": "ingressgateway",
                                "pod-template-hash": "68bf7d7f94",
                                "release": "istio",
                                "service.istio.io/canonical-name": "istio-ingressgateway",
                                "service.istio.io/canonical-revision": "latest"
                            },
                    "MESH_ID": "cluster.local",
                    "NAME": "istio-ingressgateway-68bf7d7f94-sp226",
                    "NAMESPACE": "istio-system",
                    "OWNER": "kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-ingressgateway",
                    "ROUTER_MODE": "sni-dnat",
                    "SDS": "true",
                    "SERVICE_ACCOUNT": "istio-ingressgateway-service-account",
                    "WORKLOAD_NAME": "istio-ingressgateway"
                },
            "userAgentBuildVersion": {
                "version": {
                    "majorNumber": 1,
                    "minorNumber": 15
                },
                "metadata": {
                        "build.type": "RELEASE",
                        "revision.sha": "f98b7e538920abc408fbc91c22a3b32bc854d9dc",
                        "revision.status": "Clean",
                        "ssl.version": "BoringSSL"
                    }
            },
        },
...
{{< /text >}}

## Перевірка підключення до Istiod {#verifying-connectivity-to-istiod}

Перевірка підключення до Istiod є корисним кроком для усунення проблем. Кожен контейнер проксі в сервісній мережі повинен мати змогу спілкуватися з Istiod. Це можна зробити кількома простими кроками:

1. Створіть под `curl`:

    {{< text bash >}}
    $ kubectl create namespace foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/curl/curl.yaml) -n foo
    {{< /text >}}

2. Перевірте підключення до Istiod за допомогою `curl`. Наступний приклад викликає API реєстрації v1 з використанням стандартних параметрів конфігурації Istiod і увімкненим взаємним TLS:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name}) -c curl -n foo -- curl -sS istiod.istio-system:15014/version
    {{< /text >}}

Ви повинні отримати відповідь, яка містить версію Istiod.

## Яка версія Envoy використовується в Istio? {#what-envoy-version-is-istio-using}

Щоб дізнатися версію Envoy, використану в розгортанні, ви можете зробити  `exec` в контейнер і запитати точку доступу `server_info`:

{{< text bash >}}
$ kubectl exec -it productpage-v1-6b746f74dc-9stvs -c istio-proxy -n default  -- pilot-agent request GET server_info --log_as_json | jq {version}
{
 "version": "2d4ec97f3ac7b3256d060e1bb8aa6c415f5cef63/1.17.0/Clean/RELEASE/BoringSSL"
}
{{< /text >}}

---
title: Depuración de Envoy e Istiod
description: Describe herramientas y técnicas para diagnosticar problemas de configuración de Envoy relacionados con la gestión de tráfico.
weight: 20
keywords: [debug,proxy,status,config,pilot,envoy]
aliases:
    - /help/ops/traffic-management/proxy-cmd
    - /help/ops/misc
    - /help/ops/troubleshooting/proxy-cmd
owner: istio/wg-user-experience-maintainers
test: no
---

Istio proporciona dos comandos muy útiles para ayudar a diagnosticar problemas de configuración de la gestión de tráfico:
los comandos [`proxy-status`](/es/docs/reference/commands/istioctl/#istioctl-proxy-status)
y [`proxy-config`](/es/docs/reference/commands/istioctl/#istioctl-proxy-config). El comando `proxy-status`
te permite obtener una visión general de tu mesh e identificar el proxy que causa el problema. Después, puedes usar `proxy-config`
para inspeccionar la configuración de Envoy y diagnosticar el problema.

Si quieres probar los comandos que se describen a continuación, puedes:

* Tener un clúster de Kubernetes con Istio y Bookinfo instalados (como se describe en los
[pasos de instalación](/es/docs/setup/getting-started/) y en los
[pasos de instalación de Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application)).

O

* Usar comandos similares con tu propia aplicación que se ejecute en un clúster de Kubernetes.

## Obtener una visión general de tu mesh {#get-an-overview-of-your-mesh}

El comando `proxy-status` te permite obtener una visión general de tu mesh. Si sospechas que uno de tus sidecars no está
recibiendo configuración o no está sincronizado, `proxy-status` te lo indicará.

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

Si falta un proxy en esta lista, significa que no está conectado actualmente a ninguna instancia de Istiod, por lo que no
recibirá ninguna configuración.

* `SYNCED` significa que Envoy confirmó la recepción de la última configuración que le envió {{< gloss >}}Istiod{{< /gloss >}}.
* `NOT SENT` significa que Istiod no le ha enviado nada a Envoy. Normalmente se debe a que Istiod no tiene nada que enviar.
* `STALE` significa que Istiod envió una actualización a Envoy, pero no ha recibido confirmación. Esto suele indicar
un problema de red entre Envoy e Istiod o un error del propio Istio.

## Obtener las diferencias entre Envoy e Istiod {#retrieve-diffs-between-envoy-and-istiod}

El comando `proxy-status` también se puede usar para obtener las diferencias entre la configuración que Envoy tiene cargada y la
configuración que Istiod enviaría, si le indicas un ID de proxy. Esto puede ayudarte a determinar exactamente qué no está sincronizado y
dónde puede estar el problema.

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

Aquí puedes ver que los listeners y las rutas coinciden, pero los clusters no están sincronizados.

## Análisis en profundidad de la configuración de Envoy {#deep-dive-into-envoy-configuration}

El comando `proxy-config` se puede usar para ver cómo está configurada una instancia concreta de Envoy. Con esto puedes
localizar problemas que no podrías detectar solo revisando tu configuración de Istio y tus recursos personalizados.
Para obtener un resumen básico de los clusters, listeners o rutas de un pod concreto, usa el comando de la siguiente manera (cambia clusters
por listeners o routes cuando lo necesites):

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

Para depurar Envoy necesitas entender los clusters/listeners/rutas/endpoints de Envoy y cómo interactúan entre sí.
Usaremos el comando `proxy-config` con el flag `-o json` y los flags de filtrado para seguir a Envoy mientras determina adónde
enviar una solicitud del pod `productpage` al pod `reviews` en `reviews:9080`.

1. Si consultas el resumen de listeners de un pod, verás que Istio genera los siguientes listeners:
    * Un listener en `0.0.0.0:15006` que recibe todo el tráfico entrante al pod y un listener en `0.0.0.0:15001` que recibe todo el tráfico saliente del pod y luego entrega la solicitud a un listener virtual.
    * Un listener virtual por cada IP de servicio y por cada puerto no HTTP, para el tráfico TCP/HTTPS saliente.
    * Un listener virtual en la IP del pod por cada puerto expuesto, para el tráfico entrante.
    * Un listener virtual en `0.0.0.0` por cada puerto HTTP, para el tráfico HTTP saliente.

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

1. En el resumen anterior puedes ver que cada sidecar tiene un listener vinculado a `0.0.0.0:15006`, adonde iptables redirige todo el tráfico entrante del pod, y un listener vinculado a `0.0.0.0:15001`, adonde iptables redirige todo el tráfico saliente del pod. El listener `0.0.0.0:15001` entrega la solicitud al listener virtual que mejor coincide con el destino original de la solicitud, si encuentra alguno. En caso contrario, envía la solicitud al `PassthroughCluster`, que se conecta directamente al destino.

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

1. Nuestra solicitud es una solicitud HTTP saliente al puerto `9080`, por lo que se entrega al listener virtual `0.0.0.0:9080`.
Luego, este listener busca la configuración de rutas en el RDS que tiene configurado. En este caso, buscará
la configuración de rutas `9080` en el RDS configurado por Istiod (mediante ADS).

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

1. La configuración de rutas `9080` solo tiene un virtual host para cada servicio. Nuestra solicitud se dirige al servicio
reviews, así que Envoy seleccionará el virtual host cuyo dominio coincida con nuestra solicitud. Una vez que el dominio coincide, Envoy
busca la primera ruta que coincida con la solicitud. En este caso no tenemos ningún enrutamiento avanzado, así que solo hay
una ruta, que coincide con todo. Esta ruta le indica a Envoy que envíe la solicitud al cluster
`outbound|9080||reviews.default.svc.cluster.local`.

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

1. Este cluster está configurado para obtener los endpoints asociados desde Istiod (mediante ADS). Así, Envoy usará el
campo `serviceName` como clave para buscar la lista de endpoints y reenviar la solicitud a uno de ellos.

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

1. Para ver los endpoints disponibles actualmente para este cluster, usa el comando `proxy-config` endpoints.

    {{< text bash json >}}
    $ istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster "outbound|9080||reviews.default.svc.cluster.local"
    ENDPOINT            STATUS      OUTLIER CHECK     CLUSTER
    172.17.0.7:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.8:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.9:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    {{< /text >}}

## Inspeccionar la configuración de bootstrap {#inspecting-bootstrap-configuration}

Hasta ahora vimos la configuración obtenida (principalmente) de Istiod; sin embargo, Envoy necesita cierta configuración de bootstrap que
incluye información como dónde se encuentra Istiod. Para verla, usa el siguiente comando:

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

## Verificar la conectividad con Istiod {#verifying-connectivity-to-istiod}

Verificar la conectividad con Istiod es un paso útil para solucionar problemas. Todos los contenedores de proxy del service mesh deberían poder comunicarse con Istiod. Puedes comprobarlo con unos pocos pasos sencillos:

1.  Crea un pod `curl`:

    {{< text bash >}}
    $ kubectl create namespace foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/curl/curl.yaml) -n foo
    {{< /text >}}

1.  Prueba la conectividad con Istiod usando `curl`. El siguiente ejemplo invoca la API de registro v1 con los parámetros de configuración por defecto de Istiod y con TLS mutuo habilitado:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name}) -c curl -n foo -- curl -sS istiod.istio-system:15014/version
    {{< /text >}}

Deberías recibir una respuesta con la versión de Istiod.

## ¿Qué versión de Envoy usa Istio? {#what-envoy-version-is-istio-using}

Para averiguar qué versión de Envoy se usa en tu despliegue, puedes hacer `exec` en el contenedor y consultar el endpoint `server_info`:

{{< text bash >}}
$ kubectl exec -it productpage-v1-6b746f74dc-9stvs -c istio-proxy -n default  -- pilot-agent request GET server_info --log_as_json | jq {version}
{
 "version": "2d4ec97f3ac7b3256d060e1bb8aa6c415f5cef63/1.17.0/Clean/RELEASE/BoringSSL"
}
{{< /text >}}

---
title: "Enrutamiento de tráfico de salida a destinos wildcard"
description: "Un enfoque genérico para configurar gateways de salida que pueden enrutar tráfico a un conjunto restringido de hosts remotos objetivo de forma dinámica, incluyendo dominios wildcard."
publishdate: 2023-12-01
attribution: "Gergő Huszty (IBM)"
keywords: [traffic-management,gateway,mesh,mtls,egress,remote]
---

Si está usando Istio para manejar tráfico originado por aplicaciones hacia destinos fuera de la malla, probablemente está familiarizado con el concepto de gateways de salida.
Los gateways de salida pueden usarse para monitorear y reenviar tráfico desde aplicaciones internas de la malla a ubicaciones fuera de la malla.
Esta es una característica útil si su sistema está operando en un entorno restringido y desea controlar qué se puede alcanzar en la internet pública desde su malla.

El caso de uso de configurar un gateway de salida para manejar dominios wildcard arbitrarios había sido incluido en la [documentación oficial de Istio](https://archive.istio.io/v1.13/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains) hasta la versión 1.13, pero fue posteriormente eliminado porque la solución documentada no estaba oficialmente soportada o recomendada y estaba sujeta a romperse en futuras versiones de Istio.
Sin embargo, la solución antigua todavía era utilizable con versiones de Istio anteriores a 1.20. Istio 1.20, sin embargo, eliminó alguna funcionalidad de Envoy que era requerida para que el enfoque funcionara.

Esta publicación intenta describir cómo resolvimos el problema y llenamos el vacío con un enfoque similar usando componentes independientes de la versión de Istio y características de Envoy, pero sin la necesidad de un proxy SNI de Nginx separado.
Nuestro enfoque permite a los usuarios de la solución antigua migrar configuraciones sin problemas antes de que sus sistemas enfrenten los cambios disruptivos en Istio 1.20.

## Problema a resolver

Los casos de uso de gateway de salida actualmente documentados se basan en el hecho de que el objetivo del tráfico
(el hostname) se configura estáticamente en un `VirtualService`, indicando a Envoy en el pod del gateway de salida hacia dónde hacer proxy TCP
de las conexiones salientes coincidentes. Puede usar múltiples, e incluso wildcard, nombres DNS para coincidir con los criterios de enrutamiento, pero no
puede enrutar el tráfico a la ubicación exacta especificada en la solicitud de la aplicación. Por ejemplo puede coincidir tráfico para objetivos
`*.wikipedia.org`, pero luego necesita reenviar el tráfico a un único objetivo final, por ejemplo, `en.wikipedia.org`. Si hay otro
servicio, por ejemplo, `anyservice.wikipedia.org`, que no está alojado por el mismo servidor(es) que `en.wikipedia.org`, el tráfico a ese host fallará. Esto es porque, aunque el hostname objetivo en el
handshake TLS de la carga HTTP contiene `anyservice.wikipedia.org`, los servidores `en.wikipedia.org` no podrán servir la solicitud.

La solución a este problema en un alto nivel es inspeccionar el nombre del servidor original (extensión SNI) en el handshake TLS de la aplicación (que se envía
en texto plano, por lo que no se necesita terminación TLS u otra operación de hombre en el medio) en cada nueva conexión del gateway y usarlo como
el objetivo para hacer proxy TCP dinámicamente del tráfico que sale del gateway.

Al restringir el tráfico de salida a través de gateways de salida, necesitamos bloquear los gateways de salida para que solo puedan ser usados
por clientes dentro de la malla. Esto se logra aplicando `ISTIO_MUTUAL` (autenticación de pares mTLS) entre la aplicación
sidecar y el gateway. Eso significa que habrá dos capas de TLS en la carga L7 de la aplicación. Una que es la aplicación
originada sesión TLS de extremo a extremo terminada por el objetivo remoto final, y otra que es la sesión mTLS de Istio.

Otra cosa a tener en cuenta es que para mitigar cualquier corrupción potencial del pod de aplicación, tanto el sidecar de la aplicación como el gateway deben realizar verificaciones de lista de hostnames.
De esta manera, cualquier pod de aplicación comprometido aún solo podrá acceder a los objetivos permitidos y nada más.

## Programación de Envoy de bajo nivel al rescate

Las versiones recientes de Envoy incluyen una solución de proxy TCP de reenvío dinámico que usa el encabezado SNI en una base por
conexión para determinar el objetivo de una solicitud de aplicación. Aunque un `VirtualService` de Istio no puede configurar un objetivo así, podemos usar
`EnvoyFilter`s para alterar las instrucciones de enrutamiento generadas por Istio para que se use el encabezado SNI para determinar el objetivo.

Para hacer que todo funcione, comenzamos configurando un gateway de salida personalizado para escuchar el tráfico saliente. Usando
un `DestinationRule` y un `VirtualService` instruimos a los sidecars de la aplicación para enrutar el tráfico (para una lista seleccionada
de hostnames) a ese gateway, usando mTLS de Istio. En el lado del pod del gateway construimos el reenviador SNI con los
`EnvoyFilter`s, mencionados anteriormente, introduciendo listeners y clusters internos de Envoy para hacer que todo funcione. Finalmente, parcheamos el
destino interno del proxy TCP implementado por el gateway al reenviador SNI interno.

El flujo de solicitud de extremo a extremo se muestra en el siguiente diagrama:

{{< image width="90%" link="./egress-sni-flow.svg" alt="Enrutamiento SNI de salida con nombres de dominio arbitrarios" title="Enrutamiento SNI de salida con nombres de dominio arbitrarios" caption="Enrutamiento SNI de salida con nombres de dominio arbitrarios" >}}

Este diagrama muestra una solicitud HTTPS de salida a `en.wikipedia.org` usando SNI como clave de enrutamiento.

* Contenedor de aplicación

    La aplicación origina una conexión HTTP/TLS hacia el destino final.
    Pone el hostname del destino en el encabezado SNI. Esta sesión TLS no es
    descifrada dentro de la malla. Solo se inspecciona el encabezado SNI (ya que está en texto plano).

* Proxy Sidecar

    El sidecar intercepta tráfico a hostnames coincidentes en el encabezado SNI de las sesiones TLS originadas por la aplicación.
    Basándose en el VirtualService, el tráfico se enruta al gateway de salida mientras envuelve el tráfico original en
    mTLS de Istio también. La sesión TLS externa tiene la dirección del Servicio del gateway en el encabezado SNI.

* Listener de malla

    Se crea un listener dedicado en el Gateway que autentica mutuamente el tráfico mTLS de Istio.
    Después de la terminación del mTLS externo de Istio, envía incondicionalmente el tráfico TLS interno con un proxy TCP
    al otro listener (interno) en el mismo Gateway.

* Reenviador SNI

    Otro listener con reenviador SNI realiza una nueva inspección de encabezado TLS para la sesión TLS original.
    Si el hostname SNI interno coincide con los nombres de dominio permitidos (incluyendo wildcards), hace proxy TCP del
    tráfico al destino, leído del encabezado por conexión. Este listener es interno a Envoy
    (permitiendo reiniciar el procesamiento de tráfico para ver el valor SNI interno), de modo que ningún pod (dentro o fuera de la malla)
    puede conectarse a él directamente. Este listener está 100% configurado manualmente a través de EnvoyFilter.

## Desplegar la muestra

Para desplegar la configuración de muestra, comience creando el namespace `istio-egress` y luego use el siguiente YAML para desplegar un gateway de salida, junto con algo de RBAC
y su `Service`. Usamos el método de inyección de gateway para crear el gateway en este ejemplo. Dependiendo de su método de instalación, puede querer
desplegarlo de manera diferente (por ejemplo, usando un CR `IstioOperator` o usando Helm).

{{< text yaml >}}
# New k8s cluster service to put egressgateway into the Service Registry,
# so application sidecars can route traffic towards it within the mesh.
apiVersion: v1
kind: Service
metadata:
  name: egressgateway
  namespace: istio-egress
spec:
  type: ClusterIP
  selector:
    istio: egressgateway
  ports:
  - port: 443
    name: tls-egress
    targetPort: 8443

---
# Gateway deployment with injection method
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-egressgateway
  namespace: istio-egress
spec:
  selector:
    matchLabels:
      istio: egressgateway
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        istio: egressgateway
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: istio-proxy
        image: auto # The image will automatically update each time the pod starts.
        securityContext:
          capabilities:
            drop:
            - ALL
          runAsUser: 1337
          runAsGroup: 1337

---
# Set up roles to allow reading credentials for TLS
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: istio-egressgateway-sds
  namespace: istio-egress
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
- apiGroups:
  - security.openshift.io
  resourceNames:
  - anyuid
  resources:
  - securitycontextconstraints
  verbs:
  - use

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: istio-egressgateway-sds
  namespace: istio-egress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: istio-egressgateway-sds
subjects:
- kind: ServiceAccount
  name: default
{{< /text >}}

Verifique que el pod del gateway esté funcionando en el namespace `istio-egress` y luego aplique el siguiente YAML para configurar el enrutamiento del gateway:

{{< text yaml >}}
# Define a new listener that enforces Istio mTLS on inbound connections.
# This is where sidecar will route the application traffic, wrapped into
# Istio mTLS.
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: egressgateway
  namespace: istio-system
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 8443
      name: tls-egress
      protocol: TLS
    hosts:
      - "*"
    tls:
      mode: ISTIO_MUTUAL

---
# VirtualService that will instruct sidecars in the mesh to route the outgoing
# traffic to the egress gateway Service if the SNI target hostname matches
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-wildcard-through-egress-gateway
  namespace: istio-system
spec:
  hosts:
    - "*.wikipedia.org"
  gateways:
  - mesh
  - egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
        - "*.wikipedia.org"
    route:
    - destination:
        host: egressgateway.istio-egress.svc.cluster.local
        subset: wildcard
# Dummy routing instruction. If omitted, no reference will point to the Gateway
# definition, and istiod will optimise the whole new listener out.
  tcp:
  - match:
    - gateways:
      - egressgateway
      port: 8443
    route:
    - destination:
        host: "dummy.local"
      weight: 100

---
# Instruct sidecars to use Istio mTLS when sending traffic to the egress gateway
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway
  namespace: istio-system
spec:
  host: egressgateway.istio-egress.svc.cluster.local
  subsets:
  - name: wildcard
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL

---
# Put the remote targets into the Service Registry
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: wildcard
  namespace: istio-system
spec:
  hosts:
    - "*.wikipedia.org"
  ports:
  - number: 443
    name: tls
    protocol: TLS

---
# Access logging for the gateway
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers:
      - name: envoy

---
# And finally, the configuration of the SNI forwarder,
# it's internal listener, and the patch to the original Gateway
# listener to route everything into the SNI forwarder.
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: sni-magic
  namespace: istio-system
spec:
  configPatches:
  - applyTo: CLUSTER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: sni_cluster
        load_assignment:
          cluster_name: sni_cluster
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  envoy_internal_address:
                    server_listener_name: sni_listener
  - applyTo: CLUSTER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: dynamic_forward_proxy_cluster
        lb_policy: CLUSTER_PROVIDED
        cluster_type:
          name: envoy.clusters.dynamic_forward_proxy
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.clusters.dynamic_forward_proxy.v3.ClusterConfig
            dns_cache_config:
              name: dynamic_forward_proxy_cache_config
              dns_lookup_family: V4_ONLY

  - applyTo: LISTENER
    match:
      context: GATEWAY
    patch:
      operation: ADD
      value:
        name: sni_listener
        internal_listener: {}
        listener_filters:
        - name: envoy.filters.listener.tls_inspector
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector

        filter_chains:
        - filter_chain_match:
            server_names:
            - "*.wikipedia.org"
          filters:
            - name: envoy.filters.network.sni_dynamic_forward_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.sni_dynamic_forward_proxy.v3.FilterConfig
                port_value: 443
                dns_cache_config:
                  name: dynamic_forward_proxy_cache_config
                  dns_lookup_family: V4_ONLY
            - name: envoy.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                stat_prefix: tcp
                cluster: dynamic_forward_proxy_cluster
                access_log:
                - name: envoy.access_loggers.file
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
                    path: "/dev/stdout"
                    log_format:
                      text_format_source:
                        inline_string: '[%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%
                          %PROTOCOL%" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
                          "%UPSTREAM_TRANSPORT_FAILURE_REASON%" %BYTES_RECEIVED% %BYTES_SENT% %DURATION%
                          %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%"
                          "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%" %UPSTREAM_CLUSTER%
                          %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS%
                          %REQUESTED_SERVER_NAME% %ROUTE_NAME%

                          '
  - applyTo: NETWORK_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.tcp_proxy"
    patch:
      operation: MERGE
      value:
        name: envoy.tcp_proxy
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
          stat_prefix: tcp
          cluster: sni_cluster
{{< /text >}}

Verifique los logs de `istiod` y del gateway para cualquier error o advertencia. Si todo salió bien, los sidecars de su malla ahora están enrutando
solicitudes `*.wikipedia.org` a su pod de gateway mientras el pod de gateway las está reenviando al host remoto exacto especificado en la solicitud de la
aplicación.

## Pruébelo

Siguiendo otros ejemplos de salida de Istio, usaremos el
pod [sleep]({{< github_tree >}}/samples/sleep) como fuente de prueba para enviar solicitudes.
Asumiendo que la inyección automática de sidecar está habilitada en su namespace predeterminado, despliegue
la aplicación de prueba usando el siguiente comando:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
{{< /text >}}

Obtenga sus pods sleep y gateway:

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ export GATEWAY_POD=$(kubectl get pod -n istio-egress -l istio=egressgateway -o jsonpath={.items..metadata.name})
{{< /text >}}

Ejecute el siguiente comando para confirmar que puede conectarse al sitio `wikipedia.org`:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
<title>Wikipedia, the free encyclopedia</title>
<title>Wikipedia – Die freie Enzyklopädie</title>
{{< /text >}}

¡Pudimos alcanzar tanto subdominios de `wikipedia.org` en inglés como en alemán, genial!

Normalmente, en un entorno de producción, [bloquearíamos solicitudes externas](/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy) que no están configuradas para redirigir a través del gateway de salida, pero dado que no hicimos eso en nuestro entorno de prueba, accedamos a otro sitio externo para comparar:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://cloud.ibm.com/login | grep -o "<title>.*</title>"'
<title>IBM Cloud</title>
{{< /text >}}

Dado que tenemos el registro de acceso activado globalmente (con el CR `Telemetry` en el manifiesto), ahora podemos inspeccionar los logs para ver cómo se manejaron las solicitudes anteriores por los proxies.

Primero, verifique los logs del gateway:

{{< text bash >}}
$ kubectl logs -n istio-egress $GATEWAY_POD
[...]
[2023-11-24T13:21:52.798Z] "- - -" 0 - - - "-" 813 111152 55 - "-" "-" "-" "-" "185.15.59.224:443" dynamic_forward_proxy_cluster 172.17.5.170:48262 envoy://sni_listener/ envoy://internal_client_address/ en.wikipedia.org -
[2023-11-24T13:21:52.798Z] "- - -" 0 - - - "-" 1531 111950 55 - "-" "-" "-" "-" "envoy://sni_listener/" sni_cluster envoy://internal_client_address/ 172.17.5.170:8443 172.17.34.35:55102 outbound_.443_.wildcard_.egressgateway.istio-egress.svc.cluster.local -
[2023-11-24T13:21:53.000Z] "- - -" 0 - - - "-" 821 92848 49 - "-" "-" "-" "-" "185.15.59.224:443" dynamic_forward_proxy_cluster 172.17.5.170:48278 envoy://sni_listener/ envoy://internal_client_address/ de.wikipedia.org -
[2023-11-24T13:21:53.000Z] "- - -" 0 - - - "-" 1539 93646 50 - "-" "-" "-" "-" "envoy://sni_listener/" sni_cluster envoy://internal_client_address/ 172.17.5.170:8443 172.17.34.35:55108 outbound_.443_.wildcard_.egressgateway.istio-egress.svc.cluster.local -
{{< /text >}}

Hay cuatro entradas de log, representando dos de nuestras tres solicitudes curl. Cada par muestra cómo una sola solicitud fluye a través del pipeline de procesamiento de tráfico de envoy.
Están impresas en orden inverso, pero podemos ver que la 2da y 4ta línea muestran que las solicitudes llegaron al servicio gateway y se pasaron a través del objetivo `sni_cluster` interno.
La 1ra y 3ra línea muestran que el objetivo final se determina del encabezado SNI interno, es decir, el host objetivo establecido por la aplicación.
La solicitud se reenvía a `dynamic_forward_proxy_cluster` que finalmente envía la solicitud desde Envoy al objetivo remoto.

Genial, pero ¿dónde está la tercera solicitud a IBM Cloud? Revisemos los logs del sidecar:

{{< text bash >}}
$ kubectl logs $SOURCE_POD -c istio-proxy
[...]
[2023-11-24T13:21:52.793Z] "- - -" 0 - - - "-" 813 111152 61 - "-" "-" "-" "-" "172.17.5.170:8443" outbound|443|wildcard|egressgateway.istio-egress.svc.cluster.local 172.17.34.35:55102 208.80.153.224:443 172.17.34.35:37020 en.wikipedia.org -
[2023-11-24T13:21:52.994Z] "- - -" 0 - - - "-" 821 92848 55 - "-" "-" "-" "-" "172.17.5.170:8443" outbound|443|wildcard|egressgateway.istio-egress.svc.cluster.local 172.17.34.35:55108 208.80.153.224:443 172.17.34.35:37030 de.wikipedia.org -
[2023-11-24T13:21:55.197Z] "- - -" 0 - - - "-" 805 15199 158 - "-" "-" "-" "-" "104.102.54.251:443" PassthroughCluster 172.17.34.35:45584 104.102.54.251:443 172.17.34.35:45582 cloud.ibm.com -
{{< /text >}}

Como puede ver, las solicitudes de Wikipedia se enviaron a través del gateway mientras que la solicitud a IBM Cloud salió directamente del pod de aplicación a internet, como lo indica el log `PassthroughCluster`.

## Conclusión

Implementamos enrutamiento controlado para tráfico HTTPS/TLS de salida usando gateways de salida, soportando nombres de dominio arbitrarios y wildcard. En un entorno de producción, el ejemplo mostrado en esta publicación
se extendería para soportar requisitos de HA (por ejemplo, agregando `Deployment`s de gateway conscientes de zona, etc.) y para restringir el
acceso directo a red externa de su aplicación para que la aplicación solo pueda acceder a la red pública a través del gateway, que está limitado a un conjunto predefinido de hostnames remotos.

La solución escala fácilmente. ¡Puede incluir múltiples nombres de dominio en la configuración, y serán permitidos tan pronto como lo despliegue!
No hay necesidad de configurar `VirtualService`s por dominio u otros detalles de enrutamiento. Sin embargo, tenga cuidado, ya que los nombres de dominio están listados en múltiples lugares en la configuración. Si usa
herramientas para CI/CD (por ejemplo, Kustomize), es mejor extraer la lista de nombres de dominio en un solo lugar desde el cual puede renderizar en los recursos de configuración requeridos.

¡Eso es todo! Espero que esto haya sido útil.
Si es un usuario existente de la solución anterior basada en Nginx,
ahora puede migrar a este enfoque antes de actualizar a Istio 1.20, que de otro modo interrumpirá su configuración actual.

¡Feliz enrutamiento SNI!

## Referencias

* [Documentación de Envoy para el reenviador SNI](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/sni_dynamic_forward_proxy_filter)
* [Solución anterior con Nginx como un contenedor proxy SNI en el gateway](https://archive.istio.io/v1.13/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains)

---
title: Salida usando Wildcard Hosts
description: Describe cómo habilitar el tráfico de salida para un conjunto de hosts en un dominio común, en lugar de configurar cada host por separado.
keywords: [traffic-management,egress]
weight: 50
aliases:
  - /docs/examples/advanced-gateways/wildcard-egress-hosts/
owner: istio/wg-networking-maintainers
test: yes
---

La tarea [Acceso a Services Externos](/es/docs/tasks/traffic-management/egress/egress-control) y
el ejemplo [Configurar un Egress Gateway](/es/docs/tasks/traffic-management/egress/egress-gateway/)
describen cómo configurar el tráfico de salida para hostnames específicos, como `edition.cnn.com`.
Este ejemplo muestra cómo habilitar el tráfico de salida para un conjunto de hosts en un dominio común, por
ejemplo `*.wikipedia.org`, en lugar de configurar cada host por separado.

## Antecedentes

Suponga que desea habilitar el tráfico de salida en Istio para los sitios `wikipedia.org` en todos los idiomas.
Cada versión de `wikipedia.org` en un idioma particular tiene su propio hostname, por ejemplo, `en.wikipedia.org` y
`de.wikipedia.org` en inglés y alemán, respectivamente.
Desea habilitar el tráfico de salida mediante elementos de configuración comunes para todos los sitios de Wikipedia,
sin necesidad de especificar cada sitio de idioma por separado.

{{< boilerplate gateway-api-support >}}

## Antes de empezar

*   Instale Istio con el registro de acceso habilitado y con la política de tráfico de salida de bloqueo por defecto:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl install --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
{{< /text >}}

{{< tip >}}
Puede ejecutar esta tarea en una configuración de Istio diferente al perfil `demo` siempre que se asegure de
[desplegar el egress gateway de Istio](/es/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway),
[habilitar el registro de acceso de Envoy](/es/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging), y
[aplicar la política de tráfico de salida de bloqueo por defecto](/es/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy)
en su instalación.
{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl install --set profile=minimal -y \
    --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true \
    --set meshConfig.accessLogFile=/dev/stdout \
    --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

*   Despliegue la aplicación de ejemplo [curl]({{< github_tree >}}/samples/curl) para usarla como fuente de prueba para enviar solicitudes.
    Si tiene
    la [inyección automática de sidecar](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
    habilitada, ejecute el siguiente comando para desplegar la aplicación de ejemplo:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    De lo contrario, inyecte manualmente el sidecar antes de desplegar la aplicación `curl` con el siguiente comando:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    {{< tip >}}
    Puede usar cualquier pod con `curl` instalado como fuente de prueba.
    {{< /tip >}}

*   Establezca la variable de entorno `SOURCE_POD` con el nombre de su pod de origen:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Configurar el tráfico directo a un host wildcard

La primera y más sencilla forma de acceder a un conjunto de hosts dentro de un dominio común es configurando
una `ServiceEntry` simple con un host wildcard y llamando a los services directamente desde el sidecar.
Al llamar a los services directamente (es decir, no a través de un egress gateway), la configuración para
un host wildcard no es diferente a la de cualquier otro host (por ejemplo, completamente calificado),
solo mucho más conveniente cuando hay muchos hosts dentro del dominio común.

{{< warning >}}
Tenga en cuenta que la configuración siguiente puede ser fácilmente eludida por una aplicación maliciosa. Para un control seguro del tráfico de salida,
dirija el tráfico a través de un egress gateway.
{{< /warning >}}

{{< warning >}}
Tenga en cuenta que la resolución `DNS` no se puede utilizar para hosts wildcard. Por eso se utiliza la resolución `NONE` (omitida ya que es
la predeterminada) en la entrada de service a continuación.
{{< /warning >}}

1.  Defina una `ServiceEntry` para `*.wikipedia.org`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      ports:
      - number: 443
        name: https
        protocol: HTTPS
    EOF
    {{< /text >}}

1.  Envíe solicitudes HTTPS a
    [https://en.wikipedia.org](https://en.wikipedia.org) y [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

### Limpieza del tráfico directo a un host wildcard

{{< text bash >}}
$ kubectl delete serviceentry wikipedia
{{< /text >}}

## Configurar el tráfico del egress gateway a un host wildcard

Cuando todos los hosts wildcard son atendidos por un solo servidor, la configuración para
el acceso basado en egress gateway a un host wildcard es muy similar a la de cualquier host, con una excepción:
el destino de ruta configurado no será el mismo que el host configurado,
es decir, el wildcard. En su lugar, se configurará con el host del único servidor para
el conjunto de dominios.

1.  Cree un `Gateway` de salida para _*.wikipedia.org_ y reglas de ruta
    para dirigir el tráfico a través del egress gateway y desde el egress gateway al service externo:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "*.wikipedia.org"
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-wikipedia
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
    - name: wikipedia
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-wikipedia-through-egress-gateway
spec:
  hosts:
  - "*.wikipedia.org"
  gateways:
  - mesh
  - istio-egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - "*.wikipedia.org"
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: wikipedia
        port:
          number: 443
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
    route:
    - destination:
        host: www.wikipedia.org
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: wikipedia-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: "*.wikipedia.org"
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: direct-wikipedia-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: wikipedia
  rules:
  - backendRefs:
    - name: wikipedia-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-wikipedia-from-egress-gateway
spec:
  parentRefs:
  - name: wikipedia-egress-gateway
  hostnames:
  - "*.wikipedia.org"
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: www.wikipedia.org
      port: 443
---
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: wikipedia
spec:
  hosts:
  - "*.wikipedia.org"
  ports:
  - number: 443
    name: https
    protocol: HTTPS
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Cree una `ServiceEntry` para el servidor de destino, _www.wikipedia.org_:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: www-wikipedia
    spec:
      hosts:
      - www.wikipedia.org
      ports:
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

3)  Envíe solicitudes HTTPS a
    [https://en.wikipedia.org](https://en.wikipedia.org) y [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

4)  Verifique las estadísticas del proxy del egress gateway para el contador que corresponde a sus
    solicitudes a _*.wikipedia.org_:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -n istio-system -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=wikipedia-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Limpieza del tráfico del egress gateway a un host wildcard

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-wikipedia
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete se wikipedia
$ kubectl delete se www-wikipedia
$ kubectl delete gtw wikipedia-egress-gateway
$ kubectl delete tlsroute direct-wikipedia-to-egress-gateway
$ kubectl delete tlsroute forward-wikipedia-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Configuración de comodines para dominios arbitrarios

La configuración de la sección anterior funcionó porque todos los sitios `*.wikipedia.org` pueden ser servidos por cualquiera
de los servidores `wikipedia.wikipedia.org`. Sin embargo, este no siempre es el caso. Por ejemplo, es posible que desee configurar el control de salida
para el acceso a dominios wildcard más generales como `*.com` o `*.org`. La configuración del tráfico a dominios wildcard arbitrarios
introduce un desafío para los gateways de Istio; un gateway de Istio solo se puede configurar para enrutar el tráfico
a hosts predefinidos, direcciones IP predefinidas o a la dirección IP de destino original de la solicitud.

En la sección anterior, configuró el virtual service para dirigir el tráfico al host predefinido `www.wikipedia.org`.
En el caso general, sin embargo, no conoce el host o la dirección IP que puede servir a un host arbitrario recibido en una
solicitud, lo que deja la dirección de destino original de la solicitud como el único valor con el que enrutar la solicitud.
Desafortunadamente, al usar un egress gateway, la dirección de destino original de la solicitud se pierde ya que la solicitud original
se redirige al gateway, lo que hace que la dirección IP de destino se convierta en la dirección IP del gateway.

Aunque no es tan fácil y algo frágil, ya que se basa en los detalles de implementación de Istio, puede usar
[filtros de Envoy](/es/docs/reference/config/networking/envoy-filter/) para configurar un gateway para admitir dominios arbitrarios
utilizando el valor [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) en una solicitud HTTPS, o cualquier TLS,
para identificar el destino original al que enrutar la solicitud. Un ejemplo de este enfoque de configuración se puede encontrar
en [enrutamiento del tráfico de salida a destinos wildcard](/blog/2023/egress-sni/).

## Limpieza

* Apague el service [curl]({{< github_tree >}}/samples/curl):

    {{< text bash >}}
    $ kubectl delete -f @samples/curl/curl.yaml@
    {{< /text >}}

* Desinstale Istio de su cluster:

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}
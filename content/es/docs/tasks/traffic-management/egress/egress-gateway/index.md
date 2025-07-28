---
title: Egress Gateways
description: Describe cómo configurar Istio para dirigir el tráfico a services externos a través de un gateway dedicado.
weight: 30
keywords: [traffic-management,egress]
aliases:
  - /docs/examples/advanced-gateways/egress-gateway/
owner: istio/wg-networking-maintainers
test: yes
---

{{<warning>}}
Este ejemplo no funciona en Minikube.
{{</warning>}}

La tarea [Acceso a Services Externos](/es/docs/tasks/traffic-management/egress/egress-control) muestra cómo configurar
Istio para permitir el acceso a services HTTP y HTTPS externos desde applications dentro de la malla.
Allí, los services externos se llaman directamente desde el sidecar del cliente.
Este ejemplo también muestra cómo configurar Istio para llamar a services externos, aunque esta vez
indirectamente a través de un service _egress gateway_ dedicado.

Istio utiliza [ingress y egress gateways](/es/docs/reference/config/networking/gateway/)
para configurar balanceadores de carga que se ejecutan en el borde de una service mesh.
Un ingress gateway le permite definir puntos de entrada a la malla por los que fluye todo el tráfico entrante.
Un egress gateway es un concepto simétrico; define puntos de salida de la malla. Los egress gateways permiten
aplicar features de Istio, por ejemplo, monitoreo y reglas de ruta, al tráfico que sale de la malla.

## Caso de uso

Considere una organización que tiene un requisito de seguridad estricto de que todo el tráfico que sale
de la service mesh debe fluir a través de un conjunto de nodos dedicados. Estos nodos se ejecutarán en máquinas dedicadas,
separadas del resto de los nodos que ejecutan applications en el cluster. Estos nodos especiales servirán
para la aplicación de políticas en el tráfico de salida y serán monitoreados más a fondo que otros nodos.

Otro caso de uso es un cluster donde los nodos de la aplicación no tienen IPs públicas, por lo que los services en malla que se ejecutan
en ellos no pueden acceder a Internet. Definir un egress gateway, dirigir todo el tráfico de salida a través de él y
asignar IPs públicas a los nodos del egress gateway permite que los nodos de la aplicación accedan a services externos de forma
controlada.

{{< boilerplate gateway-api-gamma-experimental >}}

## Antes de empezar

*	Configure Istio siguiendo las instrucciones de la [guía de instalación](/es/docs/setup/).

    {{< tip >}}
    El egress gateway y el registro de acceso se habilitarán si instala el perfil de
    [configuración `demo`](/es/docs/setup/additional-setup/config-profiles/).
    {{< /tip >}}

*	Despliegue la aplicación de ejemplo [curl]({{< github_tree >}}/samples/curl) para usarla como fuente de prueba para enviar solicitudes.

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    {{< tip >}}
    Puede usar cualquier pod con `curl` instalado como fuente de prueba.
    {{< /tip >}}

*	Establezca la variable de entorno `SOURCE_POD` con el nombre de su pod de origen:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

    {{< warning >}}
    Las instrucciones de esta tarea crean una regla de destino para el egress gateway en el namespace `default`
    y asumen que el cliente, `SOURCE_POD`, también se está ejecutando en el namespace `default`.
    Si no, la regla de destino no se encontrará en la
    [ruta de búsqueda de reglas de destino](/es/docs/ops/best-practices/traffic-management/#cross-namespace-configuration)
    y las solicitudes del cliente fallarán.
    {{< /warning >}}

*	[Habilite el registro de acceso de Envoy](/es/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)
    si aún no está habilitado. Por ejemplo, usando `istioctl`:

    {{< text bask >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
    {{< /text >}}

## Desplegar Istio egress gateway

{{< tip >}}
Los egress gateways se [despliegan automáticamente](/es/docs/tasks/traffic-management/ingress/gateway-api/#deployment-methods)
cuando se utiliza la API de Gateway para configurarlos. Puede omitir esta sección si está utilizando las instrucciones de la `Gateway API`
en las siguientes secciones.
{{< /tip >}}

1.	Verifique si el egress gateway de Istio está desplegado:

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway -n istio-system
    {{< /text >}}

    Si no se devuelven pods, despliegue el egress gateway de Istio realizando el siguiente paso.

1.	Si utilizó una configuración de `IstioOperator` para instalar Istio, agregue los siguientes campos a su configuración:

    {{< text yaml >}}
    spec:
      components:
        egressGateways:
        - name: istio-egressgateway
          enabled: true
    {{< /text >}}

    De lo contrario, agregue la configuración equivalente a su comando `istioctl install` original, por ejemplo:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set "components.egressGateways[0].name=istio-egressgateway" \
                       --set "components.egressGateways[0].enabled=true"
    {{< /text >}}

## Egress gateway para tráfico HTTP

Primero cree una `ServiceEntry` para permitir el tráfico directo a un service externo.

1.	Defina una `ServiceEntry` para `edition.cnn.com`.

    {{< warning >}}
    La resolución `DNS` debe usarse en la entrada de service a continuación. Si la resolución es `NONE`, el gateway
    dirigirá el tráfico a sí mismo en un bucle infinito. Esto se debe a que el gateway recibe una solicitud con la
    dirección IP de destino original que es igual a la IP del service del gateway (ya que la solicitud es dirigida por
    los proxies sidecar al gateway).

    Con la resolución `DNS`, el gateway realiza una consulta DNS para obtener una dirección IP del service externo y
    dirige el tráfico a esa dirección IP.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1.	Verifique que su `ServiceEntry` se aplicó correctamente enviando una solicitud HTTP a [http://edition.cnn.com/politics](http://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    La salida debería ser la misma que en el ejemplo de
    [TLS origination para Tráfico de Salida](/es/docs/tasks/traffic-management/egress/egress-tls-origination/),
    sin TLS origination.

1.	Cree un `Gateway` para el tráfico de salida al puerto 80 de _edition.cnn.com_.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
Para dirigir múltiples hosts a través de un egress gateway, puede incluir una lista de hosts, o usar `*` para que coincida con todos, en el `Gateway`.
El campo `subset` en la `DestinationRule` debe reutilizarse para los hosts adicionales.
{{< /tip >}}

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
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - edition.cnn.com
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: edition.cnn.com
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)	Configure reglas de ruta para dirigir el tráfico de los sidecars al egress gateway y del egress gateway
    al service externo:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 80
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)	Reenvíe la solicitud HTTP a [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    La salida debería ser la misma que en el paso 2.

6)	Verifique el registro del pod del egress gateway para una línea correspondiente a nuestra solicitud.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Si Istio está desplegado en el namespace `istio-system`, el comando para imprimir el registro es:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain >}}
[2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
{{< /text >}}

{{< tip >}}
Si la [Autenticación mTLS](/es/docs/tasks/security/authentication/authn-policy/) está habilitada, y tiene problemas para conectarse al egress gateway, ejecute el siguiente comando para verificar que el certificado es correcto:

{{< text bash >}}
$ istioctl pc secret -n istio-system "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Acceda al registro correspondiente al egress gateway utilizando la etiqueta de pod generada por Istio:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain >}}
[2024-01-09T15:35:47.283Z] "GET /politics HTTP/1.1" 301 - via_upstream - "-" 0 0 2 2 "172.30.239.55" "curl/7.87.0-DEV" "6c01d65f-a157-97cd-8782-320a40026901" "edition.cnn.com" "151.101.195.5:80" outbound|80||edition.cnn.com 172.30.239.16:55636 172.30.239.16:80 172.30.239.55:59224 - default.forward-cnn-from-egress-gateway.0
{{< /text >}}

{{< tip >}}
Si la [Autenticación mTLS](/es/docs/tasks/security/authentication/authn-policy/) está habilitada, y tiene problemas para conectarse al egress gateway, ejecute el siguiente comando para verificar que el certificado es correcto:

{{< text bash >}}
$ istioctl pc secret "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/default/sa/cnn-egress-gateway-istio
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

Tenga en cuenta que solo redirigió el tráfico HTTP del puerto 80 a través del egress gateway.
El tráfico HTTPS al puerto 443 fue directamente a _edition.cnn.com_.

### Limpieza del gateway HTTP

Elimine las definiciones anteriores antes de pasar al siguiente paso:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete httproute direct-cnn-to-egress-gateway
$ kubectl delete httproute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Egress gateway para tráfico HTTPS

En esta sección, dirigirá el tráfico HTTPS (TLS originado por la aplicación) a través de un egress gateway.
Debe especificar el puerto 443 con el protocolo `TLS` en una `ServiceEntry` y un `Gateway` de salida correspondientes.

1.	Defina una `ServiceEntry` para `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1.	Verifique que su `ServiceEntry` se aplicó correctamente enviando una solicitud HTTPS a [https://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

1.	Cree un `Gateway` de salida para _edition.cnn.com_ y reglas de ruta para dirigir el tráfico
    a través del egress gateway y del egress gateway al service externo.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
Para dirigir múltiples hosts a través de un egress gateway, puede incluir una lista de hosts, o usar `*` para que coincida con todos, en el `Gateway`.
El campo `subset` en la `DestinationRule` debe reutilizarse para los hosts adicionales.
{{< /tip >}}

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
      name: tls
      protocol: TLS
    hosts:
    - edition.cnn.com
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - mesh
  - istio-egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 443
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: edition.cnn.com
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
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: edition.cnn.com
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
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)	Envíe una solicitud HTTPS a [https://edition.cnn.com/politics](https://edition.cnn.com/politics).
    La salida debería ser la misma que antes.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

5)	Verifique el registro del proxy del egress gateway.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Si Istio está desplegado en el namespace `istio-system`, el comando para imprimir el registro es:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain >}}
[2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Acceda al registro correspondiente al egress gateway utilizando la etiqueta de pod generada por Istio:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain >}}
[2024-01-11T21:09:42.835Z] "- - -" 0 - - - "-" 839 2504306 231 - "-" "-" "-" "-" "151.101.195.5:443" outbound|443||edition.cnn.com 172.30.239.8:34470 172.30.239.8:443 172.30.239.15:43956 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Limpieza del gateway HTTPS

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete tlsroute direct-cnn-to-egress-gateway
$ kubectl delete tlsroute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Consideraciones de seguridad adicionales

Tenga en cuenta que la definición de un `Gateway` de salida en Istio no proporciona por sí misma ningún tratamiento especial para los nodos
en los que se ejecuta el service del egress gateway. Depende del administrador del cluster o del proveedor de la nube desplegar
los egress gateways en nodos dedicados e introducir medidas de seguridad adicionales para hacer que estos nodos sean más
seguros que el resto de la malla.

Istio *no puede garantizar de forma segura* que todo el tráfico de salida fluya realmente a través de los egress gateways. Istio solo
habilita dicho flujo a través de sus proxies sidecar. Si los atacantes eluden el proxy sidecar, podrían acceder directamente
a services externos sin atravesar el egress gateway. Así, los atacantes escapan del control y monitoreo de Istio.
El administrador del cluster o el proveedor de la nube deben asegurarse de que ningún tráfico salga de la malla sin pasar por el egress
gateway. Los mecanismos externos a Istio deben hacer cumplir este requisito. Por ejemplo, el administrador del cluster
puede configurar un firewall para denegar todo el tráfico que no provenga del egress gateway.
Las [políticas de red de Kubernetes](https://kubernetes.io/docs/concepts/services-networking/network-policies/) también
pueden prohibir todo el tráfico de salida que no se origine en el egress gateway (consulte
[la siguiente sección](#apply-kubernetes-network-policies) para ver un ejemplo).
Además, el administrador del cluster o el proveedor de la nube pueden configurar la red para asegurar que los nodos de la aplicación solo puedan
acceder a Internet a través de un gateway. Para ello, el administrador del cluster o el proveedor de la nube pueden evitar la
asignación de IPs públicas a pods que no sean gateways y pueden configurar dispositivos NAT para descartar paquetes que no se originen en
los egress gateways.

## Aplicar políticas de red de Kubernetes

Esta sección muestra cómo crear una
[política de red de Kubernetes](https://kubernetes.io/docs/concepts/services-networking/network-policies/) para evitar
la elusión del egress gateway. Para probar la política de red, creará un namespace, `test-egress`, desplegará
la muestra [curl]({{< github_tree >}}/samples/curl) en él, y luego intentará enviar solicitudes a un service externo
protegido por gateway.

1.	Siga los pasos de la sección
    [Egress gateway para tráfico HTTPS](#egress-gateway-for-https-traffic).

2.	Cree el namespace `test-egress`:

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

3.	Despliegue la muestra [curl]({{< github_tree >}}/samples/curl) en el namespace `test-egress`.

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/curl/curl.yaml@
    {{< /text >}}

4.	Verifique que el pod desplegado tiene un solo contenedor sin sidecar de Istio adjunto:

    {{< text bash >}}
    $ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    curl-776b7bcdcd-z7mc4    1/1       Running   0          18m
    {{< /text >}}

5.	Envíe una solicitud HTTPS a [https://edition.cnn.com/politics](https://edition.cnn.com/politics) desde el pod `curl` en
    el namespace `test-egress`. La solicitud tendrá éxito ya que aún no ha definido ninguna política restrictiva.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -s -o /dev/null -w "%{\http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

6.	Etiquete los namespaces donde se ejecutan el control plane de Istio y el egress gateway.
    Si desplegó Istio en el namespace `istio-system`, el comando es:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
$ kubectl label namespace default gateway=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7.	Etiquete el namespace `kube-system`.

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

8.	Defina una `NetworkPolicy` para limitar el tráfico de salida del namespace `test-egress` al tráfico destinado a
    el control plane, el gateway y el service DNS de `kube-system` (puerto 53).

    {{< warning >}}
    Las [políticas de red](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
    son implementadas por el plugin de red en su cluster de Kubernetes.
    Dependiendo de su cluster de prueba, el tráfico puede no ser bloqueado en el siguiente
    paso.
    {{< /warning >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
  - to:
    - namespaceSelector:
        matchLabels:
          gateway: "true"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

9)	Reenvíe la solicitud HTTPS anterior a [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Ahora
    debería fallar ya que el tráfico está bloqueado por la política de red. Tenga en cuenta que el pod `curl` no puede eludir
    el egress gateway. La única forma en que puede acceder a `edition.cnn.com` es utilizando un proxy sidecar de Istio y
    dirigiendo el tráfico al egress gateway. Esta configuración demuestra que incluso si un pod malicioso logra
    eludir su proxy sidecar, no podrá acceder a sitios externos y será bloqueado por la política de red.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -v -sS https://edition.cnn.com/politics
    Hostname was NOT found in DNS cache
      Trying 151.101.65.67...
      Trying 2a04:4e42:200::323...
    Immediate connect fail for 2a04:4e42:200::323: Cannot assign requested address
      Trying 2a04:4e42:400::323...
    Immediate connect fail for 2a04:4e42:400::323: Cannot assign requested address
      Trying 2a04:4e42:600::323...
    Immediate connect fail for 2a04:4e42:600::323: Cannot assign requested address
      Trying 2a04:4e42::323...
    Immediate connect fail for 2a04:4e42::323: Cannot assign requested address
    connect to 151.101.65.67 port 443 failed: Connection timed out
    {{< /text >}}

10)	Ahora inyecte un proxy sidecar de Istio en el pod `curl` en el namespace `test-egress` habilitando primero
    la inyección automática de proxy sidecar en el namespace `test-egress`:

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

11)	Luego vuelva a desplegar el despliegue `curl`:

    {{< text bash >}}
    $ kubectl delete deployment curl -n test-egress
    $ kubectl apply -f @samples/curl/curl.yaml@ -n test-egress
    {{< /text >}}

12)	Verifique que el pod desplegado tiene dos contenedores, incluido el proxy sidecar de Istio (`istio-proxy`):

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
curl istio-proxy
{{< /text >}}

Antes de continuar, deberá crear una regla de destino similar a la utilizada para el pod `curl` en el namespace `default`,
para dirigir el tráfico del namespace `test-egress` a través del egress gateway:

{{< text bash >}}
$ kubectl apply -n test-egress -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
curl istio-proxy
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

13)	Envíe una solicitud HTTPS a [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Ahora debería tener éxito
    ya que el tráfico que fluye al egress gateway está permitido por la
    Política de Red que definió. El gateway luego reenvía el tráfico a `edition.cnn.com`.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -sS -o /dev/null -w "%{\http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

14)	Verifique el registro del proxy del egress gateway.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Si Istio está desplegado en el namespace `istio-system`, el comando para imprimir el registro es:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain >}}
[2020-03-06T18:12:33.101Z] "- - -" 0 - "-" "-" 906 1352475 35 - "-" "-" "-" "-" "151.101.193.67:443" outbound|443||edition.cnn.com 172.30.223.53:39460 172.30.223.53:443 172.30.223.58:38138 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Acceda al registro correspondiente al egress gateway utilizando la etiqueta de pod generada por Istio:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain >}}
[2024-01-12T19:54:01.821Z] "- - -" 0 - - - "-" 839 2504306 231 - "-" "-" "-" "-" "151.101.67.5:443" outbound|443||edition.cnn.com 172.30.239.60:49850 172.30.239.60:443 172.30.239.21:36512 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Limpieza de políticas de red

1.	Elimine los recursos creados en esta sección:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@ -n test-egress
$ kubectl delete destinationrule egressgateway-for-cnn -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@ -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl label namespace default gateway-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)	Siga los pasos de la sección [Limpieza del gateway HTTPS](#cleanup-https-gateway).

## Limpieza

Apague el service [curl]({{< github_tree >}}/samples/curl):

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}

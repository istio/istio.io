---
title: Gateways de Entrada
description: Describe cómo configurar un gateway de Istio para exponer un service fuera de la service mesh.
weight: 10
keywords: [traffic-management,ingress]
aliases:
    - /docs/tasks/ingress.html
    - /docs/tasks/ingress
owner: istio/wg-networking-maintainers
test: yes
---

Además del soporte para los recursos [Ingress](/es/docs/tasks/traffic-management/ingress/kubernetes-ingress/) de Kubernetes, Istio también le permite configurar el tráfico de entrada
utilizando un [Gateway de Istio](/es/docs/concepts/traffic-management/#gateways) o un recurso [Gateway de Kubernetes](https://gateway-api.sigs.k8s.io/api-types/gateway/).
Un `Gateway` proporciona una personalización y flexibilidad más amplias que `Ingress`, y permite que las features de Istio, como el monitoreo y las reglas de ruta, se apliquen al tráfico que ingresa al cluster.

Esta tarea describe cómo configurar Istio para exponer un service fuera de la service mesh utilizando un `Gateway`.

{{< boilerplate gateway-api-support >}}

## Antes de empezar

*   Configure Istio siguiendo las instrucciones de la [guía de instalación](/es/docs/setup/).

    {{< tip >}}
    Si va a utilizar las instrucciones de la `Gateway API`, puede instalar Istio utilizando el perfil `minimal`
    porque no necesitará el `istio-ingressgateway` que, de lo contrario, se instala
    por defecto:

    {{< text bash >}}
    $ istioctl install --set profile=minimal
    {{< /text >}}

    {{< /tip >}}

*   Inicie la muestra [httpbin]({{< github_tree >}}/samples/httpbin), que servirá como service de destino
    para el tráfico de entrada:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    Tenga en cuenta que, para el propósito de este documento, que muestra cómo usar un gateway para controlar el tráfico de entrada
    en su "cluster de Kubernetes", puede iniciar el service `httpbin` con o sin
    la inyección de sidecar habilitada (es decir, el service de destino puede estar dentro o fuera de la malla de Istio).

## Configuración de la entrada usando un gateway

Un `Gateway` de entrada describe un balanceador de carga que opera en el borde de la malla y que recibe conexiones HTTP/TCP entrantes.
Configura los puertos expuestos, protocolos, etc.
pero, a diferencia de los [Recursos Ingress de Kubernetes](https://kubernetes.io/docs/concepts/services-networking/ingress/),
no incluye ninguna configuración de enrutamiento de tráfico. El enrutamiento de tráfico para el tráfico de entrada se configura
utilizando reglas de enrutamiento, exactamente de la misma manera que para las solicitudes de services internos.

Veamos cómo puede configurar un `Gateway` en el puerto 80 para el tráfico HTTP.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Cree un [Gateway de Istio](/es/docs/reference/config/networking/gateway/):

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # El selector coincide con las etiquetas del pod del ingress gateway.
  # Si instaló Istio usando Helm siguiendo la documentación estándar, esto sería "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
EOF
{{< /text >}}

Configure las rutas para el tráfico que ingresa a través del `Gateway`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

Ahora ha creado una configuración de [virtual service](/es/docs/reference/config/networking/virtual-service/)
para el service `httpbin` que contiene dos reglas de ruta que permiten el tráfico para las rutas `/status` y
`/delay`.

La lista de [gateways](/es/docs/reference/config/networking/virtual-service/#VirtualService-gateways)
especifica que solo se permiten las solicitudes a través de su `httpbin-gateway`.
Todas las demás solicitudes externas serán rechazadas con una respuesta 404.

{{< warning >}}
Las solicitudes internas de otros services en la malla no están sujetas a estas reglas
sino que, en su lugar, se establecerán por defecto en el enrutamiento round-robin. Para aplicar estas reglas también a las llamadas internas,
puede agregar el valor especial `mesh` a la lista de `gateways`. Dado que el hostname interno para el
service es probablemente diferente (por ejemplo, `httpbin.default.svc.cluster.local`) del externo,
también deberá agregarlo a la lista de `hosts`. Consulte la
[guía de operaciones](/es/docs/ops/common-problems/network-issues#route-rules-have-no-effect-on-ingress-gateway-requests)
para obtener más detalles.
{{< /warning >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Cree un [Gateway de Kubernetes](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway):

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: "httpbin.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

{{< tip >}}
En un entorno de producción, un `Gateway` y sus rutas correspondientes a menudo se crean en namespaces separados por usuarios
que realizan diferentes roles. En ese caso, el campo `allowedRoutes` en el `Gateway` se configuraría para especificar los
namespaces donde se deben crear las rutas, en lugar de, como en este ejemplo, esperar que estén en el mismo namespace
que el `Gateway`.
{{< /tip >}}

Debido a que la creación de un recurso `Gateway` de Kubernetes también
[desplegará un service proxy asociado](/es/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment),
ejecute el siguiente comando para esperar a que el gateway esté listo:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw httpbin-gateway
{{< /text >}}

Configure las rutas para el tráfico que ingresa a través del `Gateway`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /status
    - path:
        type: PathPrefix
        value: /delay
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

Ahora ha creado una configuración de [Ruta HTTP](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.HTTPRoute)
para el service `httpbin` que contiene dos reglas de ruta que permiten el tráfico para las rutas `/status` y
`/delay`.

{{< /tab >}}

{{< /tabset >}}

## Determinación de la IP y los puertos de entrada

Cada `Gateway` está respaldado por un [service de tipo LoadBalancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/).
La IP y los puertos del balanceador de carga externo para este service se utilizan para acceder al gateway.
Los services de Kubernetes de tipo `LoadBalancer` son compatibles por defecto en clusters que se ejecutan en la mayoría de las plataformas en la nube, pero
en algunos entornos (por ejemplo, de prueba) es posible que deba hacer lo siguiente:

* `minikube`: inicie un balanceador de carga externo ejecutando el siguiente comando en una terminal diferente:

    {{< text syntax=bash snip_id=minikube_tunnel >}}
    $ minikube tunnel
    {{< /text >}}

* `kind`: siga la [guía](https://kind.sigs.k8s.io/docs/user/loadbalancer/) para que los services de tipo `LoadBalancer` funcionen.

* otras plataformas: es posible que pueda usar [MetalLB](https://metallb.universe.tf/installation/) para obtener una `EXTERNAL-IP` para los services `LoadBalancer`.

Para mayor comodidad, almacenaremos la IP y los puertos de entrada en variables de entorno que se utilizarán en instrucciones posteriores.
Establezca las variables de entorno `INGRESS_HOST` e `INGRESS_PORT` de acuerdo con las siguientes instrucciones:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Establezca las siguientes variables de entorno con el nombre y el namespace donde se encuentra el ingress gateway de Istio en su cluster:

{{< text bash >}}
$ export INGRESS_NAME=istio-ingressgateway
$ export INGRESS_NS=istio-system
{{< /text >}}

{{< tip >}}
Si instaló Istio usando Helm siguiendo la documentación estándar, el nombre y el namespace del ingress gateway son ambos `istio-ingress`:

{{< text bash >}}
$ export INGRESS_NAME=istio-ingress
$ export INGRESS_NS=istio-ingress
{{< /text >}}

{{< /tip >}}

Ejecute el siguiente comando para determinar si su cluster de Kubernetes se encuentra en un entorno que admite balanceadores de carga externos:

{{< text bash >}}
$ kubectl get svc "$INGRESS_NAME" -n "$INGRESS_NS"
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)   AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121   ...       17h
{{< /text >}}

Si el valor `EXTERNAL-IP` está establecido, su entorno tiene un balanceador de carga externo que puede usar para el ingress gateway.
Si el valor `EXTERNAL-IP` es `<none>` (o perpetuamente `<pending>`), su entorno no proporciona un balanceador de carga externo para el ingress gateway.

Si su entorno no admite balanceadores de carga externos, puede intentar
[acceder al ingress gateway utilizando los puertos de nodo](/es/docs/tasks/traffic-management/ingress/ingress-control/#using-node-ports-of-the-ingress-gateway-service).
De lo contrario, establezca la IP y los puertos de entrada utilizando los siguientes comandos:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
$ export TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
{{< /text >}}

{{< warning >}}
En ciertos entornos, el balanceador de carga puede exponerse utilizando un nombre de host, en lugar de una dirección IP.
En este caso, el valor `EXTERNAL-IP` del ingress gateway no será una dirección IP,
sino un nombre de host, y el comando anterior no habrá podido establecer la variable de entorno `INGRESS_HOST`.
Utilice el siguiente comando para corregir el valor de `INGRESS_HOST`:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Obtenga la dirección y el puerto del gateway del recurso httpbin gateway:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< tip >}}
Puede usar comandos similares para encontrar otros puertos en cualquier gateway. Por ejemplo, para acceder a un puerto HTTP seguro
llamado `https` en un gateway llamado `my-gateway`:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw my-gateway -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw my-gateway -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

## Acceso a services de entrada

1.  Acceda al service _httpbin_ usando _curl_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
    ...
    HTTP/1.1 200 OK
    ...
    server: istio-envoy
    ...
    {{< /text >}}

    Tenga en cuenta que utiliza el flag `-H` para establecer la cabecera HTTP _Host_ en
    "httpbin.example.com". Esto es necesario porque su `Gateway` de entrada está configurado para manejar "httpbin.example.com",
    pero en su entorno de prueba no tiene ninguna vinculación DNS para ese host y simplemente está enviando su solicitud a la IP de entrada.

1.  Acceda a cualquier otra URL que no haya sido expuesta explícitamente. Debería ver un error HTTP 404:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

### Acceso a services de entrada usando un navegador

Introducir la URL del service `httpbin` en un navegador no funcionará porque no puede pasar la cabecera _Host_
a un navegador como lo hizo con `curl`. En una situación real, esto no es un problema
porque configura el host solicitado correctamente y es resoluble por DNS. Por lo tanto, utiliza el nombre de dominio del host
en la URL, por ejemplo, `https://httpbin.example.com/status/200`.

Puede solucionar este problema para pruebas y demostraciones simples de la siguiente manera:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Use un valor comodín `*` para el host en las configuraciones de `Gateway`
y `VirtualService`. Por ejemplo, cambie su configuración de entrada a lo siguiente:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # El selector coincide con las etiquetas del pod del ingress gateway.
  # Si instaló Istio usando Helm siguiendo la documentación estándar, esto sería "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Si elimina los nombres de host de las configuraciones de `Gateway` y `HTTPRoute`, se aplicarán a cualquier solicitud.
Por ejemplo, cambie su configuración de entrada a lo siguiente:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /headers
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Luego puede usar `$INGRESS_HOST:$INGRESS_PORT` en la URL del navegador. Por ejemplo,
`http://$INGRESS_HOST:$INGRESS_PORT/headers` mostrará todas las cabeceras que envía su navegador.

## Comprender lo que sucedió

Los recursos de configuración de `Gateway` permiten que el tráfico externo ingrese a la
service mesh de Istio y ponen a disposición las features de gestión de tráfico y políticas de Istio
para los services de borde.

En los pasos anteriores, creó un service dentro de la service mesh
y expuso un endpoint HTTP del service al tráfico externo.

## Uso de puertos de nodo del service de ingress gateway

{{< warning >}}
No debe usar estas instrucciones si su entorno de Kubernetes tiene un balanceador de carga externo que admita
[services de tipo LoadBalancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/).
{{< /warning >}}

Si su entorno no admite balanceadores de carga externos, aún puede experimentar con algunas de las features de Istio utilizando
los [puertos de nodo](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) del service `istio-ingressgateway`.

Establezca los puertos de entrada:

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
$ export TCP_INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
{{< /text >}}

La configuración de la IP de entrada depende del proveedor del cluster:

1.  _GKE:_

    {{< text bash >}}
    $ export INGRESS_HOST=worker-node-address
    {{< /text >}}

    Debe crear reglas de firewall para permitir el tráfico TCP a los puertos del service _ingressgateway_.
    Ejecute los siguientes comandos para permitir el tráfico para el puerto HTTP, el puerto seguro (HTTPS) o ambos:

    {{< text bash >}}
    $ gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
    $ gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
    {{< /text >}}

1.  _IBM Cloud Kubernetes Service:_

    {{< text bash >}}
    $ ibmcloud ks workers --cluster cluster-name-or-id
    $ export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
    {{< /text >}}

1.  _Docker For Desktop:_

    {{< text bash >}}
    $ export INGRESS_HOST=127.0.0.1
    {{< /text >}}

1.  _Otros entornos:_

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n "${INGRESS_NS}" -o jsonpath='{.items[0].status.hostIP}')
    {{< /text >}}

## Solución de problemas

1.  Inspeccione los valores de las variables de entorno `INGRESS_HOST` e `INGRESS_PORT`. Asegúrese
    de que tienen valores válidos, de acuerdo con la salida de los siguientes comandos:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, INGRESS_PORT=$INGRESS_PORT"
    {{< /text >}}

1.  Verifique que no tiene otros ingress gateways de Istio definidos en el mismo puerto:

    {{< text bash >}}
    $ kubectl get gateway --all-namespaces
    {{< /text >}}

1.  Verifique que no tiene recursos Ingress de Kubernetes definidos en la misma IP y puerto:

    {{< text bash >}}
    $ kubectl get ingress --all-namespaces
    {{< /text >}}

1.  Si tiene un balanceador de carga externo y no le funciona, intente
    [acceder al gateway utilizando su puerto de nodo](/es/docs/tasks/traffic-management/ingress/ingress-control/#using-node-ports-of-the-ingress-gateway-service).

## Limpieza

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Elimine la configuración de `Gateway` y `VirtualService`, y apague el service [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete gateway httpbin-gateway
$ kubectl delete virtualservice httpbin
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Elimine la configuración de `Gateway` y `HTTPRoute`, y apague el service [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete httproute httpbin
$ kubectl delete gtw httpbin-gateway
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

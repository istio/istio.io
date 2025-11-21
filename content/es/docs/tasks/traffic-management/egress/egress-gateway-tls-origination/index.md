---
title: Egress Gateways con TLS origination
description: Describe cómo configurar un Egress Gateway para realizar la TLS origination a services externos.
weight: 40
keywords: [traffic-management,egress]
aliases:
  - /docs/examples/advanced-gateways/egress-gateway-tls-origination/
  - /docs/examples/advanced-gateways/egress-gateway-tls-origination-sds/
  - /docs/tasks/traffic-management/egress/egress-gateway-tls-origination-sds/
owner: istio/wg-networking-maintainers
test: yes
---

El ejemplo [TLS origination para Tráfico de Salida](/es/docs/tasks/traffic-management/egress/egress-tls-origination/)
muestra cómo configurar Istio para realizar la {{< gloss >}}TLS origination{{< /gloss >}}
para el tráfico a un service externo. El ejemplo [Configurar un Egress Gateway](/es/docs/tasks/traffic-management/egress/egress-gateway/)
muestra cómo configurar Istio para dirigir el tráfico de salida a través de un
service _egress gateway_ dedicado. Este ejemplo combina los dos anteriores al
describir cómo configurar un egress gateway para realizar la TLS origination para
el tráfico a services externos.

{{< boilerplate gateway-api-support >}}

## Antes de empezar

*   Configure Istio siguiendo las instrucciones de la [guía de instalación](/es/docs/setup/).

*   Inicie la muestra [curl]({{< github_tree >}}/samples/curl)
    que se utilizará como fuente de prueba para llamadas externas.

    Si ha habilitado la [inyección automática de sidecar](/es/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), haga

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    de lo contrario, debe inyectar manualmente el sidecar antes de desplegar la aplicación `curl`:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    Tenga en cuenta que cualquier pod desde el que pueda `exec` y `curl` servirá para los procedimientos siguientes.

*   Cree una variable de shell para almacenar el nombre del pod de origen para enviar solicitudes a services externos.
    Si utilizó la muestra [curl]({{< github_tree >}}/samples/curl), ejecute:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

*   Para usuarios de macOS, verifique que está utilizando `openssl` versión 1.1 o posterior:

    {{< text bash >}}
    $ openssl version -a | grep OpenSSL
    OpenSSL 1.1.1g  21 Apr 2020
    {{< /text >}}

    Si el comando anterior muestra una versión `1.1` o posterior, como se muestra, su comando `openssl`
    debería funcionar correctamente con las instrucciones de esta tarea. De lo contrario, actualice su `openssl` o pruebe
    una implementación diferente de `openssl`, por ejemplo en una máquina Linux.

*   [Habilite el registro de acceso de Envoy](/es/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)
    si aún no está habilitado. Por ejemplo, usando `istioctl`:

    {{< text bask >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
    {{< /text >}}

*   Si NO está utilizando las instrucciones de la `Gateway API`, asegúrese de
    [desplegar el egress gateway de Istio](/es/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway).

## Realizar la TLS origination con un egress gateway

Esta sección describe cómo realizar la misma TLS origination que en el ejemplo
[TLS origination para Tráfico de Salida](/es/docs/tasks/traffic-management/egress/egress-tls-origination/),
solo que esta vez utilizando un egress gateway. Tenga en cuenta que en este caso la TLS origination se
realizará por el egress gateway, a diferencia del sidecar en el ejemplo anterior.

1.  Defina una `ServiceEntry` para `edition.cnn.com`:

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
        name: http
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Verifique que su `ServiceEntry` se aplicó correctamente enviando una solicitud a [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "${SOURCE_POD}" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...
    {{< /text >}}

    Su `ServiceEntry` se configuró correctamente si ve _301 Moved Permanently_ en la salida.

1.  Cree un `Gateway` de salida para _edition.cnn.com_, puerto 80, y una regla de destino para
    las solicitudes sidecar que se dirigirán al egress gateway.

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
      number: 80
      name: https-port-for-tls-origination
      protocol: HTTPS
    hosts:
    - edition.cnn.com
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 80
        tls:
          mode: ISTIO_MUTUAL
          sni: edition.cnn.com
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
  - name: https-listener-for-tls-origination
    hostname: edition.cnn.com
    port: 80
    protocol: HTTPS
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: cnn-egress-gateway-istio.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 80
      tls:
        mode: ISTIO_MUTUAL
        sni: edition.cnn.com
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) Configure reglas de ruta para dirigir el tráfico a través del egress gateway:

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
          number: 443
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
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Defina una `DestinationRule` para realizar la TLS origination para las solicitudes a `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: originate-tls-for-edition-cnn-com
spec:
      host: edition.cnn.com
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: SIMPLE # inicia HTTPS para conexiones a edition.cnn.com
    EOF
    {{< /text >}}

6)  Envíe una solicitud HTTP a [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "${SOURCE_POD}" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

    La salida debería ser la misma que en el ejemplo de [TLS origination para Tráfico de Salida](/es/docs/tasks/traffic-management/egress/egress-tls-origination/),
    con TLS origination: sin el mensaje _301 Moved Permanently_.

7) Verifique el registro del proxy del egress gateway.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Si Istio está desplegado en el namespace `istio-system`, el comando para imprimir el registro es:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain>}}
[2020-06-30T16:17:56.763Z] "GET /politics HTTP/2" 200 - "-" "-" 0 1295938 529 89 "10.244.0.171" "curl/7.64.0" "cf76518d-3209-9ab7-a1d0-e6002728ef5b" "edition.cnn.com" "151.101.129.67:443" outbound|443||edition.cnn.com 10.244.0.170:54280 10.244.0.170:8080 10.244.0.171:35628 - -
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Acceda al registro correspondiente al egress gateway utilizando la etiqueta de pod generada por Istio:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain >}}
[2024-03-14T18:37:01.451Z] "GET /politics HTTP/1.1" 200 - via_upstream - "-" 0 2484998 59 37 "172.30.239.26" "curl/7.87.0-DEV" "b80c8732-8b10-4916-9a73-c3e1c848ed1e" "edition.cnn.com" "151.101.131.5:443" outbound|443||edition.cnn.com 172.30.239.33:51270 172.30.239.33:80 172.30.239.26:35192 edition.cnn.com default.forward-cnn-from-egress-gateway.0
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Limpieza del TLS origination ejemplo

Borra las configuraciones de Istio que se crearon::

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete gw istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete httproute direct-cnn-to-egress-gateway
$ kubectl delete httproute forward-cnn-from-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Realizar la originación mTLS con un egress gateway

De forma similar a la sección anterior, esta sección describe cómo configurar un egress gateway para realizar
la TLS origination para un service externo, solo que esta vez utilizando un service que requiere mTLS.

Este ejemplo es considerablemente más complejo porque requiere la siguiente configuración:

1. generar certificados de cliente y servidor
1. desplegar un service externo que admita el protocolo mTLS
1. volver a desplegar el egress gateway con los certificados mTLS necesarios

Solo entonces podrá configurar el tráfico externo para que pase por el egress gateway, que realizará
la TLS origination.

### Generar certificados y claves de cliente y servidor

Para esta tarea, puede usar su herramienta favorita para generar certificados y claves. Los comandos a continuación usan
[openssl](https://man.openbsd.org/openssl.1)

1.  Cree un certificado raíz y una clave privada para firmar el certificado de sus services:

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  Cree un certificado y una clave privada para `my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

    Opcionalmente, puede agregar `SubjectAltNames` al certificado si desea habilitar la validación SAN para el destino. Por ejemplo:

    {{< text syntax=bash snip_id=none >}}
    $ cat > san.conf <<EOF
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    x509_extensions = v3_req
    prompt = no
    [req_distinguished_name]
    countryName = US
    [v3_req]
    keyUsage = critical, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth
    basicConstraints = critical, CA:FALSE
    subjectAltName = critical, @alt_names
    [alt_names]
    DNS = my-nginx.mesh-external.svc.cluster.local
    EOF
    $
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:4096 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization" -config san.conf
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt -extfile san.conf -extensions v3_req
    {{< /text >}}

1.  Genere el certificado de cliente y la clave privada:

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

### Desplegar un servidor mTLS

Para simular un service externo real que admita el protocolo mTLS,
despliegue un servidor [NGINX](https://www.nginx.com) en su cluster de Kubernetes, pero ejecutándose fuera de
la service mesh de Istio, es decir, en un namespace sin la inyección de proxy sidecar de Istio habilitada.

1.  Cree un namespace para representar servicios fuera de la mesh de Istio, llamado `mesh-external`. Tenga en cuenta que el proxy sidecar
    no se inyectará automáticamente en los pods de este namespace ya que la inyección automática de sidecar no estaba
    [habilitada](/es/docs/setup/additional-setup/sidecar-injection/#deploying-an-app) en él.

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. Cree [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) de Kubernetes para almacenar los certificados del servidor y de la CA.

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  Cree un fichero de configuración para el servidor NGINX:

    {{< text bash >}}
    $ cat <<\EOF > ./nginx.conf
    events {
    }

    http {
      log_format main '$remote_addr - $remote_user [$time_local]  $status '
      '"$request" $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log main;
      error_log  /var/log/nginx/error.log;

      server {
        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name my-nginx.mesh-external.svc.cluster.local;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
        ssl_client_certificate /etc/nginx-ca-certs/example.com.crt;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

1.  Cree un [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) de Kubernetes
para contener la configuración del servidor NGINX:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  Despliegue el servidor NGINX:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      namespace: mesh-external
      labels:
        run: my-nginx
    spec:
      ports:
      - port: 443
        protocol: TCP
      selector:
        run: my-nginx
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
      namespace: mesh-external
    spec:
      selector:
        matchLabels:
          run: my-nginx
      replicas: 1
      template:
        metadata:
          labels:
            run: my-nginx
        spec:
          containers:
          - name: my-nginx
            image: nginx
            ports:
            - containerPort: 443
            volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx
              readOnly: true
            - name: nginx-server-certs
              mountPath: /etc/nginx-server-certs
              readOnly: true
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

### Configurar la originación mTLS para el tráfico de salida

1)  Cree un [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) de Kubernetes
    en el **mismo namespace** donde se despliega el egress gateway, para almacenar los certificados del cliente:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl create secret -n istio-system generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
{{< /text >}}

Para admitir la integración con varias herramientas, Istio admite algunos formatos de Secret diferentes.
En este ejemplo, se utiliza un único Secret genérico con las claves `tls.key`, `tls.crt` y `ca.crt`.

{{< tip >}}
{{< boilerplate crl-tip >}}
{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl create secret -n default generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
{{< /text >}}

Para admitir la integración con varias herramientas, Istio admite algunos formatos de Secret diferentes.
En este ejemplo, se utiliza un único Secret genérico con las claves `tls.key`, `tls.crt` y `ca.crt`.

{{< tip >}}
{{< boilerplate crl-tip >}}
{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

2)  Cree un `Gateway` de salida para `my-nginx.mesh-external.svc.cluster.local`, puerto 443, y una regla de destino para
    las solicitudes sidecar que se dirigirán al egress gateway:

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
    - my-nginx.mesh-external.svc.cluster.local
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-nginx
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: nginx
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 443
        tls:
          mode: ISTIO_MUTUAL
          sni: my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx-egressgateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: my-nginx.mesh-external.svc.cluster.local
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: nginx-egressgateway-istio-sds
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - watch
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: nginx-egressgateway-istio-sds
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-egressgateway-istio-sds
subjects:
- kind: ServiceAccount
  name: nginx-egressgateway-istio
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-nginx
spec:
  host: nginx-egressgateway-istio.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: ISTIO_MUTUAL
        sni: my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3) Configure reglas de ruta para dirigir el tráfico a través del egress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-nginx-through-egress-gateway
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
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
        subset: nginx
        port:
          number: 443
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
    route:
    - destination:
        host: my-nginx.mesh-external.svc.cluster.local
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-nginx-to-egress-gateway
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
  gateways:
  - mesh
  http:
  - match:
    - port: 80
    route:
    - destination:
        host: nginx-egressgateway-istio.default.svc.cluster.local
        port:
          number: 443
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-nginx-from-egress-gateway
spec:
  parentRefs:
  - name: nginx-egressgateway
  hostnames:
  - my-nginx.mesh-external.svc.cluster.local
  rules:
  - backendRefs:
    - name: my-nginx
      namespace: mesh-external
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: my-nginx-reference-grant
  namespace: mesh-external
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: default
  to:
    - group: ""
      kind: Service
      name: my-nginx
EOF
{{< /text >}}

TODO: averiguar por qué usar un `HTTPRoute`, en lugar del `VirtualService` anterior, no funciona. Ignora completamente el `HTTPRoute` e intenta pasar al service de destino, lo que agota el tiempo de espera. La única diferencia con el `VirtualService` anterior es que el `VirtualService` generado incluye la anotación: `internal.istio.io/route-semantics": "gateway"`.

{{< /tab >}}

{{< /tabset >}}

4)  Agregue una `DestinationRule` para realizar la originación mTLS:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -n istio-system -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        credentialName: client-credential # this must match the secret created earlier to hold client certs
        sni: my-nginx.mesh-external.svc.cluster.local
        # subjectAltNames: # can be enabled if the certificate was generated with SAN as specified in previous section
        # - my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        credentialName: client-credential # this must match the secret created earlier to hold client certs
        sni: my-nginx.mesh-external.svc.cluster.local
        # subjectAltNames: # can be enabled if the certificate was generated with SAN as specified in previous section
        # - my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< boilerplate auto-san-validation >}}

5)  Verifique que la credencial se suministra al egress gateway y está activa:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl -n istio-system proxy-config secret deploy/istio-egressgateway | grep client-credential
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           16491643791048004260                       2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl proxy-config secret deploy/nginx-egressgateway-istio | grep client-credential
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           16491643791048004260                       2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6)  Envíe una solicitud HTTP a `http://my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

7) Verifique el registro del proxy del egress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Si Istio está desplegado en el namespace `istio-system`, el comando para imprimir el registro es:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain>}}
[2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "my-nginx.mesh-external.svc.cluster.local" "172.21.72.197:443"
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Acceda al registro correspondiente al egress gateway utilizando la etiqueta de pod generada por Istio:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=nginx-egressgateway | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
{{< /text >}}

Debería ver una línea similar a la siguiente:

{{< text plain >}}
[2024-04-08T20:08:18.451Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 615 5 5 "172.30.239.41" "curl/7.87.0-DEV" "86e54df0-6dc3-46b3-a8b8-139474c32a4d" "my-nginx.mesh-external.svc.cluster.local" "172.30.239.57:443" outbound|443||my-nginx.mesh-external.svc.cluster.local 172.30.239.53:48530 172.30.239.53:443 172.30.239.41:53694 my-nginx.mesh-external.svc.cluster.local default.forward-nginx-from-egress-gateway.0
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Limpieza del ejemplo de originación mTLS

1.  Elimine los recursos del servidor mTLS de NGINX:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    {{< /text >}}

1.  Elimine los recursos de configuración del gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete secret client-credential -n istio-system
$ kubectl delete gw istio-egressgateway
$ kubectl delete virtualservice direct-nginx-through-egress-gateway
$ kubectl delete destinationrule -n istio-system originate-mtls-for-nginx
$ kubectl delete destinationrule egressgateway-for-nginx
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete secret client-credential
$ kubectl delete gtw nginx-egressgateway
$ kubectl delete role nginx-egressgateway-istio-sds
$ kubectl delete rolebinding nginx-egressgateway-istio-sds
$ kubectl delete virtualservice direct-nginx-to-egress-gateway
$ kubectl delete httproute forward-nginx-from-egress-gateway
$ kubectl delete destinationrule originate-mtls-for-nginx
$ kubectl delete destinationrule egressgateway-for-nginx
$ kubectl delete referencegrant my-nginx-reference-grant -n mesh-external
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Elimine los certificados y las claves privadas:

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

4)  Elimine los ficheros de configuración generados utilizados en este ejemplo:

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}

## Limpieza

Elimine el service y el despliegue `curl`:

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}

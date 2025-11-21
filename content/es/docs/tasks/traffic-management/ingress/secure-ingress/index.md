---
title: Gateways Seguros
description: Expone un servicio fuera del service mesh sobre TLS o mTLS.
weight: 20
aliases:
    - /docs/tasks/traffic-management/ingress/secure-ingress-sds/
    - /docs/tasks/traffic-management/ingress/secure-ingress-mount/
keywords: [traffic-management,ingress,sds-credentials]
owner: istio/wg-networking-maintainers
test: yes
---

La [tarea de Control de Tráfico de Ingreso](/es/docs/tasks/traffic-management/ingress/ingress-control)
describe cómo configurar un gateway de ingreso para exponer un servicio HTTP al tráfico externo.
Esta tarea muestra cómo exponer un servicio HTTPS seguro usando TLS simple o mutuo.

{{< boilerplate gateway-api-support >}}

## Antes de comenzar

*   Configura Istio siguiendo las instrucciones en la [Guía de instalación](/es/docs/setup/).

*   Inicia la muestra [httpbin]({{< github_tree >}}/samples/httpbin):

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

*   Para usuarios de macOS, verifica que uses `curl` compilado con la biblioteca [LibreSSL](http://www.libressl.org):

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    Si el comando anterior produce una versión de LibreSSL como se muestra, tu comando `curl`
    debería funcionar correctamente con las instrucciones en esta tarea. De lo contrario, intenta
    una implementación diferente de `curl`, por ejemplo en una máquina Linux.

## Generar certificados y claves de cliente y servidor

Esta tarea requiere varios conjuntos de certificados y claves que se usan en los siguientes ejemplos.
Puedes usar tu herramienta favorita para crearlos o usar los comandos a continuación para generarlos usando
[openssl](https://man.openbsd.org/openssl.1).

1.  Crea un certificado raíz y una clave privada para firmar los certificados para tus servicios:

    {{< text bash >}}
    $ mkdir example_certs1
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs1/example.com.key -out example_certs1/example.com.crt
    {{< /text >}}

1.  Genera un certificado y una clave privada para `httpbin.example.com`:

    {{< text bash >}}
    $ openssl req -out example_certs1/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 0 -in example_certs1/httpbin.example.com.csr -out example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Crea un segundo conjunto del mismo tipo de certificados y claves:

    {{< text bash >}}
    $ mkdir example_certs2
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs2/example.com.key -out example_certs2/example.com.crt
    $ openssl req -out example_certs2/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs2/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs2/example.com.crt -CAkey example_certs2/example.com.key -set_serial 0 -in example_certs2/httpbin.example.com.csr -out example_certs2/httpbin.example.com.crt
    {{< /text >}}

1.  Genera un certificado y una clave privada para `helloworld.example.com`:

    {{< text bash >}}
    $ openssl req -out example_certs1/helloworld.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/helloworld.example.com.key -subj "/CN=helloworld.example.com/O=helloworld organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/helloworld.example.com.csr -out example_certs1/helloworld.example.com.crt
    {{< /text >}}

1.  Genera un certificado de cliente y una clave privada:

    {{< text bash >}}
    $ openssl req -out example_certs1/client.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/client.example.com.csr -out example_certs1/client.example.com.crt
    {{< /text >}}

{{< tip >}}
Puedes confirmar que tienes todos los archivos necesarios ejecutando el siguiente comando:

{{< text bash >}}
$ ls example_cert*
example_certs1:
client.example.com.crt          example.com.key                 httpbin.example.com.crt
client.example.com.csr          helloworld.example.com.crt      httpbin.example.com.csr
client.example.com.key          helloworld.example.com.csr      httpbin.example.com.key
example.com.crt                 helloworld.example.com.key

example_certs2:
example.com.crt         httpbin.example.com.crt httpbin.example.com.key
example.com.key         httpbin.example.com.csr
{{< /text >}}

{{< /tip >}}

### Configurar un gateway de ingreso de TLS para un solo host

1.  Crea un secreto para el gateway de ingreso:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs1/httpbin.example.com.key \
      --cert=example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Configura el gateway de ingreso:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Primero, define un gateway con una sección `servers:` para el puerto 443, y especifica valores para
`credentialName` para ser `httpbin-credential`. Los valores son los mismos que el
nombre del secreto. El modo TLS debe tener el valor de `SIMPLE`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: httpbin-credential # must be the same as secret
    hosts:
    - httpbin.example.com
EOF
{{< /text >}}

Luego, configura las rutas de tráfico de ingreso del gateway definiendo un correspondiente
virtual service:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - mygateway
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

Finalmente, sigue [estas instrucciones](/es/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
para establecer las variables `INGRESS_HOST` y `SECURE_INGRESS_PORT` para acceder al gateway.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Primero, crea un [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway):

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

Luego, configura las rutas de tráfico de ingreso del gateway definiendo un correspondiente `HTTPRoute`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
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

Finalmente, obtén la dirección y el puerto del gateway desde el recurso `Gateway`:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw mygateway -n istio-system
$ export INGRESS_HOST=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Envía una solicitud HTTPS para acceder al servicio `httpbin` a través de HTTPS:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
    I'm a teapot!
    ...
    {{< /text >}}

    El servicio `httpbin` devolverá el código [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3).

1)  Cambia las credenciales del gateway eliminando el secreto del gateway y luego recreándolo usando
    diferentes certificados y claves:

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs2/httpbin.example.com.key \
      --cert=example_certs2/httpbin.example.com.crt
    {{< /text >}}

1)  Accede al servicio `httpbin` con `curl` usando la nueva cadena de certificados:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs2/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
    I'm a teapot!
    ...
    {{< /text >}}

1) Si intentas acceder a `httpbin` usando la cadena de certificados anterior, el intento ahora falla:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS alert, Server hello (2):
    * curl: (35) error:04FFF06A:rsa routines:CRYPTO_internal:block type is not 01
    {{< /text >}}

### Configurar un gateway de ingreso de TLS para múltiples hosts

Puedes configurar un gateway de ingreso para múltiples hosts,
`httpbin.example.com` y `helloworld.example.com`, por ejemplo. El gateway de ingreso
está configurado con credenciales únicas correspondientes a cada host.

1.  Restaura las credenciales de `httpbin` del ejemplo anterior eliminando y recreando el secreto
    con los certificados y claves originales:

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs1/httpbin.example.com.key \
      --cert=example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Inicia la muestra `helloworld-v1`:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v1
    {{< /text >}}

1.  Crea un secreto `helloworld-credential`:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls helloworld-credential \
      --key=example_certs1/helloworld.example.com.key \
      --cert=example_certs1/helloworld.example.com.crt
    {{< /text >}}

1.  Configura el gateway de ingreso con hosts `httpbin.example.com` y `helloworld.example.com`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Define un gateway con dos secciones de servidor para el puerto 443. Establece el valor de
`credentialName` en cada puerto a `httpbin-credential` y `helloworld-credential` respectivamente. Establece el modo TLS a `SIMPLE`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https-httpbin
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: httpbin-credential
    hosts:
    - httpbin.example.com
  - port:
      number: 443
      name: https-helloworld
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: helloworld-credential
    hosts:
    - helloworld.example.com
EOF
{{< /text >}}

Configura las rutas de tráfico del gateway definiendo un correspondiente virtual service.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.example.com
  gateways:
  - mygateway
  http:
  - match:
    - uri:
        exact: /hello
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Configura un `Gateway` con dos listeners para el puerto 443. Establece el valor de
`certificateRefs` en cada listener a `httpbin-credential` y `helloworld-credential` respectivamente.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https-httpbin
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
  - name: https-helloworld
    hostname: "helloworld.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: helloworld-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

Configura las rutas de tráfico del gateway para el servicio `helloworld`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["helloworld.example.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5) Envía una solicitud HTTPS a `helloworld.example.com`:

    {{< text bash >}}
    $ curl -v -HHost:helloworld.example.com --resolve "helloworld.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://helloworld.example.com:$SECURE_INGRESS_PORT/hello"
    ...
    HTTP/2 200
    ...
    {{< /text >}}

1) Envía una solicitud HTTPS a `httpbin.example.com` y aún obtienes [HTTP 418](https://datatracker.ietf.org/doc/html/rfc2324) en retorno:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
    server: istio-envoy
    ...
    {{< /text >}}

### Configurar un gateway de ingress de TLS mutuo

Puedes extender la definición del gateway para soportar [TLS mutuo](https://en.wikipedia.org/wiki/Mutual_authentication).

1. Cambia las credenciales del gateway de ingreso eliminando su secreto y creando uno nuevo.
   El servidor usa el certificado de CA para verificar a sus clientes, y debemos usar la clave `ca.crt` para mantener el certificado de CA.

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret generic httpbin-credential \
      --from-file=tls.key=example_certs1/httpbin.example.com.key \
      --from-file=tls.crt=example_certs1/httpbin.example.com.crt \
      --from-file=ca.crt=example_certs1/example.com.crt
    {{< /text >}}

    {{< tip >}}
    {{< boilerplate crl-tip >}}

    El secreto también puede incluir un [OCSP Staple](https://datatracker.ietf.org/doc/html/rfc6961) usando la clave `tls.ocsp-staple` que puede especificarse con un argumento adicional: `--from-file=tls.ocsp-staple=/some/path/to/your-ocsp-staple.pem`.
    {{< /tip >}}

1. Configura el gateway de ingreso:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Cambia la definición del gateway estableciendo el modo TLS a `MUTUAL`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: MUTUAL
      credentialName: httpbin-credential # must be the same as secret
    hosts:
    - httpbin.example.com
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Debido a que el Kubernetes Gateway API no soporta actualmente el terminado de TLS mutuo en un
[Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway),
usamos una opción específica de Istio, `gateway.istio.io/tls-terminate-mode: MUTUAL`,
para configurarlo:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
      options:
        gateway.istio.io/tls-terminate-mode: MUTUAL
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3) Intenta enviar una solicitud HTTPS usando el enfoque anterior y verás cómo falla:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    * TLSv1.3 (OUT), TLS handshake, Client hello (1):
    * TLSv1.3 (IN), TLS handshake, Server hello (2):
    * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
    * TLSv1.3 (IN), TLS handshake, Request CERT (13):
    * TLSv1.3 (IN), TLS handshake, Certificate (11):
    * TLSv1.3 (IN), TLS handshake, CERT verify (15):
    * TLSv1.3 (IN), TLS handshake, Finished (20):
    * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.3 (OUT), TLS handshake, Certificate (11):
    * TLSv1.3 (OUT), TLS handshake, Finished (20):
    * TLSv1.3 (IN), TLS alert, unknown (628):
    * OpenSSL SSL_read: error:1409445C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required, errno 0
    {{< /text >}}

1) Pasa un certificado de cliente y una clave privada a `curl` y vuelve a enviar la solicitud.
   Pasa el certificado de su cliente con la bandera `--cert` y su clave privada
   con la bandera `--key` a `curl`:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt --cert example_certs1/client.example.com.crt --key example_certs1/client.example.com.key \
      "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
    server: istio-envoy
    ...
    I'm a teapot!
    ...
    {{< /text >}}

## Más información

### Formatos de clave

Istio soporta la lectura de varios formatos diferentes de Secret, para soportar la integración con varias herramientas como [cert-manager](/es/docs/ops/integrations/certmanager/):

* Un secreto TLS con claves `tls.key` y `tls.crt`, como se describe anteriormente. Para TLS mutuo, una clave `ca.crt` puede usarse.
* Un secreto TLS con claves `tls.key` y `tls.crt`, como se describe anteriormente. Para TLS mutuo, un secreto genérico separado llamado `<secreto>-cacert`, con una clave `cacert`. Por ejemplo, `httpbin-credential` tiene `tls.key` y `tls.crt`, y `httpbin-credential-cacert` tiene `cacert`.
* Un secreto genérico con claves `key` y `cert`. Para TLS mutuo, una clave `cacert` puede usarse.
* Un secreto genérico con claves `key` y `cert`. Para TLS mutuo, un secreto genérico separado llamado `<secreto>-cacert`, con una clave `cacert`. Por ejemplo, `httpbin-credential` tiene `key` y `cert`, y `httpbin-credential-cacert` tiene `cacert`.
* El valor de la clave `cacert` puede ser un paquete de CA consistente en la concatenación de certificados de CA individuales.

### Enrutamiento de SNI

Un `Gateway` HTTPS realizará [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) coincidencia contra sus hosts configurados
antes de reenviar una solicitud, lo que puede causar que algunas solicitudes fallen.
Ver [configuración de enrutamiento de SNI](/es/docs/ops/common-problems/network-issues/#configuring-sni-routing-when-not-sending-sni) para más detalles.

## Solución de problemas

*   Inspecciona los valores de las variables de entorno `INGRESS_HOST` y `SECURE_INGRESS_PORT`. Asegúrate de que tengan valores válidos, según la salida de los siguientes comandos:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT"
    {{< /text >}}

*   Asegúrate de que el valor de `INGRESS_HOST` sea una dirección IP. En algunas plataformas en la nube, como AWS, podrías
     obtener un nombre de dominio en su lugar. Esta tarea espera una dirección IP, por lo que necesitarás convertirla con comandos
     similares a los siguientes:

    {{< text bash >}}
    $ nslookup ab52747ba608744d8afd530ffd975cbf-330887905.us-east-1.elb.amazonaws.com
    $ export INGRESS_HOST=3.225.207.109
    {{< /text >}}

*   Verifica el log del controlador de gateway por mensajes de error:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl logs -n istio-system <gateway-service-pod>
    {{< /text >}}

*   Si estás usando macOS, verifica que uses `curl` compilado con la biblioteca [LibreSSL](http://www.libressl.org),
    como se describe en la sección [Antes de comenzar](#antes-de-comenzar) anterior.

*   Verifica que los secretos se hayan creado correctamente en el namespace `istio-system`:

    {{< text bash >}}
    $ kubectl -n istio-system get secrets
    {{< /text >}}

    `httpbin-credential` y `helloworld-credential` deberían aparecer en la lista de secretos.

*   Verifica los logs para asegurarte de que el agente de gateway de ingreso haya enviado
    la pareja clave/certificado al gateway de ingreso:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl logs -n istio-system <gateway-service-pod>
    {{< /text >}}

    El log debería mostrar que el secreto `httpbin-credential` fue añadido. Si usas TLS mutuo, entonces el secreto `httpbin-credential-cacert` también debería aparecer.
    Verifica que el log muestre que el agente de gateway recibe solicitudes SDS del gateway de ingreso, que el nombre del recurso es `httpbin-credential`, y que el gateway de ingreso obtiene la pareja clave/certificado. Si usas TLS mutuo, el log debería mostrar
    clave/certificado fue enviado al gateway de ingreso,
    que el agente de gateway recibió la solicitud SDS con el nombre de recurso `httpbin-credential-cacert`, y que el gateway de ingreso obtuvo el certificado raíz.

## Limpieza

1.  Elimina la configuración del gateway y las rutas:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete gateway mygateway
$ kubectl delete virtualservice httpbin helloworld
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -n istio-system gtw mygateway
$ kubectl delete httproute httpbin helloworld
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Elimina los secretos, certificados y claves:

    {{< text bash >}}
    $ kubectl delete -n istio-system secret httpbin-credential helloworld-credential
    $ rm -rf ./example_certs1 ./example_certs2
    {{< /text >}}

1)  Apaga los servicios `httpbin` y `helloworld`:

    {{< text bash >}}
    $ kubectl delete -f samples/httpbin/httpbin.yaml
    $ kubectl delete deployment helloworld-v1
    $ kubectl delete service helloworld
    {{< /text >}}

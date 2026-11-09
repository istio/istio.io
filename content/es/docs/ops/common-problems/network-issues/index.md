---
title: Problemas de gestión de tráfico
description: Técnicas para resolver problemas comunes de gestión de tráfico y de red en Istio.
force_inline_toc: true
weight: 10
aliases:
  - /help/ops/traffic-management/troubleshooting
  - /help/ops/troubleshooting/network-issues
  - /docs/ops/troubleshooting/network-issues
owner: istio/wg-networking-maintainers
test: n/a
---

## Envoy rechaza las solicitudes {#requests-are-rejected-by-envoy}

Las solicitudes pueden rechazarse por varios motivos. La mejor forma de entender por qué se rechazan es
inspeccionar los registros de acceso de Envoy. De forma predeterminada, los registros de acceso se envían a la salida estándar del contenedor.
Ejecuta el siguiente comando para ver el registro:

{{< text bash >}}
$ kubectl logs PODNAME -c istio-proxy -n NAMESPACE
{{< /text >}}

En el formato predeterminado del registro de acceso, los indicadores de respuesta de Envoy aparecen después del código de respuesta;
si usas un formato de registro personalizado, asegúrate de incluir `%RESPONSE_FLAGS%`.

Consulta los [indicadores de respuesta de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags)
para obtener más detalles sobre ellos.

Los indicadores de respuesta más comunes son:

- `NR`: no hay ninguna ruta configurada; revisa tu `DestinationRule` o tu `VirtualService`.
- `UO`: desbordamiento upstream por circuit breaking; revisa la configuración del circuit breaker en la `DestinationRule`.
- `UF`: no se pudo conectar con el upstream; si usas la autenticación de Istio, comprueba si hay un
[conflicto de configuración de TLS mutuo](#503-errors-after-setting-destination-rule).

## Las reglas de enrutamiento no parecen afectar al flujo de tráfico {#route-rules-dont-seem-to-affect-traffic-flow}

Con la implementación actual del sidecar de Envoy, pueden hacer falta hasta 100 solicitudes para que se observe
la distribución ponderada entre versiones.

Si las reglas de enrutamiento funcionan perfectamente con el ejemplo [Bookinfo](/es/docs/examples/bookinfo/),
pero reglas similares de enrutamiento por versión no tienen efecto en tu propia aplicación, puede que
tus servicios de Kubernetes necesiten pequeños cambios.
Los servicios de Kubernetes deben cumplir ciertas restricciones para aprovechar
las funcionalidades de enrutamiento L7 de Istio.
Consulta los [requisitos para pods y servicios](/es/docs/ops/deployment/application-requirements/)
para obtener más detalles.

Otro posible problema es que las reglas de enrutamiento simplemente tarden en surtir efecto.
La implementación de Istio en Kubernetes usa un algoritmo de consistencia eventual
para garantizar que todos los sidecars de Envoy tengan la configuración correcta,
incluidas todas las reglas de enrutamiento. Un cambio de configuración tarda un tiempo
en propagarse a todos los sidecars. En despliegues grandes, la
propagación tarda más y puede haber un retraso del
orden de segundos.

## Errores 503 después de configurar una destination rule {#503-errors-after-setting-destination-rule}

{{< tip >}}
Solo deberías ver este error si deshabilitaste el [TLS mutuo automático](/es/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) durante la instalación.
{{< /tip >}}

Si las solicitudes a un servicio empiezan a generar errores HTTP 503 justo después de aplicar una `DestinationRule`
y los errores continúan hasta que eliminas o reviertes la `DestinationRule`, es probable que la `DestinationRule`
esté causando un conflicto de TLS para el servicio.

Por ejemplo, si configuras TLS mutuo de forma global en el clúster, la `DestinationRule` debe incluir la siguiente `trafficPolicy`:

{{< text yaml >}}
trafficPolicy:
  tls:
    mode: ISTIO_MUTUAL
{{< /text >}}

De lo contrario, el modo toma el valor predeterminado `DISABLE`, lo que hace que los sidecar proxies del cliente envíen solicitudes HTTP en texto plano
en lugar de solicitudes cifradas con TLS. Por lo tanto, las solicitudes entran en conflicto con el proxy del servidor, porque este espera
solicitudes cifradas.

Siempre que apliques una `DestinationRule`, asegúrate de que el modo TLS de la `trafficPolicy` coincida con la configuración global del servidor.

## Las reglas de enrutamiento no tienen efecto en las solicitudes del ingress gateway {#route-rules-have-no-effect-on-ingress-gateway-requests}

Supongamos que usas un `Gateway` de ingress y el `VirtualService` correspondiente para acceder a un servicio interno.
Por ejemplo, tu `VirtualService` se parece a esto:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # or maybe "*" if you are testing without DNS using the ingress-gateway IP (e.g., http://1.2.3.4/hello)
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

También tienes un `VirtualService` que enruta el tráfico del servicio helloworld a un subconjunto concreto:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

En esta situación, verás que las solicitudes al servicio helloworld a través del ingress gateway
no se dirigen al subconjunto v1, sino que siguen usando el enrutamiento round-robin predeterminado.

Las solicitudes de ingress usan el host del gateway (p. ej., `myapp.com`),
lo que activa las reglas del `VirtualService` myapp, que enruta a cualquier endpoint del servicio helloworld.
Solo las solicitudes internas con el host `helloworld.default.svc.cluster.local` usan el
`VirtualService` helloworld, que dirige el tráfico exclusivamente al subconjunto v1.

Para controlar el tráfico que llega desde el gateway, también debes incluir la regla del subconjunto en el `VirtualService` myapp:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # or maybe "*" if you are testing without DNS using the ingress-gateway IP (e.g., http://1.2.3.4/hello)
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    ...
{{< /text >}}

Como alternativa, si es posible, puedes combinar ambos `VirtualServices` en una sola unidad:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com # cannot use "*" here since this is being combined with the mesh services
  - helloworld.default.svc.cluster.local
  gateways:
  - mesh # applies internally as well as externally
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
      gateways:
      - myapp-gateway #restricts this rule to apply only to ingress gateway
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    - gateways:
      - mesh # applies to all services inside the mesh
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

## Envoy falla bajo carga {#envoy-is-crashing-under-load}

Revisa tu `ulimit -a`. Muchos sistemas tienen por defecto un límite de 1024 descriptores de archivo abiertos, lo que hará que una aserción de Envoy falle y que Envoy se cierre con:

{{< text plain >}}
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
{{< /text >}}

Asegúrate de aumentar tu ulimit. Ejemplo: `ulimit -n 16384`

## Envoy no se conecta a mi servicio HTTP/1.0 {#envoy-wont-connect-to-my-http10-service}

Envoy requiere tráfico `HTTP/1.1` o `HTTP/2` para los servicios upstream. Por ejemplo, si usas [NGINX](https://www.nginx.com/) para servir tráfico detrás de Envoy,
tendrás que establecer la directiva [proxy_http_version](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version) en tu configuración de NGINX con el valor "1.1", ya que el valor predeterminado de NGINX es 1.0.

Configuración de ejemplo:

{{< text plain >}}
upstream http_backend {
    server 127.0.0.1:8080;

    keepalive 16;
}

server {
    ...

    location /http/ {
        proxy_pass http://http_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        ...
    }
}
{{< /text >}}

## Error 503 al acceder a servicios headless {#503-error-while-accessing-headless-services}

Supongamos que Istio está instalado con la siguiente configuración:

- `mTLS mode` establecido en `STRICT` dentro de la mesh
- `meshConfig.outboundTrafficPolicy.mode` establecido en `ALLOW_ANY`

Considera que `nginx` está desplegado como un `StatefulSet` en el namespace default y que hay un `Headless Service` correspondiente definido como se muestra a continuación:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: http-web  # Explicitly defining an http port
  clusterIP: None   # Creates a Headless Service
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx
  serviceName: "nginx"
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
{{< /text >}}

El nombre de puerto `http-web` en la definición del Service especifica explícitamente el protocolo http para ese puerto.

Supongamos que también tenemos un `Deployment` del pod [curl]({{< github_tree >}}/samples/curl) en el namespace default.
Cuando se accede a `nginx` desde este pod `curl` usando su IP de pod (una de las formas habituales de acceder a un servicio headless), la solicitud pasa por el `PassthroughCluster` hasta el lado del servidor, pero el sidecar proxy del lado del servidor no encuentra la entrada de ruta hacia `nginx` y falla con `HTTP 503 UC`.

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
$ kubectl exec -it $SOURCE_POD -c curl -- curl 10.1.1.171 -s -o /dev/null -w "%{http_code}"
  503
{{< /text >}}

`10.1.1.171` es la IP de pod de una de las réplicas de `nginx`, y se accede al servicio en el `containerPort` 80.

Estas son algunas formas de evitar este error 503:

1. Especifica la cabecera Host correcta:

    De forma predeterminada, la cabecera Host de la solicitud curl anterior es la IP del pod. Si especificas `nginx.default` como cabecera Host en nuestra solicitud a `nginx`, se devuelve correctamente `HTTP 200 OK`.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c curl -- curl -H "Host: nginx.default" 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

1. Establece el nombre del puerto en `tcp`, `tcp-web` o `tcp-<custom_name>`:

    Aquí el protocolo se especifica explícitamente como `tcp`. En este caso, solo se usa el filtro de red `TCP Proxy` del sidecar proxy, tanto en el lado del cliente como en el del servidor. El HTTP Connection Manager no se usa en absoluto y, por lo tanto, no se espera ningún tipo de cabecera en la solicitud.

    Una solicitud a `nginx`, con o sin la cabecera Host establecida explícitamente, devuelve correctamente `HTTP 200 OK`.

    Esto resulta útil en ciertos escenarios en los que un cliente no puede incluir información de cabeceras en la solicitud.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c curl -- curl 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c curl -- curl -H "Host: nginx.default" 10.1.1.171 -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

1. Usa el nombre de dominio en lugar de la IP del pod:

    También se puede acceder a una instancia concreta de un servicio headless usando solo el nombre de dominio.

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    $ kubectl exec -it $SOURCE_POD -c curl -- curl web-0.nginx.default -s -o /dev/null -w "%{http_code}"
      200
    {{< /text >}}

    Aquí, `web-0` es el nombre del pod de una de las 3 réplicas de `nginx`.

Consulta la página de [enrutamiento de tráfico](/es/docs/ops/configuration/traffic-management/traffic-routing/) para obtener más información sobre los servicios headless y el comportamiento del enrutamiento de tráfico con distintos protocolos.

## Errores de configuración de TLS {#tls-configuration-mistakes}

Muchos problemas de gestión de tráfico
se deben a una [configuración de TLS](/es/docs/ops/configuration/traffic-management/tls-configuration/) incorrecta.
Las siguientes secciones describen algunos de los errores de configuración más comunes.

### Enviar HTTPS a un puerto HTTP {#sending-https-to-an-http-port}

Si tu aplicación envía una solicitud HTTPS a un servicio declarado como HTTP,
el sidecar de Envoy intentará analizar la solicitud como HTTP al reenviarla,
lo que fallará porque el HTTP está cifrado de forma inesperada.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: http
    protocol: HTTP
  resolution: DNS
{{< /text >}}

Aunque la configuración anterior puede ser correcta si envías texto plano a propósito por el puerto 443 (p. ej., `curl http://httpbin.org:443`),
por lo general el puerto 443 se reserva para el tráfico HTTPS.

Enviar una solicitud HTTPS como `curl https://httpbin.org`, que usa el puerto 443 de forma predeterminada, producirá un error como
`curl: (35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`.
Los registros de acceso también pueden mostrar un error como `400 DPE`.

Para solucionarlo, cambia el protocolo del puerto a HTTPS:

{{< text yaml >}}
spec:
  ports:
  - number: 443
    name: https
    protocol: HTTPS
{{< /text >}}

### Discrepancia de TLS entre el gateway y el virtual service {#gateway-mismatch}

Hay dos discrepancias de TLS habituales que pueden producirse al vincular un virtual service a un gateway.

1. El gateway termina TLS mientras que el virtual service configura enrutamiento TLS.
1. El gateway hace TLS passthrough mientras que el virtual service configura enrutamiento HTTP.

#### Gateway con terminación TLS {#gateway-with-tls-termination}

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
      - "*"
    tls:
      mode: SIMPLE
      credentialName: sds-credential
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*.example.com"
  gateways:
  - istio-system/gateway
  tls:
  - match:
    - sniHosts:
      - "*.example.com"
    route:
    - destination:
        host: httpbin.org
{{< /text >}}

En este ejemplo, el gateway termina TLS (la configuración `tls.mode` del gateway es `SIMPLE`,
no `PASSTHROUGH`) mientras que el virtual service usa enrutamiento basado en TLS. Las reglas de enrutamiento se evalúan
después de que el gateway termine TLS, por lo que la regla TLS no tendrá efecto, ya que la
solicitud es entonces HTTP en lugar de HTTPS.

Con esta configuración incorrecta, acabarás recibiendo respuestas 404, porque las solicitudes se
envían al enrutamiento HTTP, pero no hay rutas HTTP configuradas.
Puedes confirmarlo con el comando `istioctl proxy-config routes`.

Para solucionar este problema, cambia el virtual service para que especifique enrutamiento `http` en lugar de `tls`:

{{< text yaml >}}
spec:
  ...
  http:
  - match:
    - headers:
        ":authority":
          regex: "*.example.com"
{{< /text >}}

#### Gateway con TLS passthrough {#gateway-with-tls-passthrough}

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - "*"
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: virtual-service
spec:
  gateways:
  - gateway
  hosts:
  - httpbin.example.com
  http:
  - route:
    - destination:
        host: httpbin.org
{{< /text >}}

En esta configuración, el virtual service intenta hacer coincidir tráfico HTTP con el tráfico TLS que pasa a través del gateway.
Como resultado, la configuración del virtual service no tiene ningún efecto. Puedes comprobar que la ruta HTTP no se aplica con
los comandos `istioctl proxy-config listener` e `istioctl proxy-config route`.

Para solucionarlo, cambia el virtual service para que configure enrutamiento `tls`:

{{< text yaml >}}
spec:
  tls:
  - match:
    - sniHosts: ["httpbin.example.com"]
    route:
    - destination:
        host: httpbin.org
{{< /text >}}

Como alternativa, puedes terminar TLS en lugar de dejarlo pasar, cambiando la configuración `tls` del gateway:

{{< text yaml >}}
spec:
  ...
    tls:
      credentialName: sds-credential
      mode: SIMPLE
{{< /text >}}

### TLS doble (originación de TLS para una solicitud TLS) {#double-tls}

Al configurar Istio para realizar {{< gloss >}}TLS origination{{< /gloss >}}, debes asegurarte de
que la aplicación envíe solicitudes en texto plano al sidecar, que será el que origine el TLS.

La siguiente `DestinationRule` origina TLS para las solicitudes al servicio `httpbin.org`,
pero el `ServiceEntry` correspondiente define el protocolo como HTTPS en el puerto 443.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: originate-tls
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
{{< /text >}}

Con esta configuración, el sidecar espera que la aplicación envíe tráfico TLS por el puerto 443
(p. ej., `curl https://httpbin.org`), pero también realizará la originación de TLS antes de reenviar las solicitudes.
Esto hará que las solicitudes se cifren dos veces.

Por ejemplo, enviar una solicitud como `curl https://httpbin.org` producirá un error:
`(35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number`.

Puedes corregir este ejemplo cambiando a HTTP el protocolo del puerto en el `ServiceEntry`:

{{< text yaml >}}
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 443
    name: http
    protocol: HTTP
{{< /text >}}

Ten en cuenta que, con esta configuración, tu aplicación tendrá que enviar solicitudes en texto plano al puerto 443,
como `curl http://httpbin.org:443`, porque la originación de TLS no cambia el puerto.
Sin embargo, a partir de Istio 1.8, puedes exponer el puerto HTTP 80 a la aplicación (p. ej., `curl http://httpbin.org`)
y luego redirigir las solicitudes al `targetPort` 443 para la originación de TLS:

{{< text yaml >}}
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
{{< /text >}}

### Errores 404 cuando varios gateways se configuran con el mismo certificado TLS {#404-errors-occur-when-multiple-gateways-configured-with-same-tls-certificate}

Configurar más de un gateway con el mismo certificado TLS hará que los navegadores
que aprovechan la [reutilización de conexiones de HTTP/2](https://httpwg.org/specs/rfc7540.html#reuse)
(es decir, la mayoría de los navegadores) produzcan errores 404 al acceder a un segundo host después de que
ya se haya establecido una conexión con otro host.

Por ejemplo, supongamos que tienes 2 hosts que comparten el mismo certificado TLS de esta forma:

- Certificado comodín `*.test.com` instalado en `istio-ingressgateway`
- Configuración de `Gateway` `gw1` con host `service1.test.com`, selector `istio: ingressgateway` y TLS con el certificado (comodín) montado en el gateway
- Configuración de `Gateway` `gw2` con host `service2.test.com`, selector `istio: ingressgateway` y TLS con el certificado (comodín) montado en el gateway
- Configuración de `VirtualService` `vs1` con host `service1.test.com` y gateway `gw1`
- Configuración de `VirtualService` `vs2` con host `service2.test.com` y gateway `gw2`

Como ambos gateways los sirve el mismo workload (es decir, el selector `istio: ingressgateway`), las solicitudes a ambos servicios
(`service1.test.com` y `service2.test.com`) se resuelven a la misma IP. Si primero se accede a `service1.test.com`, este
devuelve el certificado comodín (`*.test.com`), lo que indica que las conexiones a `service2.test.com` pueden usar el mismo certificado.
En consecuencia, navegadores como Chrome y Firefox reutilizan la conexión existente para las solicitudes a `service2.test.com`.
Como el gateway (`gw1`) no tiene ninguna ruta para `service2.test.com`, devuelve una respuesta 404 (Not Found).

Puedes evitar este problema configurando un único `Gateway` comodín, en lugar de dos (`gw1` y `gw2`).
Después, simplemente vincula ambos `VirtualServices` a él de esta forma:

- Configuración de `Gateway` `gw` con host `*.test.com`, selector `istio: ingressgateway` y TLS con el certificado (comodín) montado en el gateway
- Configuración de `VirtualService` `vs1` con host `service1.test.com` y gateway `gw`
- Configuración de `VirtualService` `vs2` con host `service2.test.com` y gateway `gw`

### Configurar enrutamiento SNI cuando no se envía SNI {#configuring-sni-routing-when-not-sending-sni}

Un `Gateway` HTTPS que especifica el campo `hosts` realiza una coincidencia de [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) en las solicitudes entrantes.
Por ejemplo, la siguiente configuración solo permitiría solicitudes que coincidan con `*.example.com` en el SNI:

{{< text yaml >}}
servers:
- port:
    number: 443
    name: https
    protocol: HTTPS
  hosts:
  - "*.example.com"
{{< /text >}}

Esto puede hacer que algunas solicitudes fallen.

Por ejemplo, si no tienes DNS configurado y, en su lugar, estableces directamente la cabecera host, como en `curl 1.2.3.4 -H "Host: app.example.com"`, no se establecerá ningún SNI y la solicitud fallará.
En su lugar, puedes configurar DNS o usar la opción `--resolve` de `curl`. Consulta la tarea [Gateways seguros](/es/docs/tasks/traffic-management/ingress/secure-ingress/) para obtener más información.

Otro problema habitual son los balanceadores de carga situados delante de Istio.
La mayoría de los balanceadores de carga en la nube no reenvían el SNI, así que, si terminas TLS en tu balanceador de carga en la nube, puede que tengas que hacer una de estas cosas:

- Configurar el balanceador de carga en la nube para que, en su lugar, haga passthrough de la conexión TLS
- Deshabilitar la coincidencia de SNI en el `Gateway` estableciendo el campo hosts en `*`

Un síntoma habitual de esto es que las comprobaciones de estado del balanceador de carga funcionan mientras que el tráfico real falla.

## Una configuración de filtro de Envoy sin cambios deja de funcionar de repente {#unchanged-envoy-filter-configuration-suddenly-stops-working}

Una configuración de `EnvoyFilter` que especifica una posición de inserción relativa a otro filtro puede ser muy
frágil porque, de forma predeterminada, el orden de evaluación se basa en la hora de creación de los filtros.
Considera un filtro con la siguiente especificación:

{{< text yaml >}}
spec:
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        portNumber: 443
        filterChain:
          filter:
            name: istio.stats
    patch:
      operation: INSERT_BEFORE
      value:
        ...
{{< /text >}}

Para funcionar correctamente, esta configuración de filtro depende de que el filtro `istio.stats` se haya creado
antes que ella. De lo contrario, la operación `INSERT_BEFORE` se ignorará sin avisar. No habrá nada en el
registro de errores que indique que este filtro no se ha añadido a la cadena.

Esto es especialmente problemático al hacer coincidir filtros que son específicos de una versión, como `istio.stats`
(es decir, que incluyen el campo `proxyVersion` en sus criterios de coincidencia). Estos filtros pueden eliminarse
o sustituirse por otros más recientes al actualizar Istio. Como resultado, un `EnvoyFilter` como el anterior puede
funcionar perfectamente al principio, pero, tras actualizar Istio a una versión más reciente, dejará de incluirse en la cadena
de filtros de red de los sidecars.

Para evitar este problema, puedes cambiar la operación por una que no dependa de la presencia de
otro filtro (p. ej., `INSERT_FIRST`), o establecer una prioridad explícita en el `EnvoyFilter` para anular el
orden predeterminado basado en la hora de creación. Por ejemplo, añadir `priority: 10` al filtro anterior garantiza
que se procese después del filtro `istio.stats`, que tiene una prioridad predeterminada de 0.

## Un virtual service con inyección de fallos y políticas de reintento/timeout no funciona como se espera {#virtual-service-with-fault-injection-and-retrytimeout-policies-not-working-as-expected}

Actualmente, Istio no admite configurar inyecciones de fallos y políticas de reintento o timeout en el
mismo `VirtualService`. Considera la siguiente configuración:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - "*"
  gateways:
  - helloworld-gateway
  http:
  - match:
    - uri:
        exact: /hello
    fault:
      abort:
        httpStatus: 500
        percentage:
          value: 50
    retries:
      attempts: 5
      retryOn: 5xx
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
{{< /text >}}

Cabría esperar que, con los cinco reintentos configurados, el usuario casi nunca viera
errores al llamar al servicio `helloworld`. Sin embargo, como tanto el fallo como los reintentos están configurados en
el mismo `VirtualService`, la configuración de reintentos no surte efecto y se obtiene una tasa de fallos
del 50 %. Para solucionar este problema, puedes eliminar la configuración del fallo de tu `VirtualService` e
inyectar el fallo en el proxy Envoy upstream con un `EnvoyFilter`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: hello-world-filter
spec:
  workloadSelector:
    labels:
      app: helloworld
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND # will match outbound listeners in all sidecars
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.fault
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.fault.v3.HTTPFault"
          abort:
            http_status: 500
            percentage:
              numerator: 50
              denominator: HUNDRED
{{< /text >}}

Esto funciona porque, de esta forma, la política de reintentos se configura en el proxy del cliente, mientras que la
inyección de fallos se configura en el proxy upstream.

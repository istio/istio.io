---
title: Política de Autenticación
description: Muestra cómo usar la política de autenticación de Istio para configurar mTLS y la autenticación básica de usuario final.
weight: 10
keywords: [security,authentication]
aliases:
    - /docs/tasks/security/istio-auth.html
    - /docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea cubre las actividades principales que podría necesitar realizar al habilitar, configurar y usar las políticas de autenticación de Istio. Obtenga más información sobre
los conceptos subyacentes en la [descripción general de la autenticación](/es/docs/concepts/security/#authentication).

## Antes de empezar

* Comprenda la [política de autenticación](/es/docs/concepts/security/#authentication-policies) de Istio y los conceptos relacionados de
[autenticación mTLS](/es/docs/concepts/security/#mutual-tls-authentication).

* Instale Istio en un cluster de Kubernetes con el perfil de configuración `default`, como se describe en los
pasos de [instalación](/es/docs/setup/getting-started).

{{< text bash >}}
$ istioctl install --set profile=default
{{< /text >}}

### Configuración

Nuestros ejemplos utilizan dos namespaces `foo` y `bar`, con dos services, `httpbin` y `curl`, ambos ejecutándose con un proxy Envoy. También utilizamos segundas
instancias de `httpbin` y `curl` ejecutándose sin el sidecar en el namespace `legacy`. Si desea utilizar los mismos ejemplos al probar las tareas,
ejecute lo siguiente:

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n bar
$ kubectl create ns legacy
$ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
$ kubectl apply -f @samples/curl/curl.yaml@ -n legacy
{{< /text >}}

Puede verificar la configuración enviando una solicitud HTTP con `curl` desde cualquier pod `curl` en el namespace `foo`, `bar` o `legacy` a `httpbin.foo`,
`httpbin.bar` o `httpbin.legacy`. Todas las solicitudes deberían tener éxito con el código HTTP 200.

Por ejemplo, aquí hay un comando para verificar la accesibilidad de `curl.bar` a `httpbin.foo`:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n bar -o jsonpath={.items..metadata.name})" -c curl -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{\n"http_code}
"
200
{{< /text >}}

Este comando de una sola línea itera convenientemente a través de todas las combinaciones de accesibilidad:

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl -s "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{\n"http_code}
""; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
curl.legacy to httpbin.legacy: 200
{{< /text >}}

Verifique que no haya ninguna política de autenticación de pares en el sistema con el siguiente comando:

{{< text bash >}}
$ kubectl get peerauthentication --all-namespaces
No resources found
{{< /text >}}

Por último, pero no menos importante, verifique que no haya reglas de destino que se apliquen a los services de ejemplo. Puede hacerlo comprobando el valor `host:` de
las reglas de destino existentes y asegurándose de que no coincidan. Por ejemplo:

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"

{{< /text >}}

{{< tip >}}
Dependiendo de la versión de Istio, es posible que vea reglas de destino para hosts distintos de los mostrados. Sin embargo, no debería haber ninguna con hosts en los namespaces `foo`,
`bar` y `legacy`, ni el comodín `*` que coincide con todo.
{{< /tip >}}

## mTLS automático

Por defecto, Istio rastrea los workloads del servidor migrados a los proxies de Istio, y configura los proxies del cliente para enviar tráfico mTLS a esos workloads automáticamente, y para enviar tráfico de texto plano a los workloads sin sidecars.

Así, todo el tráfico entre workloads con proxies utiliza mTLS, sin que usted haga
nada. Por ejemplo, tome la respuesta de una solicitud a `httpbin/header`.
Cuando se utiliza mTLS, el proxy inyecta la cabecera `X-Forwarded-Client-Cert` a la
solicitud ascendente al backend. La presencia de esa cabecera es una prueba de que se utiliza mTLS.
Por ejemplo:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl -s http://httpbin.foo:8000/headers -s | jq '.headers["X-Forwarded-Client-Cert"][0]' | sed 's/Hash=[a-z0-9]*;/Hash=<redacted>;/'
  "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=<redacted>;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/curl"
{{< /text >}}

Cuando el servidor no tiene sidecar, la cabecera `X-Forwarded-Client-Cert` no está presente, lo que implica que las solicitudes están en texto plano.

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.legacy:8000/headers -s | grep X-Forwarded-Client-Cert

{{< /text >}}

## Habilitar globalmente mTLS de Istio en modo STRICT

Aunque Istio actualiza automáticamente todo el tráfico entre los proxies y los workloads a mTLS,
los workloads aún pueden recibir tráfico de texto plano. Para evitar el tráfico no mTLS para toda la malla,
establezca una política de autenticación de pares a nivel de malla con el modo mTLS establecido en `STRICT`.
La política de autenticación de pares a nivel de malla no debe tener un `selector` y debe aplicarse en el **namespace raíz**, por ejemplo:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

{{< tip >}}
El ejemplo asume que `istio-system` es el namespace raíz. Si usó un valor diferente durante la instalación, reemplace `istio-system` con el valor que usó.
 {{< /tip >}}

Esta política de autenticación de pares configura los workloads para que solo acepten solicitudes cifradas con TLS.
Dado que no especifica un valor para el campo `selector`, la política se aplica a todos los workloads de la malla.

Ejecute el comando de prueba de nuevo:

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{\n"http_code}
""; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
curl.legacy to httpbin.legacy: 200
{{< /text >}}

Verá que las solicitudes siguen teniendo éxito, excepto las del cliente que no tiene proxy, `curl.legacy`, al servidor con un proxy, `httpbin.foo` o `httpbin.bar`. Esto es de esperar porque ahora se requiere estrictamente mTLS, pero el workload sin sidecar no puede cumplir.

### Limpieza parte 1

Elimine la política de autenticación global agregada en la sesión:

{{< text bash >}}
$ kubectl delete peerauthentication -n istio-system default
{{< /text >}}

## Habilitar mTLS por namespace o workload

### Política a nivel de namespace

Para cambiar mTLS para todos los workloads dentro de un namespace particular, use una política a nivel de namespace. La especificación de la política es la misma que para una política a nivel de malla, pero especifica el namespace al que se aplica en `metadata`. Por ejemplo, la siguiente política de autenticación de pares habilita mTLS estricto para el namespace `foo`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Como esta política se aplica solo a los workloads en el namespace `foo`, solo debería ver que las solicitudes del cliente sin sidecar (`curl.legacy`) a `httpbin.foo` comienzan a fallar.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{\n"http_code}
""; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 200
curl.legacy to httpbin.legacy: 200
{{< /text >}}

### Habilitar mTLS por workload

Para establecer una política de autenticación de pares para un workload específico, debe configurar la sección `selector` y especificar las etiquetas que coincidan con el workload deseado. Por ejemplo, la siguiente política de autenticación de pares habilita mTLS estricto para el workload `httpbin.bar`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
EOF
{{< /text >}}

De nuevo, ejecute el comando de sondeo. Como era de esperar, la solicitud de `curl.legacy` a `httpbin.bar` comienza a fallar por las mismas razones.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{\n"http_code}
""; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
curl.legacy to httpbin.legacy: 200
{{< /text >}}

{{< text plain >}}
...
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

Para refinar la configuración de mTLS por puerto, debe configurar la sección `portLevelMtls`. Por ejemplo, la siguiente política de autenticación de pares requiere mTLS en todos los puertos, excepto el puerto `8080`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    8080:
      mode: DISABLE
EOF
{{< /text >}}

1. El valor del puerto en la política de autenticación de pares es el puerto del contenedor.
1. Solo puede usar `portLevelMtls` si el puerto está vinculado a un service. Istio lo ignora de lo contrario.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{\n"http_code}
""; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 200
curl.legacy to httpbin.legacy: 200
{{< /text >}}

### Precedencia de políticas

Una política de autenticación de pares específica de workload tiene precedencia sobre una política a nivel de namespace. Puede probar este comportamiento si agrega una política para deshabilitar mTLS para el workload `httpbin.foo`, por ejemplo.
Tenga en cuenta que ya ha creado una política a nivel de namespace que habilita mTLS para todos los services en el namespace `foo` y observe que las solicitudes de
`curl.legacy` a `httpbin.foo` están fallando (ver arriba).

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "overwrite-example"
  namespace: "foo"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: DISABLE
EOF
{{< /text >}}

Al volver a ejecutar la solicitud de `curl.legacy`, debería ver un código de retorno de éxito de nuevo (200), lo que confirma que la política específica del service anula la política a nivel de namespace.

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n legacy -o jsonpath={.items..metadata.name})" -c curl -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{\n"http_code}
"
200
{{< /text >}}

### Limpieza parte 2

Elimine las políticas creadas en los pasos anteriores:

{{< text bash >}}
$ kubectl delete peerauthentication default overwrite-example -n foo
$ kubectl delete peerauthentication httpbin -n bar
{{< /text >}}

## Autenticación de usuario final

Para experimentar con esta feature, necesita un JWT válido. El JWT debe corresponder al endpoint JWKS que desea utilizar para la demostración. Este tutorial utiliza el token de prueba [JWT test]({{< github_file >}}/security/tools/jwt/samples/demo.jwt) y
el [endpoint JWKS]({{< github_file >}}/security/tools/jwt/samples/jwks.json) de la base de código de Istio.

Además, para mayor comodidad, exponga `httpbin.foo` a través de un ingress gateway (para más detalles, consulte la [tarea de ingress](/es/docs/tasks/traffic-management/ingress/)).

{{< boilerplate gateway-api-support >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Configure el gateway:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
{{< /text >}}

Siga las instrucciones en
[Determinación de la IP y los puertos de ingress](/es/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
para definir las variables de entorno `INGRESS_PORT` e `INGRESS_HOST`.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Cree el gateway:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@ -n foo
$ kubectl wait --for=condition=programmed gtw -n foo httpbin-gateway
{{< /text >}}

Establezca las variables de entorno `INGRESS_PORT` e `INGRESS_HOST`:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Ejecute una consulta de prueba a través del gateway:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{\n"http_code}
"
200
{{< /text >}}

Ahora, agregue una política de autenticación de solicitudes que requiera JWT de usuario final para el ingress gateway.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Aplique la política en el namespace del workload que selecciona, el ingress gateway en este caso.

Si proporciona un token en la cabecera de autorización, su ubicación predeterminada implícita, Istio valida el token utilizando el [conjunto de claves públicas]({{< github_file >}}/security/tools/jwt/samples/jwks.json), y rechaza las solicitudes si el token de portador no es válido. Sin embargo, las solicitudes sin tokens son aceptadas. Para observar este comportamiento, reintente la solicitud sin un token, con un token incorrecto y con un token válido:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{\n"http_code}
"
200
{{< /text >}}

{{< text bash >}}
$ curl --header "Authorization: Bearer deadbeef" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{\n"http_code}
"
401
{{< /text >}}

{{< text bash >}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{\n"http_code}
"
200
{{< /text >}}

Para observar otros aspectos de la validación de JWT, use el script [`gen-jwt.py`]({{< github_tree >}}/security/tools/jwt/samples/gen-jwt.py) para
generar nuevos tokens para probar con diferentes emisores, audiencias, fechas de vencimiento, etc. El script se puede descargar del repositorio de Istio:

{{< text bash >}}
$ wget --no-verbose {{< github_file >}}/security/tools/jwt/samples/gen-jwt.py
{{< /text >}}

También necesita el fichero `key.pem`:

{{< text bash >}}
$ wget --no-verbose {{< github_file >}}/security/tools/jwt/samples/key.pem
{{< /text >}}

{{< tip >}}
Descargue la biblioteca [jwcrypto](https://pypi.org/project/jwcrypto),
si no la ha instalado en su sistema.
{{< /tip >}}

La autenticación JWT tiene un sesgo de reloj de 60 segundos, lo que significa que el token JWT será válido 60 segundos antes de su `nbf` configurado y seguirá siendo válido 60 segundos después de su `exp` configurado.

Por ejemplo, el comando siguiente crea un token que
expira en 5 segundos. Como ve, Istio autentica las solicitudes utilizando ese token con éxito al principio, pero las rechaza después de 65 segundos:

{{< text bash >}}
$ TOKEN=$(python3 ./gen-jwt.py ./key.pem --expire 5)
$ for i in $(seq 1 10); do curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{\n"http_code}
""; sleep 10; done
200
200
200
200
200
200
200
401
401
401
{{< /text >}}

También puede agregar una política JWT a un ingress gateway (por ejemplo, el service `istio-ingressgateway.istio-system.svc.cluster.local`).
Esto se usa a menudo para definir una política JWT para todos los services vinculados al gateway, en lugar de para services individuales.

### Requerir un token válido

Para rechazar solicitudes sin tokens válidos, agregue una política de autorización con una regla que especifique una acción `DENY` para solicitudes sin principales de solicitud, mostradas como `notRequestPrincipals: ["*"]` en el siguiente ejemplo. Los principales de solicitud solo están disponibles cuando se proporcionan tokens JWT válidos. Por lo tanto, la regla deniega las solicitudes sin tokens válidos.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Reintente la solicitud sin un token. La solicitud ahora falla con el código de error `403`:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{\n"http_code}
"
403
{{< /text >}}

### Requerir tokens válidos por ruta

Para refinar la autorización con un requisito de token por host, ruta o método, cambie la política de autorización para que solo requiera JWT en `/headers`. Cuando esta regla de autorización surte efecto, las solicitudes a `$INGRESS_HOST:$INGRESS_PORT/headers` fallan con el código de error `403`. Las solicitudes a todas las demás rutas tienen éxito, por ejemplo `$INGRESS_HOST:$INGRESS_PORT/ip`.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{\n"http_code}
"
403
{{< /text >}}

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/ip" -s -o /dev/null -w "%{\n"http_code}
"
200
{{< /text >}}

### Limpieza parte 3

1. Elimine la política de autenticación:

    {{< text bash >}}
    $ kubectl -n istio-system delete requestauthentication jwt-example
    {{< /text >}}

1. Elimine la política de autorización:

    {{< text bash >}}
    $ kubectl -n istio-system delete authorizationpolicy frontend-ingress
    {{< /text >}}

1. Elimine el script generador de tokens y el fichero de claves:

    {{< text bash >}}
    $ rm -f ./gen-jwt.py ./key.pem
    {{< /text >}}

1. Si no planea explorar ninguna tarea de seguimiento, puede eliminar todos los recursos simplemente eliminando los namespaces de prueba.

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    {{< /text >}}

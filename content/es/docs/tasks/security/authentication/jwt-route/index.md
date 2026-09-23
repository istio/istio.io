---
title: Enrutamiento basado en claims JWT
description: Muestra cómo usar la política de autenticación de Istio para enrutar solicitudes basadas en claims JWT.
weight: 10
keywords: [security,authentication,jwt,route]
owner: istio/wg-security-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Esta tarea muestra cómo enrutar solicitudes basadas en claims JWT en un ingress gateway de Istio utilizando la autenticación de solicitudes
y el virtual service.

Nota: esta feature solo admite ingress gateway de Istio y requiere el uso tanto de la autenticación de solicitudes como del virtual
service para validar y enrutar correctamente basándose en los claims JWT.

## Antes de empezar

* Comprenda la [política de autenticación](/es/docs/concepts/security/#authentication-policies) de Istio y los conceptos de [virtual service](/es/docs/concepts/traffic-management/#virtual-services).

* Instale Istio utilizando la [guía de instalación de Istio](/es/docs/setup/install/istioctl/).

* Despliegue un workload, `httpbin` en un namespace, por ejemplo `foo`, y expóngalo a través del ingress gateway de Istio con este comando:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
    {{< /text >}}

*  Siga las instrucciones en
   [Determinación de la IP y los puertos de ingress](/es/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
   para definir las variables de entorno `INGRESS_HOST` e `INGRESS_PORT`.

* Verifique que el workload `httpbin` y el ingress gateway funcionan como se espera utilizando este comando:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{\http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
Si no ve la salida esperada, inténtelo de nuevo después de unos segundos. La sobrecarga de caché y propagación puede causar un retraso.
{{< /warning >}}

## Configuración del enrutamiento de entrada basado en claims JWT

El ingress gateway de Istio admite el enrutamiento basado en JWT autenticados, lo que es útil para el enrutamiento basado en la identidad del usuario final
y más seguro en comparación con el uso de atributos HTTP no autenticados (por ejemplo, ruta o cabecera).

1. Para enrutar basándose en claims JWT, primero cree la autenticación de solicitudes para habilitar la validación de JWT:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: RequestAuthentication
    metadata:
      name: ingress-jwt
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

    La autenticación de solicitudes habilita la validación de JWT en el ingress gateway de Istio para que los claims JWT validados
puedan usarse posteriormente en el virtual service para fines de enrutamiento.

    La autenticación de solicitudes se aplica en el ingress gateway porque el enrutamiento basado en claims JWT solo es compatible
en los ingress gateways.

    Nota: la autenticación de solicitudes solo verificará el JWT si existe en la solicitud. Para que el JWT sea obligatorio y
rechace la solicitud si no incluye JWT, aplique la política de autorización como se especifica en la [tarea](/es/docs/tasks/security/authentication/authn-policy#require-a-valid-token).

1. Actualice el virtual service para enrutar basándose en claims JWT validados:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: httpbin
      namespace: foo
    spec:
      hosts:
      - "*"
      gateways:
      - httpbin-gateway
      http:
      - match:
        - uri:
            prefix: /headers
          headers:
            "@request.auth.claims.groups":
              exact: group1
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

    El virtual service utiliza la cabecera reservada "@request.auth.claims.groups" para coincidir con el claim JWT `groups`.
    El prefijo `@` denota que coincide con los metadatos derivados de la validación de JWT y no con las cabeceras HTTP.

    Se admiten claims de tipo cadena, lista de cadenas y claims anidados. Utilice `.` o `[]` como separador para claims anidados
    nombres. Por ejemplo, "@request.auth.claims.name.givenName" o "@request.auth.claims[name][givenName]" coinciden
    con los claims anidados `name` y `givenName`, son equivalentes aquí. Cuando el nombre del claim contiene `.`, solo se puede usar `[]` como separador.

## Validación del enrutamiento de entrada basado en claims JWT

1. Valide que el ingress gateway devuelve el código HTTP 404 sin JWT:

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

    También puede crear la política de autorización para rechazar explícitamente la solicitud con el código HTTP 403 cuando falta el JWT.

1. Valide que el ingress gateway devuelve el código HTTP 401 con un JWT inválido:

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer some.invalid.token"
    HTTP/1.1 401 Unauthorized
    ...
    {{< /text >}}

    El 401 es devuelto por la autenticación de solicitudes porque el JWT falló la validación.

1. Valide que el ingress gateway enruta la solicitud con un token JWT válido que incluye el claim `groups: group1`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode
    {"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
    {{< /text >}}

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_GROUP"
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

1. Valide que el ingress gateway devuelve el código HTTP 404 con un JWT válido pero que no incluye el claim `groups: group1`:

    {{< text syntax="bash" >}}
    $ TOKEN_NO_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN_NO_GROUP" | cut -d '.' -f2 - | base64 --decode
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_NO_GROUP"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## Limpieza

* Elimine el namespace `foo`:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

* Elimine la autenticación de solicitudes:

    {{< text bash >}}
    $ kubectl delete requestauthentication ingress-jwt -n istio-system
    {{< /text >}}

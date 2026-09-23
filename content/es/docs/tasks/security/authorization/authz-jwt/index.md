---
title: Token JWT
description: Muestra cómo configurar el control de acceso para el token JWT.
weight: 30
keywords: [security,authorization,jwt,claim]
aliases:
    - /docs/tasks/security/rbac-groups/
    - /docs/tasks/security/authorization/rbac-groups/
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea muestra cómo configurar una política de autorización de Istio para aplicar el acceso
basado en un JSON Web Token (JWT). Una política de autorización de Istio admite tanto claims JWT de tipo cadena
como de tipo lista de cadenas.

## Antes de empezar

Antes de comenzar esta tarea, haga lo siguiente:

* Complete la [tarea de autenticación de usuario final de Istio](/es/docs/tasks/security/authentication/authn-policy/#end-user-authentication).

* Lea los [conceptos de autorización de Istio](/es/docs/concepts/security/#authorization).

* Instale Istio utilizando la [guía de instalación de Istio](/es/docs/setup/install/istioctl/).

* Despliegue dos workloads: `httpbin` y `curl`. Despliegue estos en un namespace,
  por ejemplo `foo`. Ambos workloads se ejecutan con un proxy Envoy delante de cada uno.
  Despliegue el namespace y los workloads de ejemplo utilizando estos comandos:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
    {{< /text >}}

* Verifique que `curl` se comunica correctamente con `httpbin` utilizando este comando:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{\n}"
    200
    {{< /text >}}

{{< warning >}}
Si no ve la salida esperada, inténtelo de nuevo después de unos segundos.
El almacenamiento en caché y la propagación pueden causar un retraso.
{{< /warning >}}

## Permitir solicitudes con JWT válido y claims de tipo lista

1. El siguiente comando crea la política de autenticación de solicitudes `jwt-example`
   para el workload `httpbin` en el namespace `foo`. Esta política para el workload `httpbin`
   acepta un JWT emitido por `testing@secure.istio.io`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: RequestAuthentication
    metadata:
      name: "jwt-example"
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
    EOF
    {{< /text >}}

1. Verifique que una solicitud con un JWT inválido es denegada:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{\n}"
    401
    {{< /text >}}

1. Verifique que una solicitud sin un JWT es permitida porque no hay política de autorización:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -w "%{\n}"
    200
    {{< /text >}}

1. El siguiente comando crea la política de autorización `require-jwt` para el workload `httpbin` en el namespace `foo`.
   La política requiere que todas las solicitudes al workload `httpbin` tengan un JWT válido con
   `requestPrincipal` establecido en `testing@secure.istio.io/testing@secure.istio.io`.
   Istio construye el `requestPrincipal` combinando el `iss` y `sub` del token JWT
   con un separador `/` como se muestra:

    {{< text syntax="bash" expandlinks="false" >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: require-jwt
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - from:
        - source:
           requestPrincipals: ["testing@secure.istio.io/testing@secure.istio.io"]
    EOF
    {{< /text >}}

1. Obtenga el JWT que establece las claves `iss` y `sub` en el mismo valor, `testing@secure.istio.io`.
   Esto hace que Istio genere el atributo `requestPrincipal` con el valor `testing@secure.istio.io/testing@secure.istio.io`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

1. Verifique que una solicitud con un JWT válido es permitida:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{\n}"
    200
    {{< /text >}}

1. Verifique que una solicitud sin un JWT es denegada:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -w "%{\n}"
    403
    {{< /text >}}

1. El siguiente comando actualiza la política de autorización `require-jwt` para también requerir
   que el JWT tenga un claim llamado `groups` que contenga el valor `group1`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: require-jwt
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - from:
        - source:
           requestPrincipals: ["testing@secure.istio.io/testing@secure.istio.io"]
        when:
        - key: request.auth.claims[groups]
          values: ["group1"]
    EOF
    {{< /text >}}

    {{< warning >}}
    No incluya comillas en el campo `request.auth.claims` a menos que el claim en sí tenga comillas.
    {{< /warning >}}

1. Obtenga el JWT que establece el claim `groups` en una lista de cadenas: `group1` y `group2`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode
    {"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
    {{< /text >}}

1. Verifique que una solicitud con el JWT que incluye `group1` en el claim `groups` es permitida:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN_GROUP" -w "%{\n}"
    200
    {{< /text >}}

1. Verifique que una solicitud con un JWT, que no tiene el claim `groups` es rechazada:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{\n}"
    403
    {{< /text >}}

## Limpieza

Elimine el namespace `foo`:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}

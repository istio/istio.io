---
title: Copiar Claims JWT a Cabeceras HTTP
description: Muestra cómo los usuarios pueden copiar sus claims JWT a cabeceras HTTP.
weight: 30
keywords: [security,authentication,JWT,claim]
aliases:
    - /docs/tasks/security/istio-auth.html
    - /docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
status: Experimental
---

{{< boilerplate experimental >}}

Esta tarea muestra cómo copiar claims JWT válidos a cabeceras HTTP después de que la autenticación JWT se haya completado con éxito a través de una política de autenticación de solicitudes de Istio.

{{< warning >}}
Solo se admiten claims de tipo cadena, booleano y entero. Los claims de tipo array no se admiten en este momento.
{{< /warning >}}

## Antes de empezar

Antes de comenzar esta tarea, haga lo siguiente:

* Familiarícese con el soporte de [autenticación de usuario final de Istio](/es/docs/tasks/security/authentication/authn-policy/#end-user-authentication).

* Instale Istio usando la [guía de instalación de Istio](/es/docs/setup/install/istioctl/).

* Despliegue los workloads `httpbin` y `curl` en el namespace `foo` con la inyección de sidecar habilitada.
    Despliegue el namespace y los workloads de ejemplo usando estos comandos:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label namespace foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/curl/curl.yaml@ -n foo
    {{< /text >}}

* Verifique que `curl` se comunica correctamente con `httpbin` usando este comando:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{\nhttp_code}"
    200
    {{< /text >}}

    {{< warning >}}
    Si no ve la salida esperada, inténtelo de nuevo después de unos segundos.
    El almacenamiento en caché y la propagación pueden causar un retraso.
    {{< /warning >}}

## Permitir solicitudes con JWT válido y claims de tipo lista

1. El siguiente comando crea la política de autenticación de solicitudes `jwt-example`
    para el workload `httpbin` en el namespace `foo`. Esta política
    acepta un JWT emitido por `testing@secure.istio.io` y copia el valor del claim `foo` a una cabecera HTTP `X-Jwt-Claim-Foo`:

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
        outputClaimToHeaders:
        - header: "x-jwt-claim-foo"
          claim: "foo"
    EOF
    {{< /text >}}

1. Verifique que una solicitud con un JWT inválido es denegada:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{\nhttp_code}"
    401
    {{< /text >}}

1. Obtenga el JWT emitido por `testing@secure.istio.io` y que tiene un claim con la clave `foo`.

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

1. Verifique que una solicitud con un JWT válido es permitida:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{\nhttp_code}"
    200
    {{< /text >}}

1. Verifique que una solicitud contiene una cabecera HTTP válida con el valor del claim JWT:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/headers" -sS -H "Authorization: Bearer $TOKEN" | jq '.headers["X-Jwt-Claim-Foo"][0]'
    "bar"
    {{< /text >}}

## Limpieza

Elimine el namespace `foo`:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}

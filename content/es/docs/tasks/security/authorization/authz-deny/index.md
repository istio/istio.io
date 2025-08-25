---
title: Denegación Explícita
description: Muestra cómo configurar el control de acceso para denegar el tráfico explícitamente.
weight: 40
keywords: [security,access-control,rbac,authorization,deny]
owner: istio/wg-security-maintainers
test: yes
---

Esta tarea muestra cómo configurar la política de autorización de Istio de acción `DENY` para denegar explícitamente el tráfico en un mesh de Istio.
Esto es diferente de la acción `ALLOW` porque la acción `DENY` tiene mayor prioridad y no será
eludida por ninguna acción `ALLOW`.

## Antes de empezar

Antes de comenzar esta tarea, haga lo siguiente:

* Lea los [conceptos de autorización de Istio](/es/docs/concepts/security/#authorization).

* Siga la [guía de instalación de Istio](/es/docs/setup/install/istioctl/) para instalar Istio.

* Despliegue workloads:

    Esta tarea utiliza dos workloads, `httpbin` y `curl`, desplegados en un namespace, `foo`.
    Ambos workloads se ejecutan con un proxy Envoy delante de cada uno. Despliegue el namespace de ejemplo
    y los workloads con el siguiente comando:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
    {{< /text >}}

* Verifique que `curl` se comunica con `httpbin` con el siguiente comando:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{\n}"
    200
    {{< /text >}}

{{< warning >}}
Si no ve la salida esperada mientras sigue la tarea, inténtelo de nuevo después de unos segundos.
La sobrecarga de caché y propagación puede causar algún retraso.
{{< /warning >}}

## Denegar explícitamente una solicitud

1. El siguiente comando crea la política de autorización `deny-method-get` para el workload `httpbin`
    en el namespace `foo`. La política establece la `action` en `DENY` para denegar las solicitudes que satisfacen
    las condiciones establecidas en la sección `rules`. Este tipo de política se conoce mejor como política de denegación.
    En este caso, la política deniega las solicitudes si su método es `GET`.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-method-get
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. Verifique que las solicitudes `GET` son denegadas:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/get" -X GET -sS -o /dev/null -w "%{\n}"
    403
    {{< /text >}}

1. Verifique que las solicitudes `POST` son permitidas:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/post" -X POST -sS -o /dev/null -w "%{\n}"
    200
    {{< /text >}}

1. Actualice la política de autorización `deny-method-get` para denegar las solicitudes `GET` solo si
    el valor `x-token` de la cabecera HTTP no es `admin`. El siguiente ejemplo
    de política establece el valor del campo `notValues` en `["admin"]` para denegar las solicitudes con
    un valor de cabecera que no sea `admin`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-method-get
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
        when:
        - key: request.headers[x-token]
          notValues: ["admin"]
    EOF
    {{< /text >}}

1. Verifique que las solicitudes `GET` con la cabecera HTTP `x-token: admin` son permitidas:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: admin" -sS -o /dev/null -w "%{\n}"
    200
    {{< /text >}}

1. Verifique que las solicitudes GET con la cabecera HTTP `x-token: guest` son denegadas:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: guest" -sS -o /dev/null -w "%{\n}"
    403
    {{< /text >}}

1. El siguiente comando crea la política de autorización `allow-path-ip` para permitir las solicitudes
    en la ruta `/ip` al workload `httpbin`. Esta política de autorización establece el campo `action`
    en `ALLOW`. Este tipo de política se conoce mejor como política de permiso.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: allow-path-ip
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - to:
        - operation:
            paths: ["/ip"]
    EOF
    {{< /text >}}

1. Verifique que las solicitudes `GET` con la cabecera HTTP `x-token: guest` en la ruta `/ip` son denegadas
    por la política `deny-method-get`. Las políticas de denegación tienen precedencia sobre las políticas de permiso:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/ip" -X GET -H "x-token: guest" -s -o /dev/null -w "%{\n}"
    403
    {{< /text >}}

1. Verifique que las solicitudes `GET` con la cabecera HTTP `x-token: admin` en la ruta `/ip` son
    permitidas por la política `allow-path-ip`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/ip" -X GET -H "x-token: admin" -s -o /dev/null -w "%{\n}"
    200
    {{< /text >}}

1. Verifique que las solicitudes `GET` con la cabecera HTTP `x-token: admin` en la ruta `/get` son
    denegadas porque no coinciden con la política `allow-path-ip`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: admin" -s -o /dev/null -w "%{\n}"
    403
    {{< /text >}}

## Limpieza

Elimine el namespace `foo` de su configuración:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}

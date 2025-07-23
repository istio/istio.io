---
title: Tráfico TCP
description: Muestra cómo configurar el control de acceso para el tráfico TCP.
weight: 20
keywords: [security,access-control,rbac,tcp,authorization]
aliases:
    - /docs/tasks/security/authz-tcp/
owner: istio/wg-security-maintainers
test: no
---

Esta tarea muestra cómo configurar la política de autorización de Istio para el tráfico TCP en un mesh de Istio.

## Antes de empezar

Antes de comenzar esta tarea, haga lo siguiente:

* Lea los [conceptos de autorización de Istio](/es/docs/concepts/security/#authorization).

* Instale Istio utilizando la [guía de instalación de Istio](/es/docs/setup/install/istioctl/).

* Despliegue dos workloads llamados `curl` y `tcp-echo` juntos en un namespace, por ejemplo `foo`.
  Ambos workloads se ejecutan con un proxy Envoy delante de cada uno. El workload `tcp-echo` escucha en los puertos
  9000, 9001 y 9002 y devuelve cualquier tráfico recibido con el prefijo `hello`.
  Por ejemplo, si envía "world" a `tcp-echo`, responderá con `hello world`.
  El objeto service de Kubernetes `tcp-echo` solo declara los puertos 9000 y 9001, y
  omite el puerto 9002. Una cadena de filtro de paso directo manejará el tráfico del puerto 9002.
  Despliegue el namespace y los workloads de ejemplo utilizando el siguiente comando:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/tcp-echo/tcp-echo.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
    {{< /text >}}

* Verifique que `curl` se comunica correctamente con `tcp-echo` en los puertos 9000 y 9001
  utilizando el siguiente comando:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9000
    connection succeeded
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

* Verifique que `curl` se comunica correctamente con `tcp-echo` en el puerto 9002.
   Debe enviar el tráfico directamente a la IP del pod de `tcp-echo` porque el puerto 9002 no está
   definido explícitamente en el objeto service de Kubernetes de `tcp-echo`.
   Obtenga la dirección IP del pod y envíe la solicitud con el siguiente comando:

    {{< text bash >}}
    $ TCP_ECHO_IP=$(kubectl get pod "$(kubectl get pod -l app=tcp-echo -n foo -o jsonpath={.items..metadata.name})" -n foo -o jsonpath="{.status.podIP}")
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        "echo \"port 9002\" | nc $TCP_ECHO_IP 9002" | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9002
    connection succeeded
    {{< /text >}}

{{< warning >}}
Si no ve la salida esperada, inténtelo de nuevo después de unos segundos. El almacenamiento en caché y la propagación pueden causar un retraso.
{{< /warning >}}

## Configurar la política de autorización ALLOW para un workload TCP

1. Cree la política de autorización `tcp-policy` para el workload `tcp-echo` en el namespace `foo`.
   Ejecute el siguiente comando para aplicar la política para permitir solicitudes a los puertos 9000 y 9001:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: ALLOW
      rules:
      - to:
        - operation:
            ports: ["9000", "9001"]
    EOF
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9000 son permitidas utilizando el siguiente comando:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9000
    connection succeeded
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9001 son permitidas utilizando el siguiente comando:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9002 son denegadas. Esto es aplicado por la autorización
   política que también se aplica a la cadena de filtro de paso directo, incluso si el puerto no está declarado
   explícitamente en el objeto service de Kubernetes `tcp-echo`. Ejecute el siguiente comando y verifique la salida:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        "echo \"port 9002\" | nc $TCP_ECHO_IP 9002" | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Actualice la política para agregar un campo solo HTTP llamado `methods` para el puerto 9000 utilizando el siguiente comando:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: ALLOW
      rules:
      - to:
        - operation:
            methods: ["GET"]
            ports: ["9000"]
    EOF
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9000 son denegadas. Esto ocurre porque la regla se vuelve inválida cuando
   utiliza un campo solo HTTP (`methods`) para el tráfico TCP. Istio ignora la regla ALLOW inválida.
   El resultado final es que la solicitud es rechazada, porque no coincide con ninguna regla ALLOW.
   Ejecute el siguiente comando y verifique la salida:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9001 son denegadas. Esto ocurre porque las solicitudes no coinciden con ninguna
   regla ALLOW. Ejecute el siguiente comando y verifique la salida:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

## Configurar la política de autorización DENY para un workload TCP

1. Agregue una política DENY con campos solo HTTP utilizando el siguiente comando:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9000 son denegadas. Esto ocurre porque Istio no entiende los
   campos solo HTTP al crear una regla DENY para el puerto tcp y debido a su naturaleza restrictiva deniega todo el tráfico a los puertos tcp:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9001 son denegadas. Misma razón que la anterior.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Agregue una política DENY con campos TCP y HTTP utilizando el siguiente comando:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
            ports: ["9000"]
    EOF
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9000 son denegadas. Esto ocurre porque la solicitud coincide con los `ports` en la política de denegación mencionada anteriormente.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Verifique que las solicitudes al puerto 9001 son permitidas. Esto ocurre porque las solicitudes no coinciden con los
   `ports` en la política DENY:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

## Limpieza

Elimine el namespace foo:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}

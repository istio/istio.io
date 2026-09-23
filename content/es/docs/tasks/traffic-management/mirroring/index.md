---
title: Mirroring
description: Esta tarea demuestra las capacidades de mirroring/shadowing de tráfico de Istio.
weight: 60
keywords: [traffic-management,mirroring]
owner: istio/wg-networking-maintainers
test: yes
---

Esta tarea demuestra las capacidades de mirroring de tráfico de Istio.

El mirroring de tráfico, también llamado shadowing, es un concepto poderoso que permite
a los equipos de características llevar cambios a producción con el menor riesgo posible.
El mirroring envía una copia del tráfico en vivo a un servicio espejo. El tráfico
espejo ocurre fuera de banda del camino de solicitud crítico para el servicio primario.

En esta tarea, primero forzarás todo el tráfico a `v1` de un servicio de prueba. Luego,
aplicarás una regla para hacer espejo de una porción del tráfico a `v2`.

{{< boilerplate gateway-api-support >}}

## Antes de comenzar

1. Configura Istio siguiendo la [Guía de instalación](/es/docs/setup/).
1. Comienza desplegando dos versiones del servicio [httpbin]({{< github_tree >}}/samples/httpbin) que tienen el registro de acceso habilitado:

    1. Deploy `httpbin-v1`:

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: httpbin-v1
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: httpbin
              version: v1
          template:
            metadata:
              labels:
                app: httpbin
                version: v1
            spec:
              containers:
              - image: docker.io/kennethreitz/httpbin
                imagePullPolicy: IfNotPresent
                name: httpbin
                command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
                ports:
                - containerPort: 80
        EOF
        {{< /text >}}

    1. Deploy `httpbin-v2`:

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: httpbin-v2
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: httpbin
              version: v2
          template:
            metadata:
              labels:
                app: httpbin
                version: v2
            spec:
              containers:
              - image: docker.io/kennethreitz/httpbin
                imagePullPolicy: IfNotPresent
                name: httpbin
                command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
                ports:
                - containerPort: 80
        EOF
        {{< /text >}}

    1. Deploy el servicio Kubernetes `httpbin`:

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: v1
        kind: Service
        metadata:
          name: httpbin
          labels:
            app: httpbin
        spec:
          ports:
          - name: http
            port: 8000
            targetPort: 80
          selector:
            app: httpbin
        EOF
        {{< /text >}}

1. Despliega el `curl` workload que usarás para enviar solicitudes al servicio `httpbin`:

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: curl
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: curl
      template:
        metadata:
          labels:
            app: curl
        spec:
          containers:
          - name: curl
            image: curlimages/curl
            command: ["/bin/sleep","3650d"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

## Creando una política de enrutamiento por defecto

Por defecto, Kubernetes balancea el tráfico entre ambas versiones del servicio `httpbin`.
En este paso, cambiarás este comportamiento para que todo el tráfico vaya a `v1`.

1. Crea una regla de enrutamiento por defecto para enrutar todo el tráfico a `v1` del servicio:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
        - httpbin
      http:
      - route:
        - destination:
            host: httpbin
            subset: v1
          weight: 100
    ---
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: httpbin
    spec:
      host: httpbin
      subsets:
      - name: v1
        labels:
          version: v1
      - name: v2
        labels:
          version: v2
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin-v1
    spec:
      ports:
      - port: 80
        name: http
      selector:
        app: httpbin
        version: v1
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin-v2
    spec:
      ports:
      - port: 80
        name: http
      selector:
        app: httpbin
        version: v2
    ---
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: httpbin
    spec:
      parentRefs:
      - group: ""
        kind: Service
        name: httpbin
        port: 8000
      rules:
      - backendRefs:
        - name: httpbin-v1
          port: 80
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Ahora, con todo el tráfico dirigido a `httpbin:v1`, envía una solicitud al servicio:

    {{< text bash json >}}
    $ kubectl exec deploy/curl -c curl -- curl -sS http://httpbin:8000/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Parentspanid": "57784f8bff90ae0b",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "3289ae7257c3f159",
        "X-B3-Traceid": "b56eebd279a76f0b57784f8bff90ae0b",
        "X-Envoy-Attempt-Count": "1",
        "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/default;Hash=20afebed6da091c850264cc751b8c9306abac02993f80bdb76282237422bd098;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default"
      }
    }
    {{< /text >}}

1. Verifica los registros de los pods `httpbin-v1` y `httpbin-v2`. Deberías ver entradas de registro para `v1` y ninguna para `v2`:

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v1 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v2 -c httpbin
    <none>
    {{< /text >}}

## Mirando tráfico a `httpbin-v2`

1. Cambia la regla de enrutamiento para hacer espejo del tráfico a `httpbin-v2`:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
        - httpbin
      http:
      - route:
        - destination:
            host: httpbin
            subset: v1
          weight: 100
        mirror:
          host: httpbin
          subset: v2
        mirrorPercentage:
          value: 100.0
    EOF
    {{< /text >}}

    Esta regla de enrutamiento envía el 100% del tráfico a `v1`. La última estrofa especifica
    que quieres hacer espejo (es decir, también enviar) el 100% del mismo tráfico al
    servicio `httpbin:v2`. Cuando el tráfico se espeja,
    las solicitudes se envían al servicio espejo con sus encabezados Host/Authority
    añadidos con `-shadow`. Por ejemplo, `cluster-1` se convierte en `cluster-1-shadow`.

    También es importante tener en cuenta que estas solicitudes se espejan como "fire and
    forget", lo que significa que las respuestas se descartan.

    Puedes usar el campo `value` bajo el campo `mirrorPercentage` para hacer espejo de una fracción del tráfico,
    en lugar de espejar todas las solicitudes. Si este campo está ausente, todo el tráfico se espejará.

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: httpbin
    spec:
      parentRefs:
      - group: ""
        kind: Service
        name: httpbin
        port: 8000
      rules:
      - filters:
        - type: RequestMirror
          requestMirror:
            backendRef:
              name: httpbin-v2
              port: 80
        backendRefs:
        - name: httpbin-v1
          port: 80
    EOF
    {{< /text >}}

    Esta regla de enrutamiento envía el 100% del tráfico a `v1`. El filtro `RequestMirror`
    especifica que quieres hacer espejo (es decir, también enviar) el 100% del mismo tráfico al
    servicio `httpbin:v2`. Cuando el tráfico se espeja,
    las solicitudes se envían al servicio espejo con sus encabezados Host/Authority
    añadidos con `-shadow`. Por ejemplo, `cluster-1` se convierte en `cluster-1-shadow`.

    También es importante tener en cuenta que estas solicitudes se espejan como "fire and
    forget", lo que significa que las respuestas se descartan.

    {{< /tab >}}

    {{< /tabset >}}

1. Envía el tráfico:

    {{< text bash >}}
    $ kubectl exec deploy/curl -c curl -- curl -sS http://httpbin:8000/headers
    {{< /text >}}

    Ahora, deberías ver registros de acceso para ambos `v1` y `v2`. Los registros de acceso
    creados en `v2` son las solicitudes espejadas que realmente van a `v1`.

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v1 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v2 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    {{< /text >}}

## Limpieza

1. Elimina las reglas:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl delete virtualservice httpbin
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl delete httproute httpbin
    $ kubectl delete svc httpbin-v1 httpbin-v2
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Elimina los despliegues `httpbin` y `curl` y el servicio `httpbin`:

    {{< text bash >}}
    $ kubectl delete deploy httpbin-v1 httpbin-v2 curl
    $ kubectl delete svc httpbin
    {{< /text >}}

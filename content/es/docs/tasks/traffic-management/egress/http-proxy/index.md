---
title: Usar un Proxy HTTPS Externo
description: Describe cómo configurar Istio para permitir que las applications usen un proxy HTTPS externo.
weight: 60
keywords: [traffic-management,egress]
aliases:
  - /docs/examples/advanced-gateways/http-proxy/
owner: istio/wg-networking-maintainers
test: yes
---
El ejemplo [Configurar un Egress Gateway](/es/docs/tasks/traffic-management/egress/egress-gateway/) muestra cómo dirigir
el tráfico a services externos desde su malla a través de un componente de borde de Istio llamado _Egress Gateway_. Sin embargo, algunos
casos requieren un proxy HTTPS externo y heredado (no Istio) para acceder a services externos. Por ejemplo, su
empresa ya puede tener un proxy de este tipo en su lugar y todas las applications dentro de la organización pueden estar obligadas a
dirigir su tráfico a través de él.

Este ejemplo muestra cómo habilitar el acceso a un proxy HTTPS externo. Dado que las applications usan el método HTTP [CONNECT](https://tools.ietf.org/html/rfc7231#section-4.3.6) para establecer conexiones con proxies HTTPS,
la configuración del tráfico a un proxy HTTPS externo es diferente de la configuración del tráfico a services HTTP y HTTPS externos.

{{< boilerplate before-you-begin-egress >}}

*   [Habilitar el registro de acceso de Envoy](/es/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## Desplegar un proxy HTTPS

Para simular un proxy heredado y solo para este ejemplo, despliega un proxy HTTPS dentro de su cluster.
Además, para simular un proxy más realista que se ejecuta fuera de su cluster, se dirigirá al pod del proxy
por su dirección IP y no por el nombre de dominio de un service de Kubernetes.
Este ejemplo utiliza [Squid](http://www.squid-cache.org) pero puede usar cualquier proxy HTTPS que admita HTTP CONNECT.

1.  Cree un namespace para el proxy HTTPS, sin etiquetarlo para la inyección de sidecar. Sin la etiqueta, la inyección de sidecar
    está deshabilitada en el nuevo namespace, por lo que Istio no controlará el tráfico allí.
    Necesita este comportamiento para simular que el proxy está fuera del cluster.

    {{< text bash >}}
    $ kubectl create namespace external
    {{< /text >}}

1.  Cree un fichero de configuración para el proxy Squid.

    {{< text bash >}}
    $ cat <<EOF > ./proxy.conf
    http_port 3128

    acl SSL_ports port 443
    acl CONNECT method CONNECT

    http_access deny CONNECT !SSL_ports
    http_access allow localhost manager
    http_access deny manager
    http_access allow all

    coredump_dir /var/spool/squid
    EOF
    {{< /text >}}

1.  Cree un [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) de Kubernetes
    para contener la configuración del proxy:

    {{< text bash >}}
    $ kubectl create configmap proxy-configmap -n external --from-file=squid.conf=./proxy.conf
    {{< /text >}}

1.  Despliegue un contenedor con Squid:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: squid
      namespace: external
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: squid
      template:
        metadata:
          labels:
            app: squid
        spec:
          volumes:
          - name: proxy-config
            configMap:
              name: proxy-configmap
          containers:
          - name: squid
            image: sameersbn/squid:3.5.27
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - name: proxy-config
              mountPath: /etc/squid
              readOnly: true
    EOF
    {{< /text >}}

1.  Despliegue la muestra [curl]({{< github_tree >}}/samples/curl) en el namespace `external` para probar el tráfico al
    proxy sin control de tráfico de Istio.

    {{< text bash >}}
    $ kubectl apply -n external -f @samples/curl/curl.yaml@
    {{< /text >}}

1.  Obtenga la dirección IP del pod del proxy y defina la variable de entorno `PROXY_IP` para almacenarla:

    {{< text bash >}}
    $ export PROXY_IP="$(kubectl get pod -n external -l app=squid -o jsonpath={.items..podIP})"
    {{< /text >}}

1.  Defina la variable de entorno `PROXY_PORT` para almacenar el puerto de su proxy. En este caso, Squid usa el puerto
    3128.

    {{< text bash >}}
    $ export PROXY_PORT=3128
    {{< /text >}}

1.  Envíe una solicitud desde el pod `curl` en el namespace `external` a un service externo a través del proxy:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n external -l app=curl -o jsonpath={.items..metadata.name})" -n external -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, la enciclopedia libre</title>
    {{< /text >}}

1.  Verifique el registro de acceso del proxy para su solicitud:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name})" -n external -- tail /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

Hasta ahora, ha completado las siguientes tareas sin Istio:

* Ha desplegado el proxy HTTPS.
* Ha utilizado `curl` para acceder al service externo `wikipedia.org` a través del proxy.

A continuación, debe configurar el tráfico de los pods habilitados para Istio para que utilicen el proxy HTTPS.

## Configurar el tráfico al proxy HTTPS externo

1.  Defina una entrada de service TCP (¡no HTTP!) para el proxy HTTPS. Aunque las applications usan el método HTTP CONNECT para
    establecer conexiones con proxies HTTPS, debe configurar el proxy para tráfico TCP, en lugar de HTTP. Una vez que la
    conexión se establece, el proxy simplemente actúa como un túnel TCP.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: proxy
    spec:
      hosts:
      - my-company-proxy.com # ignored
      addresses:
      - $PROXY_IP/32
      ports:
      - number: $PROXY_PORT
        name: tcp
        protocol: TCP
      location: MESH_EXTERNAL
      resolution: NONE
    EOF
    {{< /text >}}

1.  Envíe una solicitud desde el pod `curl` en el namespace `default`. Debido a que el pod `curl` tiene un sidecar,
    Istio controla su tráfico.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, la enciclopedia libre</title>
    {{< /text >}}

1.  Verifique los registros del proxy sidecar de Istio para su solicitud:

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy
    [2018-12-07T10:38:02.841Z] "- - -" 0 - 702 87599 92 - "-" "-" "-" "-" "172.30.109.95:3128" outbound|3128||my-company-proxy.com 172.30.230.52:44478 172.30.109.95:3128 172.30.230.52:44476 -
    {{< /text >}}

1.  Verifique el registro de acceso del proxy para su solicitud:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name})" -n external -- tail /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

## Comprender lo que sucedió

En este ejemplo, realizó los siguientes pasos:

1. Desplegó un proxy HTTPS para simular un proxy externo.
1. Creó una entrada de service TCP para habilitar el tráfico controlado por Istio al proxy externo.

Tenga en cuenta que no debe crear entradas de service para los services externos a los que accede a través del proxy externo, como
`wikipedia.org`. Esto se debe a que, desde el punto de vista de Istio, las solicitudes se envían solo al proxy externo; Istio no
es consciente de que el proxy externo reenvía las solicitudes más allá.

## Limpieza

1.  Apague el service [curl]({{< github_tree >}}/samples/curl):

    {{< text bash >}}
    $ kubectl delete -f @samples/curl/curl.yaml@
    {{< /text >}}

1.  Apague el service [curl]({{< github_tree >}}/samples/curl) en el namespace `external`:

    {{< text bash >}}
    $ kubectl delete -f @samples/curl/curl.yaml@ -n external
    {{< /text >}}

1.  Apague el proxy Squid, elimine el `ConfigMap` y el fichero de configuración:

    {{< text bash >}}
    $ kubectl delete -n external deployment squid
    $ kubectl delete -n external configmap proxy-configmap
    $ rm ./proxy.conf
    {{< /text >}}

1.  Elimine el namespace `external`:

    {{< text bash >}}
    $ kubectl delete namespace external
    {{< /text >}}

1.  Elimine la entrada de Service:

    {{< text bash >}}
    $ kubectl delete serviceentry proxy
    {{< /text >}}

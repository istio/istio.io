---
title: Services de Kubernetes para Tráfico de Salida
description: Muestra cómo configurar Istio para Services Externos de Kubernetes.
keywords: [traffic-management,egress]
weight: 60
owner: istio/wg-networking-maintainers
test: yes
---

Los services [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) de Kubernetes y los services de Kubernetes con
[Endpoints](https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors)
le permiten crear un _alias_ DNS local para un service externo.
Este alias DNS tiene la misma forma que las entradas DNS para services locales, a saber,
`<nombre del service>.<nombre del namespace>.svc.cluster.local`. Los alias DNS proporcionan _transparencia de ubicación_ para sus workloads:
los workloads pueden llamar a services locales y externos de la misma manera. Si en algún momento decide desplegar el
service externo dentro de su cluster, puede simplemente actualizar su service de Kubernetes para que haga referencia a la versión local. Los workloads seguirán funcionando sin ningún cambio.

Esta tarea muestra que estos mecanismos de Kubernetes para acceder a services externos siguen funcionando con Istio.
El único paso de configuración que debe realizar es usar un modo TLS diferente al [mTLS](/es/docs/concepts/security/#mutual-tls-authentication) de Istio. Los services externos no forman parte de una service mesh de Istio,
por lo que no pueden realizar el mTLS de Istio. Debe configurar el modo TLS de acuerdo con los requisitos TLS del
service externo y de acuerdo con la forma en que su workload accede al service externo. Si su workload emite solicitudes HTTP
planas y el service externo requiere TLS, es posible que desee realizar la TLS origination por Istio. Si su workload
ya utiliza TLS, el tráfico ya está cifrado y simplemente puede deshabilitar el mTLS de Istio.

{{< warning >}}
Esta página describe cómo Istio puede integrarse con las configuraciones existentes de Kubernetes. Para nuevos despliegues, recomendamos
seguir [Acceso a Services de Salida](/es/docs/tasks/traffic-management/egress/egress-control/).
{{< /warning >}}

Aunque los ejemplos de esta tarea utilizan protocolos HTTP,
los Services de Kubernetes para tráfico de salida también funcionan con otros protocolos.

{{< boilerplate before-you-begin-egress >}}

*  Cree un namespace para un pod de origen sin control de Istio:

    {{< text bash >}}
    $ kubectl create namespace without-istio
    {{< /text >}}

*  Inicie la muestra [curl]({{< github_tree >}}/samples/curl) en el namespace `without-istio`.

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@ -n without-istio
    {{< /text >}}

*   Para enviar solicitudes, cree la variable de entorno `SOURCE_POD_WITHOUT_ISTIO` para almacenar el nombre del pod de origen:

    {{< text bash >}}
    $ export SOURCE_POD_WITHOUT_ISTIO="$(kubectl get pod -n without-istio -l app=curl -o jsonpath={.items..metadata.name})"
    {{< /text >}}

*   Verifique que el sidecar de Istio no fue inyectado, es decir, que el pod tiene un solo contenedor:

    {{< text bash >}}
    $ kubectl get pod "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio
    NAME                     READY   STATUS    RESTARTS   AGE
    curl-66c8d79ff5-8tqrl    1/1     Running   0          32s
    {{< /text >}}

## Service ExternalName de Kubernetes para acceder a un service externo

1.  Cree un service [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) de Kubernetes
    para `httpbin.org` en el namespace predeterminado:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: my-httpbin
    spec:
      type: ExternalName
      externalName: httpbin.org
      ports:
      - name: http
        protocol: TCP
        port: 80
    EOF
    {{< /text >}}

1.  Observe su service. Tenga en cuenta que no tiene una IP de cluster.

    {{< text bash >}}
    $ kubectl get svc my-httpbin
    NAME         TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    my-httpbin   ExternalName   <none>       httpbin.org   80/TCP    4s
    {{< /text >}}

1.  Acceda a `httpbin.org` a través del hostname del service de Kubernetes desde el pod de origen sin sidecar de Istio.
    Tenga en cuenta que el comando _curl_ a continuación utiliza el [formato DNS de Kubernetes para services](https://v1-13.docs.kubernetes.io/docs/concepts/services-networking/dns-pod-service/#a-records): `<nombre del service>.<namespace>.svc.cluster.local`.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio -c curl -- curl -sS my-httpbin.default.svc.cluster.local/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "my-httpbin.default.svc.cluster.local",
        "User-Agent": "curl/7.55.0"
      }
    }
    {{< /text >}}

1.  En este ejemplo, se envían solicitudes HTTP sin cifrar a `httpbin.org`. Solo para el ejemplo, deshabilita
    el modo TLS y permite el tráfico sin cifrar al service externo. En escenarios reales, recomendamos
    realizar la [TLS origination de salida](/es/docs/tasks/traffic-management/egress/egress-tls-origination/) por Istio.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: my-httpbin
    spec:
      host: my-httpbin.default.svc.cluster.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1.  Acceda a `httpbin.org` a través del hostname del service de Kubernetes desde el pod de origen con sidecar de Istio. Observe las
    cabeceras agregadas por el sidecar de Istio, por ejemplo `X-Envoy-Peer-Metadata`. También tenga en cuenta que
    la cabecera `Host` es igual al hostname de su service.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sS my-httpbin.default.svc.cluster.local/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "my-httpbin.default.svc.cluster.local",
        "User-Agent": "curl/7.64.0",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "5795fab599dca0b8",
        "X-B3-Traceid": "5079ad3a4af418915795fab599dca0b8",
        "X-Envoy-Peer-Metadata": "...",
        "X-Envoy-Peer-Metadata-Id": "sidecar~10.28.1.74~curl-6bdb595bcb-drr45.default~default.svc.cluster.local"
      }
    }
    {{< /text >}}

### Limpieza del service ExternalName de Kubernetes

{{< text bash >}}
$ kubectl delete destinationrule my-httpbin
$ kubectl delete service my-httpbin
{{< /text >}}

## Usar un service de Kubernetes con endpoints para acceder a un service externo

1.  Cree un service de Kubernetes sin selector para Wikipedia:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: my-wikipedia
    spec:
      ports:
      - protocol: TCP
        port: 443
        name: tls
    EOF
    {{< /text >}}

1.  Cree endpoints para su service. Elija un par de IPs de la [lista de rangos de Wikipedia](https://www.mediawiki.org/wiki/Wikipedia_Zero/IP_Addresses).

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Endpoints
    apiVersion: v1
    metadata:
      name: my-wikipedia
    subsets:
      - addresses:
          - ip: 198.35.26.96
          - ip: 208.80.153.224
        ports:
          - port: 443
            name: tls
    EOF
    {{< /text >}}

1.  Observe su service. Tenga en cuenta que tiene una IP de cluster que puede usar para acceder a `wikipedia.org`.

    {{< text bash >}}
    $ kubectl get svc my-wikipedia
    NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
    my-wikipedia   ClusterIP   172.21.156.230   <none>        443/TCP   21h
    {{< /text >}}

1.  Envíe solicitudes HTTPS a `wikipedia.org` por la IP del cluster de su service de Kubernetes desde el pod de origen sin sidecar de Istio.
    Use la opción `--resolve` de `curl` para acceder a `wikipedia.org` por la IP del cluster:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio -c curl -- curl -sS --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
    <title>Wikipedia, la enciclopedia libre</title>
    {{< /text >}}

1.  En este caso, el workload envía solicitudes HTTPS (abre conexión TLS) a `wikipedia.org`. El tráfico ya está
    cifrado por el workload, por lo que puede deshabilitar de forma segura el mTLS de Istio:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: my-wikipedia
    spec:
      host: my-wikipedia.default.svc.cluster.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1.  Acceda a `wikipedia.org` por la IP del cluster de su service de Kubernetes desde el pod de origen con sidecar de Istio:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sS --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
    <title>Wikipedia, la enciclopedia libre</title>
    {{< /text >}}

1.  Verifique que el acceso se realiza realmente por la IP del cluster. Observe la frase
    `Connected to en.wikipedia.org   (172.21.156.230)` en la salida de `curl -v`, menciona la IP que se imprimió
    en la salida de su service como la IP del cluster.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sS -v --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page -o /dev/null
    * Added en.wikipedia.org:443:172.21.156.230 to DNS cache
    * Hostname en.wikipedia.org was found in DNS cache
    *   Trying 172.21.156.230...
    * TCP_NODELAY set
    * Connected to en.wikipedia.org (172.21.156.230) port 443 (#0)
    ...
    {{< /text >}}

### Limpieza del service de Kubernetes con endpoints

{{< text bash >}}
$ kubectl delete destinationrule my-wikipedia
$ kubectl delete endpoints my-wikipedia
$ kubectl delete service my-wikipedia
{{< /text >}}

## Limpieza

1.  Apague el service [curl]({{< github_tree >}}/samples/curl):

    {{< text bash >}}
    $ kubectl delete -f @samples/curl/curl.yaml@
    {{< /text >}}

1.  Apague el service [curl]({{< github_tree >}}/samples/curl) en el namespace `without-istio`:

    {{< text bash >}}
    $ kubectl delete -f @samples/curl/curl.yaml@ -n without-istio
    {{< /text >}}

1.  Elimine el namespace `without-istio`:

    {{< text bash >}}
    $ kubectl delete namespace without-istio
    {{< /text >}}

1. Desestablezca las variables de entorno:

    {{< text bash >}}
    $ unset SOURCE_POD SOURCE_POD_WITHOUT_ISTIO
    {{< /text >}}

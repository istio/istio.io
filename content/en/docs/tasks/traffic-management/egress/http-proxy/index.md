---
title: Using an External HTTPS Proxy
description: Describes how to configure Istio to let applications use an external HTTPS proxy.
weight: 60
keywords: [traffic-management,egress]
aliases:
  - /docs/examples/advanced-gateways/http-proxy/
---
The [Configure an Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway/) example shows how to direct
traffic to external services from your mesh via an Istio edge component called _Egress Gateway_. However, some
cases require an external, legacy (non-Istio) HTTPS proxy to access external services. For example, your
company may already have such a proxy in place and all the applications within the organization may be required to
direct their traffic through it.

This example shows how to enable access to an external HTTPS proxy. Since applications use the HTTP [CONNECT](https://tools.ietf.org/html/rfc7231#section-4.3.6) method to establish connections with HTTPS proxies,
configuring traffic to an external HTTPS proxy is different from configuring traffic to external HTTP and HTTPS
services.

{{< boilerplate before-you-begin-egress >}}

*   [Enable Envoy’s access logging](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## Deploy an HTTPS proxy

To simulate a legacy proxy and only for this example, you deploy an HTTPS proxy inside your cluster.
Also, to simulate a more realistic proxy that is running outside of your cluster, you will address the proxy's pod
by its IP address and not by the domain name of a Kubernetes service.
This example uses [Squid](http://www.squid-cache.org) but you can use any HTTPS proxy that supports HTTP CONNECT.

1.  Create a namespace for the HTTPS proxy, without labeling it for sidecar injection. Without the label, sidecar
    injection is disabled in the new namespace so Istio will not control the traffic there.
    You need this behavior to simulate the proxy being outside of the cluster.

    {{< text bash >}}
    $ kubectl create namespace external
    {{< /text >}}

1.  Create a configuration file for the Squid proxy.

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

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
    to hold the configuration of the proxy:

    {{< text bash >}}
    $ kubectl create configmap proxy-configmap -n external --from-file=squid.conf=./proxy.conf
    {{< /text >}}

1.  Deploy a container with Squid:

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

1.  Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample in the `external` namespace to test traffic to the
    proxy without Istio traffic control.

    {{< text bash >}}
    $ kubectl apply -n external -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Obtain the IP address of the proxy pod and define the `PROXY_IP` environment variable to store it:

    {{< text bash >}}
    $ export PROXY_IP=$(kubectl get pod -n external -l app=squid -o jsonpath={.items..podIP})
    {{< /text >}}

1.  Define the `PROXY_PORT` environment variable to store the port of your proxy. In this case, Squid uses port
    3128.

    {{< text bash >}}
    $ export PROXY_PORT=3128
    {{< /text >}}

1.  Send a request from the `sleep` pod in the `external` namespace to an external service via the proxy:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=sleep -o jsonpath={.items..metadata.name}) -n external -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  Check the access log of the proxy for your request:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name}) -n external -- tail -f /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

So far, you completed the following tasks without Istio:

* You deployed the HTTPS proxy.
* You used `curl` to access the `wikipedia.org` external service through the proxy.

Next, you must configure the traffic from the Istio-enabled pods to use the HTTPS proxy.

## Configure traffic to external HTTPS proxy

1.  Define a TCP (not HTTP!) Service Entry for the HTTPS proxy. Although applications use the HTTP CONNECT method to
    establish connections with HTTPS proxies, you must configure the proxy for TCP traffic, instead of HTTP. Once the
    connection is established, the proxy simply acts as a TCP tunnel.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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
    EOF
    {{< /text >}}

1.  Send a request from the `sleep` pod in the `default` namespace. Because the `sleep` pod has a sidecar,
    Istio controls its traffic.

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  Check the Istio sidecar proxy's logs for your request:

    {{< text bash >}}
    $ kubectl logs $SOURCE_POD -c istio-proxy
    [2018-12-07T10:38:02.841Z] "- - -" 0 - 702 87599 92 - "-" "-" "-" "-" "172.30.109.95:3128" outbound|3128||my-company-proxy.com 172.30.230.52:44478 172.30.109.95:3128 172.30.230.52:44476 -
    {{< /text >}}

1.  Check the access log of the proxy for your request:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name}) -n external -- tail -f /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

## Direct the traffic to the external proxy through an egress gateway.

1.  Define the `EGRESS_GATEWAY_PROXY_PORT` environment variable to hold some port for directing traffic through
    the egress gateway, e.g. `7777`. You must select a port that is not used for any other service in the mesh.

    {{< text bash >}}
    $ export EGRESS_GATEWAY_PROXY_PORT=7777
    {{< /text >}}

1.  Add the port for redirecting traffic to the egress gateway to an `IstioControlPlane` definition:

    {{< text bash >}}
    $ cat <<EOF > ./egress_add_port.conf
    apiVersion: install.istio.io/v1alpha2
    kind: IstioControlPlane
    metadata:
      namespace: istio-operator
      name: example-istiocontrolplane
    spec:
      profile: demo
      gateways:
        enabled: true
      values:
        gateways:
          istio-egressgateway:
            ports:
              - port: 7777
                name: tcp
              - port: 80
                name: http
              - port: 443
                name: https
              - port: 15443
                name: tls
    EOF
    {{< /text >}}

1.  Apply the definition from the previous step:

    {{< text bash >}}
    $ istioctl manifest apply -f ./egress_add_port.conf
    {{< /text >}}

1.  Define the Service entry:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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
      - number: $EGRESS_GATEWAY_PROXY_PORT
        name: tcp-gateway
        protocol: TCP
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Create a Kubernetes `ExternalName` service for your proxy:

    {{< text bash >}}
    $ kubectl apply -n istio-system -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: myproxy
    spec:
      type: ExternalName
      externalName: $PROXY_IP
      ports:
      - protocol: TCP
        port: $PROXY_PORT
        name: tcp
    EOF
    {{< /text >}}

1.  Set the `PROXY_HOSTNAME` variable to the real hostname of your proxy or to the Kubernetes ExternalName service you
    created earlier:

    {{< text bash >}}
    $ export PROXY_HOSTNAME=myproxy.istio-system.svc.cluster.local
    {{< /text >}}

1.  Create an egress `Gateway` for your external proxy, and destination rules and a virtual service to direct the
    traffic through the egress gateway and from the egress gateway to the external proxy.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: $EGRESS_GATEWAY_PROXY_PORT
          name: tcp
          protocol: TCP
        hosts:
        - my-company-proxy.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-proxy
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: proxy
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: myproxy
    spec:
      host: $PROXY_HOSTNAME
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-traffic-to-proxy-through-egress-gateway
    spec:
      hosts:
      - my-company-proxy.com
      gateways:
      - mesh
      - istio-egressgateway
      tcp:
      - match:
        - gateways:
          - mesh
          destinationSubnets:
          - $PROXY_IP/32
          port: $PROXY_PORT
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: proxy
            port:
              number: $EGRESS_GATEWAY_PROXY_PORT
      - match:
        - gateways:
          - istio-egressgateway
          port: $EGRESS_GATEWAY_PROXY_PORT
        route:
        - destination:
            host: $PROXY_HOSTNAME
            port:
              number: $PROXY_PORT
          weight: 100
    EOF
    {{< /text >}}

1.  Send a request from the `sleep` pod in the `default` namespace.

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  Check the Istio sidecar proxy's logs for your request:

    {{< text bash >}}
    $ kubectl logs $SOURCE_POD -c istio-proxy
    [2018-12-07T10:38:02.841Z] "- - -" 0 - 702 87599 92 - "-" "-" "-" "-" "172.30.109.95:3128" outbound|3128||my-company-proxy.com 172.30.230.52:44478 172.30.109.95:3128 172.30.230.52:44476 -
    {{< /text >}}

1.  Check the log of the egress gateway's Envoy and see a line that corresponds to your
    requests to the proxy. If Istio is deployed in the `istio-system` namespace, the command to print the
    log is:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system
    [2019-04-14T06:12:07.636Z] "- - -" 0 - "-" 1591 4393 94 - "-" "-" "-" "-" "<Your proxy IP>:<your proxy port>" outbound|<your proxy port>||my-company-proxy.com 172.30.146.119:59924 172.30.146.119:443 172.30.230.1:59206 -
    {{< /text >}}

### Clean the egress gateway

{{< text bash >}}
$ kubectl delete virtualservice direct-traffic-to-proxy-through-egress-gateway
$ kubectl delete destinationrule proxy egressgateway-for-proxy
$ kubectl delete gateway istio-egressgateway
$ kubectl delete service myproxy -n istio-system
{{< /text >}}

## Understanding what happened

In this example, you took the following steps:

1. Deployed an HTTPS proxy to simulate an external proxy.
1. Created a TCP service entry to enable Istio-controlled traffic to the external proxy.

Note that you must not create service entries for the external services you access through the external proxy, like
`wikipedia.org`. This is because from Istio's point of view the requests are sent to the external proxy only; Istio is
not aware of the fact that the external proxy forwards the requests further.

## Cleanup

1.  Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service in the `external` namespace:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n external
    {{< /text >}}

1.  Shutdown the Squid proxy, remove the `ConfigMap` and the configuration file:

    {{< text bash >}}
    $ kubectl delete -n external deployment squid
    $ kubectl delete -n external configmap proxy-configmap
    $ rm ./proxy.conf
    {{< /text >}}

1.  Delete the `external` namespace:

    {{< text bash >}}
    $ kubectl delete namespace external
    {{< /text >}}

1.  Delete the Service Entry:

    {{< text bash >}}
    $ kubectl delete serviceentry proxy
    {{< /text >}}

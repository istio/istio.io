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
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: squid
      namespace: external
    spec:
      replicas: 1
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

## Understanding what happened

In this example, you took the following steps:

1. Deployed an HTTPS proxy to simulate an external proxy.
1. Created a TCP service entry to enable Istio-controlled traffic to the external proxy.

Note that you must not create service entries for the external services you access through the external proxy, like
`wikipedia.org`. This is because from Istio's point of view the requests are sent to the external proxy only; Istio is
not aware of the fact that the external proxy forwards the requests further.

## Cleanup

1.  Shutdown the [sleep]({{<github_tree>}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Shutdown the [sleep]({{<github_tree>}}/samples/sleep) service in the `external` namespace:

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

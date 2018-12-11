---
title: Connect to an external HTTPS proxy
description: Describes how to configure Istio to let applications use an external HTTPS proxy.
weight: 60
keywords: [traffic-management,egress]
---
The [Configure an Egress Gateway](/docs/examples/advanced-gateways/egress-gateway/) showed how you can direct traffic to
external services from your mesh via an Istio edge component called _Egress Gateway_. However, there are cases when you
must use an external, legacy (non-Istio) HTTPS proxy to access external services. For example, your company may already
have such a proxy in place and all the applications within the organization may be required to direct their traffic
through it.

This example shows how to enable access to an external HTTPS proxy. Since access to HTTPS proxies is performed by the
HTTP [CONNECT](https://tools.ietf.org/html/rfc7231#section-4.3.6) method, configuring traffic to an external HTTPS
proxy is different from configuring traffic to external HTTP and HTTPS services.

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Start the [sleep]({{< github_tree >}}/samples/sleep) sample
    which will be used as a test source for external calls via the proxy.

    If you have enabled
    [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), do

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    Note that any pod that you can `exec` and `curl` from would do.

*   Create a shell variable to hold the name of the source pod for sending requests to external services.
    If you used the [sleep]({{<github_tree>}}/samples/sleep) sample, run:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Deploy an HTTPS proxy

For this example, to simulate a legacy proxy, you deploy an HTTPS proxy inside your cluster. Also, to simulate a more
realistic proxy that is running outside of your cluster, you will address the pod of the proxy by its IP address and
not by a Kubernetes service.
You can use any HTTPS proxy that supports HTTP Connect. We used [Squid](http://www.squid-cache.org).

1.  Create a namespace for the HTTPS proxy. Note that since you do not label it for Istio automatic sidecar injection,
    Istio will not control traffic in this namespace.

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

1.  Define an environment variable to hold the IP address of the proxy pod:

    {{< text bash >}}
    $ export PROXY_IP=$(kubectl get pod -n external -l app=squid -o jsonpath={.items..podIP})
    {{< /text >}}

1.  Define an environment variable to hold the port of your proxy. The deployment of Squid in this example uses port
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

At this point the proxy has been deployed and tested by using `curl` to access `wikipedia.org` through the proxy, all
without Istio. It's just plain Kubernetes setting so far, which simulates an external HTTPS proxy.
In the following section you are going to configure traffic from Istio-enabled pods to the HTTPS proxy.

## Configure traffic to external HTTPS proxy

1.  Define a TCP (!) Service Entry for the HTTPS proxy. Note that despite the fact that the HTTP
    [CONNECT](https://tools.ietf.org/html/rfc7231#section-4.3.6) method is used to communicate with HTTPS proxies,
    the traffic between the application and the proxy is TCP (a TCP tunnel), and not HTTP.

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

1.  Send a request from the `sleep` pod in the `default` namespace. The `sleep` pod has Istio sidecar injected and its
    traffic is controlled by Istio.

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

In this example you configured access to an external legacy HTTPS proxy from the Istio service mesh. To simulate a
remote HTTPS proxy, you deployed an HTTPS proxy in a separate namespace, without Istio automatic sidecar injection. In addition, for simulation of a remote proxy, you addressed the HTTPS proxy by its IP address and not by a Kubernetes
service.

To enable Istio-controlled traffic to the external HTTPS proxy you created a TCP service entry with the IP address and
 the port of the proxy. Note that you must not create service entries for the external services you access though the
 external proxy, like `wikipedia.org`. This is because from Istio's point of view the requests are sent to the
 external proxy only; Istio is not aware of the fact that the external proxy forwards the requests further.

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

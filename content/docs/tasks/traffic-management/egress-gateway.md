---
title: Configure an Egress Gateway
description: Describes how to configure Istio to direct traffic to external services through a dedicated gateway service
weight: 43
---

> This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/). Note that this task introduces a new concept, namely Egress Gateway, that was not present in previous Istio versions.

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external (outside the Kubernetes cluster) HTTP and HTTPS services can be accessed from applications inside the mesh. A quick reminder: by default, Istio-enabled applications are unable to access URLs outside the cluster. To enable such access, a [ServiceEntry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) for the external service must be defined, or, alternatively, [direct access to external services](/docs/tasks/traffic-management/egress/#calling-external-services-directly) must be configured.

The [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress-tls-origination/) task demonstrates how to allow the applications to send HTTP requests to external servers that require HTTPS.

This task describes how to configure Istio to direct the egress traffic through a dedicated service called _Egress Gateway_. We extend the use case described in the [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress-tls-origination/) task.

## Use case

Consider an organization that has strict security requirements. According to these requirements all the traffic that leaves the service mesh must flow through a set of dedicated nodes. These nodes will run on dedicated machines, separately from the rest of the nodes used for running applications in the cluster. The special nodes will serve for policy enforcement on the egress traffic and will be monitored more thoroughly than the rest of the nodes.

Istio 0.8 introduced the concept of [ingress and egress gateways](/docs/reference/config/istio.networking.v1alpha3/#Gateway). Ingress gateways allow one to define entrance points into the service mesh that all incoming traffic flows through. _Egress gateway_ is a symmetrical concept, it defines exit points for the mesh. An egress gateway allows Istio features, for example, monitoring and route rules, to be applied to traffic exiting the mesh.

Additional use case is a cluster where the application nodes do not have public IPs. Defining an egress gateway, directing all the egress traffic through it and allocating public IPs to the egress gateway nodes allows the application nodes access external services in a controlled way.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Start the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) sample
    which will be used as a test source for external calls.

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), do

    ```command
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    ```
    otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    ```

    Note that any pod that you can `exec` and `curl` from would do.

*   Create a shell variable to hold the name of the source pod for sending requests to external services.
If we used the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) sample, we run:
    ```command
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    ```

## Define an egress `Gateway` and direct HTTP traffic through it

First let's direct HTTP traffic without TLS origination

1.  Create an egress `Gateway` for _edition.cnn.com_, port 80:

    ```bash
        cat <<EOF | istioctl create -f -
        kind: Gateway
        metadata:
          name: istio-egressgateway
        spec:
          selector:
            istio: egressgateway
          servers:
          - port:
              number: 80
              name: http
              protocol: HTTP
            hosts:
            - "edition.cnn.com"
    EOF
    ```

1.  Define a `ServiceEntry` for `edition.cnn.com` and a `VirtualService` to direct
the traffic through the egress gateway:

    ```bash
        cat <<EOF | istioctl create -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: ServiceEntry
        metadata:
          name: cnn
        spec:
          hosts:
          - edition.cnn.com
          ports:
          - number: 80
            name: http-port
            protocol: HTTP
          - number: 443
            name: https
            protocol: HTTPS
          resolution: DNS
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: direct-through-egress-gateway
        spec:
          hosts:
          - edition.cnn.com
          gateways:
          - istio-egressgateway
          - mesh
          http:
          - match:
            - gateways:
              - mesh
              port: 80
            route:
            - destination:
                host: istio-egressgateway.istio-system.svc.cluster.local
                port:
                  number: 80
              weight: 100
          - match:
            - gateways:
              - istio-egressgateway
              port: 80
            route:
            - destination:
                host: edition.cnn.com
                port:
                  number: 80
              weight: 100
        EOF
    ```

1.  Send an HTTP request to http://edition.cnn.com/politics.

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    ```

    The output should be the same as in the [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress-tls-origination/) task, without TLS origination.

1.  Check the log of the _istio-egressgateway_ pod and see a line corresponding to our request. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    ```command
    $ kubectl logs $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') egressgateway -n istio-system | tail
    ```

    We should see a line related to our request, similar to the following:

    ```plain
    [2018-06-14T11:46:23.596Z] "GET /politics HTTP/1.1" 301 - 0 0 3 1 "172.30.146.87" "curl/7.35.0" "ab7be694-e367-94c5-83d1-086eca996dae" "edition.cnn.com" "151.101.193.67:80"
    ```

    Note that we redirected only the traffic from the port 80 to the egress gateway, the HTTPS traffic to the port 443 went directly to _edition.cnn.com_.

### Let's clean up

Let's remove the previous definitions before proceeding to the next step:

```command
$ istioctl delete gateway istio-egressgateway
$ istioctl delete serviceentry cnn
$ istioctl delete virtualservice direct-through-egress-gateway
```

## Perform TLS origination with the egress `Gateway`

Let's perform TLS origination with the egress `Gateway`, similar to the [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress-tls-origination/) task.  Note that in this case the TLS origination will be done by the egress Gateway server, as opposed to by the sidecar in the previous task.

1.  Create an egress `Gateway` for _edition.cnn.com_, port 443:

    ```bash
        cat <<EOF | istioctl create -f -
        kind: Gateway
        metadata:
          name: istio-egressgateway
        spec:
          selector:
            istio: egressgateway
          servers:
          - port:
              number: 443
              name: http-port-for-tls-origination
              protocol: HTTP
            hosts:
            - "edition.cnn.com"
    EOF
    ```

1.  Define a `ServiceEntry` for `edition.cnn.com` and a `VirtualService` to direct
the traffic through the egress gateway:

    ```bash
        cat <<EOF | istioctl create -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: ServiceEntry
        metadata:
          name: cnn
        spec:
          hosts:
          - edition.cnn.com
          ports:
          - number: 80
            name: http-port
            protocol: HTTP
          - number: 443
            name: http-port-for-tls-origination
            protocol: HTTP
          resolution: DNS
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: direct-through-egress-gateway
        spec:
          hosts:
          - edition.cnn.com
          gateways:
          - istio-egressgateway
          - mesh
          http:
          - match:
            - gateways:
              - mesh
              port: 80
            route:
            - destination:
                host: istio-egressgateway.istio-system.svc.cluster.local
                port:
                  number: 443
              weight: 100
          - match:
            - gateways:
              - istio-egressgateway
              port: 443
            route:
            - destination:
                host: edition.cnn.com
                port:
                  number: 443
              weight: 100
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: originate-tls-for-edition-cnn-com
        spec:
          host: edition.cnn.com
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: SIMPLE # initiates HTTPS for connections to edition.cnn.com
        EOF
    ```

1.  Send an HTTP request to http://edition.cnn.com/politics.

    ```command
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    content-length: 150793
    ...
    ```

    The output should be the same as in the [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress-tls-origination/) task, with TLS origination: without the _301 Moved Permanently_ message.

1.  Check the log of _istio-egressgateway_ pod and see a line corresponding to our request. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    ```command
    $ kubectl logs $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') egressgateway -n istio-system | tail
    ```

    We should see a line related to our request, similar to the following:

    ```plain
    "[2018-06-14T13:49:36.340Z] "GET /politics HTTP/1.1" 200 - 0 148528 5096 90 "172.30.146.87" "curl/7.35.0" "c6bfdfc3-07ec-9c30-8957-6904230fd037" "edition.cnn.com" "151.101.65.67:443"
    ```

## Additional security considerations

Note that defining an egress `Gateway` in Istio does not in itself provides any special treatment for the nodes on which the egress gateway service runs. It is up to the cluster administrator or the cloud provider to deploy the egress gateways on dedicated nodes and to introduce additional security measures to make these nodes more secure than the rest of the mesh.

Also note that Istio itself *cannot securely enforce* that all the egress traffic will actually flow through the egress gateways, Istio only *enables* such flow by its sidecar proxies. If a malicious application would attack the sidecar proxy attached to the application's pod, it could bypass the sidecar proxy. Having bypassed the sidecar proxy, the malicious application could try to exit the service mesh bypassing the egress gateway, to escape the control and monitoring by Istio. It is up to the cluster administrator or the cloud provider to enforce that no traffic leaves the mesh bypassing the egress gateway. Such enforcement must be performed by mechanisms external to Istio. For example, a firewall can deny all the traffic whose source is not the egress gateway. [Kubernetes network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can also forbid all the egress traffic that does not originate in the egress gateway. An additional security measure is configuring the network in such a way that the application nodes are unable to access the Internet without directing the egress traffic through the gateway where it will be monitored and controlled. One example of such network configuration is allocating public IPs exclusively to the gateways.

## Cleanup

1.  Remove the Istio configuration items we created:

    ```command
    $ istioctl delete gateway istio-egressgateway
    $ istioctl delete serviceentry cnn
    $ istioctl delete virtualservice rewrite-port-for-edition-cnn-com
    $ istioctl delete destinationrule originate-tls-for-edition-cnn-com
    ```

1.  Shutdown the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) service:

    ```command
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    ```

## What's next

* Learn more about [service entries](/docs/concepts/traffic-management/rules-configuration/#service-entries), [virtual services](/docs/concepts/traffic-management/rules-configuration/#virtual-services),
[destination rules](/docs/concepts/traffic-management/rules-configuration/#destination-rules)
and [gateways](/docs/concepts/traffic-management/rules-configuration/#gateways).

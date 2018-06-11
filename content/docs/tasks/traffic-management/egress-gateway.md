---
title: Direct Egress Traffic through Egress Gateway
description: Describes how to configure Istio to traffic to external services through a dedicated service
weight: 43
---

> This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/). Note that this task introduces a new concept, namely Egress Gateway, that was not present in previous Istio versions.

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external (outside the Kubernetes cluster) HTTP and HTTPS services can be accessed from applications inside the mesh. A quick reminder: by default, Istio-enabled applications are unable to access URLs outside the cluster. To enable such access, a [ServiceEntry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) for the external service must be defined, or, alternatively, [direct access to external services](/docs/tasks/traffic-management/egress/#calling-external-services-directly) must be configured.

The <TBD> Perform TLS Origination for Egress Traffic task demonstrates how to allow the applications to send HTTP requests to external servers that require HTTPS.

This task describes how to configure Istio to direct the egress traffic through a dedicated service called Egress Gateway. We extend the use case described in the <TBD> Perform TLS Origination for Egress Traffic task.

## Use case

Consider an organization that has strict security requirements. According to these requirements all the traffic that leaves the service mesh must flow through a set of dedicated nodes. These nodes will run on dedicated machines, separately from the rest of the nodes used for running applications in the cluster. The special nodes will serve for policy enforcement on the egress traffic and will be monitored thoroughly than the rest of the nodes.

Istio 0.8 introduced the concept of [ingress and egress Gateways](/docs/reference/config/istio.networking.v1alpha3/#Gateway). Ingress gateways allow defining entrance points into the service mesh so all the incoming traffic flows through these entrance points. Egress gateway is a symmetrical concept, it defines exit points for the mesh. An egress `Gateway` allows Istio features, for example, monitoring and route rules, to be applied to traffic exiting the mesh.

Additional use case is a cluster where the application nodes do not have public IPs. Defining an Egress gateway, directing all the egress traffic through it and allocating public IPs to the egress gateway nodes lets the application nodes access external services in a controlled way.

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

## Define an egress `Gateway` and direct the traffic through it

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
              number: 80
              name: http
              protocol: HTTP
            hosts:
            - "edition.cnn.com"
    EOF
    ```

1.  Define the `ServiceEntry`, the `VirtualService` and the `DestinationRule` as in
the <TBD> Perform TLS Origination for Egress Traffic task, with one difference.

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
          name: rewrite-port-for-edition-cnn-com
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
              authority:
                exact: edition.cnn.com
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
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -IL http://edition.cnn.com/politics
    ```

    The output should be the same as in the <TBD> Perform TLS Origination for Egress Traffic task.

    ```plain
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    ```
## Additional security considerations

Note that defining an egress `Gateway` in Istio does not in itself provides any special treatment for the nodes on which the egress gateway service runs. It is up to the Istio operator or the cloud provider to deploy the egress gateways on dedicated nodes and to introduce additional security measures to make these nodes more secure than the rest of the mesh.

Also note that Istio itself *cannot securely enforce* that all the egress traffic will actually flow through the egress gateways, Istio only *enables* such flow by its sidecar proxies. If a malicious application would attack the sidecar proxy attached to its pod, it could circumvent the sidecar proxy and try to exit the service mesh circumventing the egress gateway, to escape the control and monitoring by Istio. It is up to the Istio operator or the cloud provider to enforce that no traffic leaves the mesh circumventing the egress gateway. Such enforcement must be performed by mechanisms external to Istio. For example, a firewall can deny all the traffic whose source is not the egress gateway. [Kubernetes network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can also forbid all the egress traffic that does not originate in the egress gateway. An additional security measure is disabling public IPs of the application nodes so the applications would not be able to communicate with the external services without directing the egress traffic through the gateway where it will be monitored and controlled.

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

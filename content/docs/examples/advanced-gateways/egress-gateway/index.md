---
title: Configure an Egress Gateway
description: Describes how to configure Istio to direct traffic to external services through a dedicated gateway.
weight: 43
keywords: [traffic-management,egress]
---

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external (outside the Kubernetes cluster) HTTP and HTTPS services can be accessed from applications inside the mesh. A quick reminder: by default, Istio-enabled applications are unable to access URLs outside the cluster. To enable such access, a [service entry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) for the external service must be defined, or, alternatively, [direct access to external services](/docs/tasks/traffic-management/egress/#calling-external-services-directly) must be configured.

The [TLS Origination for Egress Traffic](/docs/examples/advanced-gateways/egress-tls-origination/) example demonstrates how to allow the applications to send HTTP requests to external servers that require HTTPS.

This example describes how to configure Istio to direct the egress traffic through a dedicated service called _Egress Gateway_. We achieve the same functionality as described in the [TLS Origination for Egress Traffic](/docs/examples/advanced-gateways/egress-tls-origination/) example, only this time we accomplish it with the addition of an egress gateway.

## Use case

Consider an organization that has strict security requirements. According to these requirements all the traffic that leaves the service mesh must flow through a set of dedicated nodes. These nodes will run on dedicated machines, separately from the rest of the nodes used for running applications in the cluster. The special nodes will serve for policy enforcement on the egress traffic and will be monitored more thoroughly than the rest of the nodes.

Istio 0.8 introduced the concept of [ingress and egress gateways](/docs/reference/config/istio.networking.v1alpha3/#Gateway). Ingress gateways allow one to define entrance points into the service mesh that all incoming traffic flows through. _Egress gateway_ is a symmetrical concept, it defines exit points for the mesh. An egress gateway allows Istio features, for example, monitoring and route rules, to be applied to traffic exiting the mesh.

Another use case is a cluster where the application nodes do not have public IPs, so the in-mesh services that run on them cannot access the Internet. Defining an egress gateway, directing all the egress traffic through it and allocating public IPs to the egress gateway nodes allows the application nodes to access external services in a controlled way.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Start the [sleep]({{< github_tree >}}/samples/sleep) sample
    which will be used as a test source for external calls.

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), do

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    Note that any pod that you can `exec` and `curl` from would do.

*   Create a shell variable to hold the name of the source pod for sending requests to external services.
If we used the [sleep]({{<github_tree>}}/samples/sleep) sample, we run:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Define an egress `Gateway` and direct HTTP traffic through it

First direct HTTP traffic without TLS origination

1.  Define a `ServiceEntry` for `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly. Send an HTTPS request to [http://edition.cnn.com/politics](http://edition.cnn.com/politics).

    {{< text bash >}}
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
    {{< /text >}}

    The output should be the same as in the
    [TLS Origination for Egress Traffic](/docs/examples/advanced-gateways/egress-tls-origination/) example, without TLS
    origination.

1.  Create an egress `Gateway` for _edition.cnn.com_, port 80, and destination rules and virtual services to
    direct the traffic through the egress gateway and from the egress gateway to the external service.

    If you have [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) enabled in Istio, use the following
    command.

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
          number: 80
          name: https
          protocol: HTTPS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 80
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    EOF
    {{< /text >}}

    otherwise:

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
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - edition.cnn.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    EOF
    {{< /text >}}

1.  Define a `VirtualService` to direct the traffic through the egress gateway:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
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
            subset: cnn
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
    {{< /text >}}

1.  Resend the HTTP request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
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
    {{< /text >}}

    The output should be the same as in the step 2.

1.  Check the log of the `istio-egressgateway` pod and see a line corresponding to our request. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') egressgateway -n istio-system | tail
    {{< /text >}}

    We should see a line related to our request, similar to the following:

    {{< text plain >}}
    [2018-06-14T11:46:23.596Z] "GET /politics HTTP/2" 301 - 0 0 3 1 "172.30.146.87" "curl/7.35.0" "ab7be694-e367-94c5-83d1-086eca996dae" "edition.cnn.com" "151.101.193.67:80"
    {{< /text >}}

    Note that we redirected only the traffic from the port 80 to the egress gateway, the HTTPS traffic to the port 443 went directly to _edition.cnn.com_.

### Cleanup of the egress gateway for HTTP traffic

Remove the previous definitions before proceeding to the next step:

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## Perform TLS origination with the egress `Gateway`

Let's perform TLS origination with the egress `Gateway`, similar to the [TLS Origination for Egress Traffic](/docs/examples/advanced-gateways/egress-tls-origination/) example.  Note that in this case the TLS origination will
be done by the egress Gateway server, as opposed to by the sidecar in the previous example.

1.  Define a `ServiceEntry` for `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly. Send an HTTPS request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    command terminated with exit code 35
    {{< /text >}}

    The output should be contain _301 Moved Permanently_, if you see it, your `ServiceEntry` was configured correctly.
    The exit code _35_ is due to the fact that Istio did not perform TLS origination. The egress gateway will perform
    TLS origination, proceed to the following steps to configure it.

1.  Create an egress `Gateway` for _edition.cnn.com_, port 443, and destination rules and virtual services to
    direct the traffic through the egress gateway and from the egress gateway to the external service.

    If you have [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) enabled in Istio, use the following
    command.

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
          number: 443
          name: https
          protocol: HTTPS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    EOF
    {{< /text >}}

    otherwise:

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
          number: 443
          name: http-port-for-tls-origination
          protocol: HTTP
        hosts:
        - edition.cnn.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    EOF
    {{< /text >}}

1.  Define a `VirtualService` to direct the traffic through the egress gateway, and a `DestinationRule` to perform TLS
    origination:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
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
            subset: cnn
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
    {{< /text >}}

1.  Send an HTTP request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    content-length: 150793
    ...
    {{< /text >}}

    The output should be the same as in the [TLS Origination for Egress Traffic](/docs/examples/advanced-gateways/egress-tls-origination/) example, with TLS origination: without the _301 Moved Permanently_ message.

1.  Check the log of the `istio-egressgateway` pod and see a line corresponding to our request. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') egressgateway -n istio-system | tail
    {{< /text >}}

    We should see a line related to our request, similar to the following:

    {{< text plain>}}
    "[2018-06-14T13:49:36.340Z] "GET /politics HTTP/1.1" 200 - 0 148528 5096 90 "172.30.146.87" "curl/7.35.0" "c6bfdfc3-07ec-9c30-8957-6904230fd037" "edition.cnn.com" "151.101.65.67:443"
    {{< /text >}}

### Cleanup of the egress gateway for TLS origination

Remove the Istio configuration items we created:

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## Direct HTTPS traffic through an egress gateway

In this section you direct HTTPS traffic (TLS originated by the application) through an egress gateway.
You specify the port 443, protocol `TLS` in the corresponding `ServiceEntry`, egress `Gateway` and `VirtualService`.

1.  Define a `ServiceEntry` for `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly. Send an HTTPS request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics).
The output should be the same as in the previous section.

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1.  Create an egress `Gateway` for _edition.cnn.com_, port 443, protocol TLS, and destination rules and virtual services
    to direct the traffic through the egress gateway and from the egress gateway to the external service.

    If you have [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) enabled in Istio, use the following
    command.

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
          number: 443
          name: tls-cnn
          protocol: TLS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 443
      tcp:
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
    EOF
    {{< /text >}}

    otherwise:

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
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - edition.cnn.com
        tls:
          mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 443
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Send an HTTPS request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics). The output should be the same as previously.

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1.  Check the statistics of the egress gateway's proxy and see a counter that corresponds to our
    requests to _edition.cnn.com_. If Istio is deployed in the `istio-system` namespace, the command to print the
    counter is:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 1
    {{< /text >}}

    You may want to perform a couple of additional requests and verify that the counter above grows by 1 with each
    request.

### Cleanup of the egress gateway for HTTPS traffic

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## Additional security considerations

Note that defining an egress `Gateway` in Istio does not in itself provides any special treatment for the nodes on which the egress gateway service runs. It is up to the cluster administrator or the cloud provider to deploy the egress gateways on dedicated nodes and to introduce additional security measures to make these nodes more secure than the rest of the mesh.

Istio *cannot securely enforce* that all the egress traffic actually flows through the egress gateways. Istio only
enables said flow through its sidecar proxies. If attackers bypass the sidecar proxy, they could directly access
external services without traversing the egress gateway. Thus, the attackers escape Istio's control and monitoring.
The cluster administrator or the cloud provider must ensure that no traffic leaves the mesh bypassing the egress
gateway. Mechanisms external to Istio must enforce this requirement. For example, a firewall can deny all traffic not
coming from the egress gateway. The
[Kubernetes network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can also forbid
all the egress traffic not originating from the egress gateway (see
[the next section](#apply-kubernetes-network-policies) for an example).
Additionally, the cluster administrator or the cloud provider can configure the network to ensure application nodes can
only access the Internet via a gateway. To do this, the cluster administrator or the cloud provider can prevent the
allocation of public IPs to pods other than gateways and can configure NAT devices to drop packets not originating at
the egress gateways.

## Apply Kubernetes network policies

In this section you create a
[Kubernetes network policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to prevent
bypassing the egress gateway. To test the network policy, you create a namespace, namely `test-egress`, and deploy
to it the [sleep]({{< github_tree >}}/samples/sleep) sample.

1.  Follow the steps in the
    [Direct HTTPS traffic through an egress gateway](#direct-https-traffic-through-an-egress-gateway) section.

1.  Create the `test-egress` namespace:

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

1.  Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample to the `test-egress` namespace.

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Check that the deployed pod has a single container with no Istio sidecar attached:

    {{< text bash >}}
    $ kubectl get pod $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    sleep-776b7bcdcd-z7mc4   1/1       Running   0          18m
    {{< /text >}}

1.  Send an HTTPS request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics) from the `sleep` pod in
    the `test-egress` namespace. The request will succeed since you did not define any restrictive policies yet.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

1.  Label the namespaces where the Istio components (the control plane and the gateways) run.
    If you deployed the Istio components to `istio-system`, the command is:

    {{< text bash >}}
    $ kubectl label namespace istio-system istio=system
    {{< /text >}}

1.  Label the `kube-system` namespace.

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

1.  Define a `NetworkPolicy` to limit the egress traffic from the `test-egress` namespace to traffic destined to
    `istio-system`, and to the `kube-system` DNS service (port 53):

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n test-egress -f -
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-egress-to-istio-system-and-kube-dns
    spec:
      podSelector: {}
      policyTypes:
      - Egress
      egress:
      - to:
        - namespaceSelector:
            matchLabels:
              kube-system: "true"
        ports:
        - protocol: UDP
          port: 53
      - to:
        - namespaceSelector:
            matchLabels:
              istio: system
    EOF
    {{< /text >}}

1.  Resend the previous HTTPS request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics). Now it
    should fail since the traffic is blocked by the network policy. Note that the `sleep` pod cannot bypass
    `istio-egressgateway`. The only way it can access `edition.cnn.com` is by using an Istio sidecar proxy and by
    directing the traffic to `istio-egressgateway`. This setting demonstrates that even if some malicious pod manages to
    bypass its sidecar proxy, it will not be able to access external sites and will be blocked by the network policy.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -v https://edition.cnn.com/politics
    Hostname was NOT found in DNS cache
      Trying 151.101.65.67...
      Trying 2a04:4e42:200::323...
    Immediate connect fail for 2a04:4e42:200::323: Cannot assign requested address
      Trying 2a04:4e42:400::323...
    Immediate connect fail for 2a04:4e42:400::323: Cannot assign requested address
      Trying 2a04:4e42:600::323...
    Immediate connect fail for 2a04:4e42:600::323: Cannot assign requested address
      Trying 2a04:4e42::323...
    Immediate connect fail for 2a04:4e42::323: Cannot assign requested address
    connect to 151.101.65.67 port 443 failed: Connection timed out
    {{< /text >}}

1.  Now inject an Istio sidecar proxy into the `sleep` pod in the `test-egress` namespace by first enabling
    automatic sidecar proxy injection in the `test-egress` namespace:

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

1.  Then redeploy the `sleep` deployment:

    {{< text bash >}}
    $ kubectl delete deployment sleep -n test-egress
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n test-egress
    {{< /text >}}

1.  Check that the deployed pod has two containers, including the Istio sidecar proxy (`istio-proxy`):

    {{< text bash >}}
    $ kubectl get pod $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -o jsonpath={.spec.containers[*].name}
    sleep istio-proxy
    {{< /text >}}

1.  Send an HTTPS request to [http://edition.cnn.com/politics](https://edition.cnn.com/politics). Now it should succeed
    since the traffic flows to `istio-egressgateway` in the `istio-system` namespace, which is allowed by the
    Network Policy you defined. `istio-egressgateway` forwards the traffic to `edition.cnn.com`.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

1.  Check the statistics of the egress gateway's proxy and see a counter that corresponds to our
    requests to _edition.cnn.com_. If Istio is deployed in the `istio-system` namespace, the command to print the
    counter is:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 2
    {{< /text >}}

### Cleanup of the network policies

1.  Delete the resources created in this section:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n test-egress
    $ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
    $ kubectl label namespace kube-system kube-system-
    $ kubectl label namespace istio-system istio-
    $ kubectl delete namespace test-egress
    {{< /text >}}

1.  Perform the [Cleanup](#cleanup-of-the-egress-gateway-for-https-traffic) part of
    [Direct HTTPS traffic through an egress gateway](#direct-https-traffic-through-an-egress-gateway) section

## Troubleshooting

1.  Check if you have [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) enabled in Istio, following the
steps in
[Verify mutual TLS configuration](/docs/tasks/security/mutual-tls/#verify-mutual-tls-configuration).
If mutual TLS is enabled, make sure you create the configuration
items accordingly (note the remarks _If you have mutual TLS Authentication enabled in Istio, you must create..._).

1.  If [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) is enabled, verify the correct certificate of the
    egress gateway:

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
    {{< /text >}}

1.  For HTTPS traffic (TLS originated by the application), test the traffic flow by using the _openssl_ command.
    _openssl_ has an explicit option for setting the SNI, namely `-servername`.

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- openssl s_client -connect edition.cnn.com:443 -servername edition.cnn.com
    CONNECTED(00000003)
    ...
    Certificate chain
     0 s:/C=US/ST=California/L=San Francisco/O=Fastly, Inc./CN=turner-tls.map.fastly.net
       i:/C=BE/O=GlobalSign nv-sa/CN=GlobalSign CloudSSL CA - SHA256 - G3
     1 s:/C=BE/O=GlobalSign nv-sa/CN=GlobalSign CloudSSL CA - SHA256 - G3
       i:/C=BE/O=GlobalSign nv-sa/OU=Root CA/CN=GlobalSign Root CA
     ---
     Server certificate
     -----BEGIN CERTIFICATE-----
    ...
    {{< /text >}}

    If you get the certificate as in the output above, your traffic is routed correctly. Check the statistics of the egress gateway's proxy and see a counter that corresponds to your requests (sent by _openssl_ and _curl_) to _edition.cnn.com_.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 2
    {{< /text >}}

## Cleanup

Shutdown the [sleep]({{<github_tree>}}/samples/sleep) service:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}

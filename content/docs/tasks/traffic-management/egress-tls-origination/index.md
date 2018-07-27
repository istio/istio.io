---
title: TLS Origination for Egress Traffic
description: Describes how to configure Istio to perform TLS origination for traffic to external services
weight: 42
---

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external, meaning outside of the
Kubernetes cluster, HTTP and HTTPS services can be accessed from applications inside the mesh. As described in that topic, by
default Istio-enabled applications are unable to access URLs outside the cluster. To enable external access, a [`ServiceEntry`](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) for the external service must be defined, or alternatively, [direct access to external services](/docs/tasks/traffic-management/egress/#calling-external-services-directly) must be configured.

This task describes how to configure Istio to perform [TLS origination](/help/glossary/#tls-origination) for egress traffic.

## Use case

Consider a legacy application that performs HTTP calls to external sites. Suppose the organization that operates the application receives a new requirement which states that all the external traffic must be encrypted. With Istio, such a requirement can be achieved just by configuration, without changing the code of the application.

In this task, you configure Istio to open HTTPS connections to external services in cases the original traffic was HTTP. The application will send unencrypted HTTP requests as previously and Istio will encrypt the requests for the application.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Start the [sleep]({{< github_tree >}}/samples/sleep) sample
    which will be used as a test source for external calls.

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), deploy the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    Otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    Note that any pod that you can `exec` and `curl` from will do for the procedures below.

*   Create a shell variable to hold the name of the source pod for sending requests to external services.
If you used the [sleep]({{< github_tree >}}/samples/sleep) sample, run:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Configuring HTTP and HTTPS external services

First, configure access to _cnn.com_ in the same way as in the [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task.
Note that you use a wildcard `*` in your `hosts` definition: `*.cnn.com`. Using the wildcard allows access to  _www.cnn.com_ as well as to _edition.cnn.com_.

1.  Create a `ServiceEntry` to allow access to an external HTTP and HTTPS services:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - "*.cnn.com"
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https-port
        protocol: HTTPS
    EOF
    {{< /text >}}

1.  Make a request to the external HTTP service:

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

    The output should be similar to the above (some details replaced by ellipsis).

Note the `-L` flag of _curl_ which instructs _curl_ to follow redirects. In this case,
the server returned a redirect response ([301 Moved Permanently](https://tools.ietf.org/html/rfc2616#section-10.3.2)) to an HTTP request to `http://edition.cnn.com/politics`. The redirect response instructs the client to send an additional request, this time by HTTPS, to `https://edition.cnn.com/politics`. For the second request, the server returns the requested content and _200 OK_ status code.

While for the _curl_ command this redirection happens transparently, there are two issues here. The first issue is the redundant first request, which doubles
the latency of fetching the content of `http://edition.cnn.com/politics`. The second issue is that the path of the URL, _politics_ in this case, is sent in clear text. If there is an attacker who sniffs the communication between your application and _cnn.com_, the attacker would know which specific topics and articles of _cnn.com_ your application fetched. For privacy reasons, you might want to prevent such disclosure from the attacker.

In the next section, you configure Istio to perform TLS origination to resolve these two issues. Clean your configuration before proceeding to the next section:

{{< text bash >}}
$ kubectl delete serviceentry cnn
{{< /text >}}

## TLS origination for egress traffic

1.  Define a `ServiceEntry` to allow traffic to _edition.cnn.com_, a `VirtualService` to perform request port rewriting, and a `DestinationRule` for TLS origination.

    Unlike the `ServiceEntry` in the previous section, here you use HTTP for the protocol on port 433 because clients
will send HTTP requests and Istio will perform TLS origination for them. Also, in this example the resolution must be set
to DNS to correctly configure Envoy.

    Finally, note that the `VirtualService` uses a specific host _edition.cnn.com_ (no wildcard) because the Envoy
proxy needs to know exactly which host to access using HTTPS:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
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
      http:
      - match:
          - port: 80
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
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
            mode: SIMPLE # initiates HTTPS when accessing edition.cnn.com
    EOF
    {{< /text >}}

1. Send an HTTP request to `http://edition.cnn.com/politics`, as in the previous section:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    This time you receive _200 OK_ as the first and the only response. Istio performed TLS origination for _curl_ so the original HTTP request was forwarded to _cnn.com_ as HTTPS. The _cnn.com_ server returned the content directly, without the need for redirection. You eliminated the double round trip between the client and the server, and the request left the mesh encrypted, without disclosing the fact that your application fetched the _politics_ section of _cnn.com_.

    Note that you used the same command as in the previous section. For applications that access external services programmatically, the code will not be changed. Therefore, you get the benefits of TLS origination by configuring Istio, without changing a line of code.

## Additional security considerations

Note that the traffic between the application pod and the sidecar proxy on the local host is still unencrypted. It means that if an attacker was able to penetrate the node of your application, they would still be able to see the unencrypted communication on the local network of the node. In some environments a strict security requirement might exist that would state that all the traffic must be encrypted, even on the local network of the nodes. With such a strict requirement the applications should use HTTPS (TLS) only, the TLS origination described in this task will not be sufficient.

Also note that even for HTTPS originated by the application, the attacker could know that the requests to _cnn.com_ are being sent, by inspecting [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication). The _SNI_ field is sent unencrypted during the TLS handshake. Using HTTPS prevents the attackers from knowing specific topics and articles, it does not prevent the attackers from learning that _cnn.com_ is accessed.

## Cleanup

1.  Remove the Istio configuration items you created:

    {{< text bash >}}
    $ kubectl delete serviceentry cnn
    $ kubectl delete virtualservice rewrite-port-for-edition-cnn-com
    $ kubectl delete destinationrule originate-tls-for-edition-cnn-com
    {{< /text >}}

1.  Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

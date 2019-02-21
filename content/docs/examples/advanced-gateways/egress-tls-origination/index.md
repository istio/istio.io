---
title: TLS Origination for Egress Traffic
description: Describes how to configure Istio to perform TLS origination for traffic to external services.
keywords: [traffic-management,egress]
weight: 20
---

The [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task demonstrates how external, i.e., outside of the
service mesh, HTTP and HTTPS services can be accessed from applications inside the mesh. As described in that task,
by default Istio-enabled applications are unable to access URLs outside of the cluster. To enable external access,
a [`ServiceEntry`](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) for the external service must be
defined, or alternatively, [direct access to external services](/docs/tasks/traffic-management/egress/#direct-access-to-external-services)
must be configured.

This example shows how to configure Istio to perform [TLS origination](/help/glossary/#tls-origination)
for traffic to an external service. Istio will open HTTPS connections to the external service while the original
traffic is HTTP.

## Use case

Consider a legacy application that performs HTTP calls to external sites. Suppose the organization that operates the
application receives a new requirement which states that all the external traffic must be encrypted. With Istio,
this requirement can be achieved just by configuration, without changing any code in the application.
The application can send unencrypted HTTP requests and Istio will then encrypt them for the application.

Another benefit of sending unencrypted HTTP requests from the source, and letting Istio perform the TLS upgrade,
is that Istio can produce better telemetry and provide more routing control for requests that are not encrypted.

## Before you begin

* Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Start the [sleep]({{< github_tree >}}/samples/sleep) sample which will be used as a test source for external calls.

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

## Configuring access to an external service

First start by configuring access to an external service, `edition.cnn.com`,
using the same technique shown in the [Control Egress Traffic](/docs/tasks/traffic-management/egress/) task.
This time, however, use a single `ServiceEntry` to enable both HTTP and HTTPS access to the service.

1.  Create a `ServiceEntry` and `VirtualService` to enable access to `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      tls:
      - match:
        - port: 443
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

Notice the `-L` flag of _curl_ which instructs _curl_ to follow redirects.
In this case, the server returned a redirect response ([301 Moved Permanently](https://tools.ietf.org/html/rfc2616#section-10.3.2))
for the HTTP request to `http://edition.cnn.com/politics`.
The redirect response instructs the client to send an additional request, this time using HTTPS, to `https://edition.cnn.com/politics`.
For the second request, the server returned the requested content and a _200 OK_ status code.

Although the _curl_ command handled the redirection transparently, there are two issues here.
The first issue is the redundant request, which doubles the latency of fetching the content of `http://edition.cnn.com/politics`.
The second issue is that the path of the URL, _politics_ in this case, is sent in clear text.
If there is an attacker who sniffs the communication between your application and `edition.cnn.com`,
the attacker would know which specific topics of `edition.cnn.com` the application fetched.
For privacy reasons, you might want to prevent such disclosure.

Both of these issues can be resolved by configuring Istio to perform TLS origination.

## TLS origination for egress traffic

1.  Redefine your `ServiceEntry` and `VirtualService` from the previous section to rewrite the HTTP request port
    and add a `DestinationRule` to perform TLS origination.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
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
      name: edition-cnn-com
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
      name: edition-cnn-com
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

    As you can see, the `VirtualService` redirects HTTP requests on port 80 to port 443 where the corresponding
    `DestinationRule` then performs the TLS origination.
    Notice that unlike the `ServiceEntry` in the previous section, this time the protocol on port 443 is HTTP, instead of HTTPS.
    This is because clients will only send HTTP requests and Istio will upgrade the connection to HTTPS.

1. Send an HTTP request to `http://edition.cnn.com/politics`, as in the previous section:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    This time you receive _200 OK_ as the first and the only response. Istio performed TLS origination for _curl_ so
    the original HTTP request was forwarded to `edition.cnn.com` as HTTPS. The server returned the content directly,
    without the need for redirection. You eliminated the double round trip between the client and the server, and the
    request left the mesh encrypted, without disclosing the fact that your application fetched the _politics_ section
    of `edition.cnn.com`.

    Note that you used the same command as in the previous section. For applications that access external services
    programmatically, the code does not need to be changed. You get the benefits of TLS origination by configuring Istio,
    without changing a line of code.

## Additional security considerations

Because the traffic between the application pod and the sidecar proxy on the local host is still unencrypted,
an attacker that is able to penetrate the node of your application would still be able to see the unencrypted
communication on the local network of the node. In some environments a strict security requirement
might state that all the traffic must be encrypted, even on the local network of the nodes.
With such a strict requirement, applications should use HTTPS (TLS) only. The TLS origination described in this
example would not be sufficient.

Also note that even with HTTPS originated by the application, an attacker could know that requests to `edition.cnn.com`
are being sent by inspecting [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication).
The _SNI_ field is sent unencrypted during the TLS handshake. Using HTTPS prevents the attackers from knowing specific
topics and articles but does not prevent an attackers from learning that `edition.cnn.com` is accessed.

## Cleanup

1.  Remove the Istio configuration items you created:

    {{< text bash >}}
    $ kubectl delete serviceentry edition-cnn-com
    $ kubectl delete virtualservice edition-cnn-com
    $ kubectl delete destinationrule edition-cnn-com
    {{< /text >}}

1.  Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

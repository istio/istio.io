---
title: Consuming External Web Services
description: Describes a simple scenario based on Istio's Bookinfo example.
publishdate: 2018-01-31
subtitle: Mesh-external service entries for egress HTTPS traffic
attribution: Vadim Eisenberg
weight: 93
keywords: [traffic-management,egress,https]
---

In many cases, not all the parts of a microservices-based application reside in a _service mesh_. Sometimes, the microservices-based applications use functionality provided by legacy systems that reside outside the mesh. We may want to migrate these systems to the service mesh gradually. Until these systems are migrated, they must be accessed by the applications inside the mesh. In other cases, the applications use web services provided by external organizations, often over the World Wide Web.

In this blog post, I modify the [Istio Bookinfo Sample Application](/docs/examples/bookinfo/) to fetch book details from an external web service ([Google Books APIs](https://developers.google.com/books/docs/v1/getting_started)). I show how to enable external HTTPS traffic in Istio by using an _egress rule_. Finally, I explain the current issues related to the egress traffic control in Istio.

## Bookinfo sample application with external details web service

### Initial setting

To demonstrate the scenario of consuming an external web service, I start with a Kubernetes cluster with [Istio installed](/docs/setup/kubernetes/quick-start/#installation-steps). Then I deploy [Istio Bookinfo Sample Application](/docs/examples/bookinfo/). This application uses the _details_ microservice to fetch book details, such as the number of pages and the publisher. The original _details_ microservice provides the book details without consulting any external service.

The example commands in this blog post work with Istio 1.0+, with or without [mutual TLS](/docs/concepts/security/#mutual-tls-authentication) enabled. The Bookinfo configuration files reside in the `samples/bookinfo` directory of the Istio release archive.

Here is a copy of the end-to-end architecture of the application from the original [Bookinfo sample application](/docs/examples/bookinfo/).

{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="The Original Bookinfo Application"
    >}}

Perform the steps in the
[Deploying the application](http://localhost:1313/docs/examples/bookinfo/#deploying-the-application),
[Confirm the app is running](http://localhost:1313/docs/examples/bookinfo/#confirm-the-app-is-running), and
[Apply default destination rules](http://localhost:1313/docs/examples/bookinfo/#apply-default-destination-rules)
sections.

### Bookinfo with details version 2

Deploy a new version of the _details_ microservice, _v2_, that fetches the book details from [Google Books APIs](https://developers.googleapis.com/books/docs/v1/getting_started). Run the following command; it sets the
`DO_NOT_ENCRYPT` environment variable of the service's container to `false`. This setting will instruct the deployed
service to use HTTPS (instead of HTTP) in access to the external service.

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-details-v2.yaml@ --dry-run -o yaml | kubectl set env --local -f - 'DO_NOT_ENCRYPT=false' -o yaml | kubectl apply -f -
{{< /text >}}

The updated architecture of the application now looks as follows:

{{< image width="80%" ratio="65.16%"
    link="./bookinfo-details-v2.svg"
    caption="The Bookinfo Application with details V2"
    >}}

Note that the Google Books web service is outside the Istio service mesh, the boundary of which is marked by a dashed line.

Now let's direct all the traffic destined to the _details_ microservice, to _details version v2_.

1.  Define _destination rules_ to enable routing for the application.

    If you have [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) enabled in Istio, use the following
    command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    otherwise:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
    {{< /text >}}

2.  Define a _virtual service_ to direct all the traffic destined to the _details_ microservice, to _details version
    v2_:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-details-v2.yaml@
    {{< /text >}}

Let's access the web page of the application, after [determining the ingress IP and port](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port).

Oops... Instead of the book details we have the _Error fetching product details_ message displayed:

{{< image width="80%" ratio="36.01%"
    link="./errorFetchingBookDetails.png"
    caption="The Error Fetching Product Details Message"
    >}}

The good news is that our application did not crash. With a good microservice design, we do not have **failure propagation**. In our case, the failing _details_ microservice does not cause the `productpage` microservice to fail. Most of the functionality of the application is still provided, despite the failure in the _details_ microservice. We have **graceful service degradation**: as you can see, the reviews and the ratings are displayed correctly, and the application is still useful.

So what might have gone wrong? Ah... The answer is that I forgot to enable traffic from inside the mesh to an external service, in this case to the Google Books web service. By default, the Istio sidecar proxies ([Envoy proxies](https://www.envoyproxy.io)) **block all the traffic to destinations outside the cluster**. To enable such traffic, we must define an [egress rule](https://archive.istio.io/v0.7/docs/reference/config/istio.routing.v1alpha1/#EgressRule).

### Enable access to the Google Books web service

No worries, let's define a **mesh-external service entry** and fix our application. We also must define a _virtual
service_ to perform routing by [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) to the external service.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: googleapis
spec:
  hosts:
  - www.googleapis.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
  resolution: DNS
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: googleapis
spec:
  hosts:
  - www.googleapis.com
  tls:
  - match:
    - port: 443
      sni_hosts:
      - www.googleapis.com
    route:
    - destination:
        host: www.googleapis.com
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

Now accessing the web page of the application displays the book details without error:

{{< image width="80%" ratio="34.82%"
    link="./externalBookDetails.png"
    caption="Book Details Displayed Correctly"
    >}}

You can query our service entries:

{{< text bash >}}
$ kubectl get serviceentries
NAME         AGE
googleapis   8m

{{< /text >}}

You can delete our service entry:

{{< text bash >}}
$ kubectl delete serviceentry googleapis
serviceentry "googleapis" deleted
{{< /text >}}

and see in the output that the egress rule is deleted.

Accessing the web page after deleting the egress rule produces the same error that we experienced before, namely _Error fetching product details_. As we can see, the egress rules are defined **dynamically**, as many other Istio configuration artifacts. The Istio operators can decide dynamically which domains they allow the microservices to access. They can enable and disable traffic to the external domains on the fly, without redeploying the microservices.

## Cleanup

{{< text bash >}}
$ kubectl delete serviceentry googleapis
$ kubectl delete virtualservice googleapis
{{< /text >}}

## Issues with Istio egress traffic control

### TLS origination by Istio

There is a caveat to this story. In HTTPS, all the HTTP details (hostname, path, headers etc.) are encrypted, so Istio cannot know the destination domain of the encrypted requests. Well, Istio could know the destination domain by the  [SNI](https://tools.ietf.org/html/rfc3546#section-3.1) (_Server Name Indication_) field. This feature, however, is not yet implemented in Istio. Therefore, currently Istio cannot perform filtering of HTTPS requests based on the destination domains.

To allow Istio to perform filtering of egress requests based on domains, the microservices must issue HTTP requests. Istio then opens an HTTPS connection to the destination (performs TLS origination). The code of the microservices must be written differently or configured differently, according to whether the microservice runs inside or outside an Istio service mesh. This contradicts the Istio design goal of [maximizing transparency](/docs/concepts/what-is-istio/#design-goals). Sometimes we need to compromise...

The diagram below shows how the HTTPS traffic to external services is performed. On the top, a microservice outside an Istio service mesh
sends regular HTTPS requests, encrypted end-to-end. On the bottom, the same microservice inside an Istio service mesh must send unencrypted HTTP requests inside a pod, which are intercepted by the sidecar Envoy proxy. The sidecar proxy performs TLS origination, so the traffic between the pod and the external service is encrypted.

{{< image width="80%" ratio="65.16%"
    link="./https_from_the_app.svg"
    caption="HTTPS traffic to external services, from outside vs. from inside an Istio service mesh"
    >}}

Here is how we code this behavior in the [Bookinfo details microservice code]({{< github_file >}}/samples/bookinfo/src/details/details.rb), using the Ruby [net/http module](https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html):

{{< text ruby >}}
uri = URI.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:' + isbn)
http = Net::HTTP.new(uri.host, uri.port)
...
unless ENV['WITH_ISTIO'] === 'true' then
     http.use_ssl = true
end
{{< /text >}}

Note that the port is derived by the `URI.parse` from the URI's schema (`https://`) to be `443`, the default HTTPS port. The
microservice, when running inside a mesh, must issue HTTP requests to the port `443`, which is the port the external service listens to.

When the `WITH_ISTIO` environment variable is defined, the request is performed without SSL (plain HTTP).

We set the `WITH_ISTIO` environment variable to _"true"_ in the
[Kubernetes deployment spec of details v2]({{< github_file >}}/samples/bookinfo/platform/kube/bookinfo-details-v2.yaml),
the `container` section:

{{< text yaml >}}
env:
- name: WITH_ISTIO
  value: "true"
{{< /text >}}

#### Relation to Istio mutual TLS

Note that the TLS origination in this case is unrelated to [the mutual TLS](/docs/concepts/security/#mutual-tls-authentication) applied by Istio. The TLS origination for the external services will work, whether the Istio mutual TLS is enabled or not. The **mutual** TLS secures service-to-service communication **inside** the service mesh and provides each service with a strong identity. In the case of the **external services**, we have **one-way** TLS, the same mechanism used to secure communication between a web browser and a web server. TLS is applied to the communication with external services to verify the identity of the external server and to encrypt the traffic.

### Malicious microservices threat

Another issue is that the egress rules are currently **not a security feature**; they only **enable** traffic to external services. For HTTP-based protocols, the rules are based on domains. Istio does not check that the destination IP of the request matches the _Host_ header. This means that a malicious microservice inside a service mesh could trick Istio to allow traffic to a malicious IP. The attack is to set one of the domains allowed by some existing Egress Rule as the _Host_ header of the malicious request.

Securing egress traffic is currently not supported in Istio and should be performed elsewhere, for example by a firewall or by an additional proxy outside Istio. Right now, we're working to enable the application of Mixer security policies on the egress traffic and to prevent the attack described above.

### No tracing, telemetry and no mixer checks

Note that currently no tracing and telemetry information can be collected for the egress traffic. Mixer policies cannot be applied. We are working to fix this in future Istio releases.

## Future work

In my next blog posts I will demonstrate Istio egress rules for TCP traffic and will show examples of combining routing rules and egress rules.

In Istio, we are working on making Istio egress traffic more secure, and in particular on enabling tracing, telemetry, and Mixer checks for the egress traffic.

## Conclusion

In this blog post I demonstrated how the microservices in an Istio service mesh can consume external web services via HTTPS. By default, Istio blocks all the traffic to the hosts outside the cluster. To enable such traffic, egress rules must be created for the service mesh. It is possible to access the external sites by HTTPS, however the microservices must issue HTTP requests while Istio will perform TLS origination. Currently, no tracing, telemetry and Mixer checks are enabled for the egress traffic. Egress rules are currently not a security feature, so additional mechanisms are required for securing egress traffic. We're working to enable logging/telemetry and security policies for the egress traffic in future releases.

To read more about Istio egress traffic control, see [Control Egress Traffic Task](/docs/tasks/traffic-management/egress/).

---
title: Distributed Tracing With Jaeger
description: How to configure the proxies to send tracing requests to Zipkin or Jaeger.
weight: 10
keywords: [telemetry,tracing]
aliases:
    - /docs/tasks/zipkin-tracing.html
---

This task shows you how Istio-enabled applications can be configured to collect trace spans.
After completing this task, you should understand all of the assumptions about your
application and how to have it participate in tracing, regardless of what
language/framework/platform you use to build your application.

The [Bookinfo](/docs/examples/bookinfo/) sample is used as the
example application for this task.

## Before you begin

Istio provides a choice of backend tracing providers.

<details><summary>Jaeger or Zipkin</summary>

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

    Either use the `istio-demo.yaml` or `istio-demo-auth.yaml` template, which includes tracing support, or
    use the Helm chart with tracing enabled by setting the `--set tracing.enabled=true` option and optionally
    selecting the required tracing provider using `--set tracing.provider=<provider>`. Currently supported
    providers are `jaeger` (the default) and `zipkin`.

</details>

<details><summary>LightStep</summary>

1.  Ensure you have a LightStep account. [Contact LightStep](https://lightstep.com/contact/) to create an account.

1.  Ensure you have a satellite pool configured with TLS certs and a secure GRPC port exposed. See
    [LightStep Satellite Setup](https://docs.lightstep.com/docs/satellite-setup) for details about setting up satellites.

1.  Ensure sure you have a LightStep access token.

1.  Ensure you can reach the satellite pool at an address in the format `<Host>:<Port>`, for example `lightstep-satellite.lightstep:9292`.

1.  Deploy Istio with the following configuration parameters specified:
    - `global.proxy.tracer="lightstep"`
    - `global.tracer.lightstep.address="<satellite-address>"`
    - `global.tracer.lightstep.accessToken="<access-token>"`
    - `global.tracer.lightstep.secure=true`
    - `global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"`

    If you are installing via `helm template` you can set these parameters using the `--set key=value` syntax
    when you run the `helm` command. For example:

    {{< text bash >}}
    $ helm template \
        --set global.proxy.tracer="lightstep" \
        --set global.tracer.lightstep.address="<satellite-address>" \
        --set global.tracer.lightstep.accessToken="<access-token>" \
        --set global.tracer.lightstep.secure=true \
        --set global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem" \
        install/kubernetes/helm/istio \
        --name istio --namespace istio-system > $HOME/istio.yaml
    $ kubectl create namespace istio-system
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

1.  Store your satellite pool's certificate authority certificate as a secret in the default namespace.
    If you deploy the Bookinfo application in a different namespace, create the secret in that namespace instead.

    {{< text bash >}}
    $ CACERT=$(cat Cert_Auth.crt | base64) # Cert_Auth.crt contains the necessary CACert
    $ NAMESPACE=default
    {{< /text >}}

    ```bash
    $ cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Secret
      metadata:
        name: lightstep.cacert
        namespace: $NAMESPACE
        labels:
          app: lightstep
      type: Opaque
      data:
        cacert.pem: $CACERT
    EOF
    ```

When using LightStep [𝑥]PM, we do not recommend reducing the trace sampling percentage below 100%. To handle a high traffic mesh, consider scaling up the size of your satellite pool.

</details>


Once the tracing backend has been configured, deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

## Accessing the dashboard

This section describes how to view the tracing information.

<details><summary>Jaeger or Zipkin</summary>

Setup access to the tracing dashboard by using port-forwarding:

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}') 15032:15032 &
{{< /text >}}

Access the dashboard by opening your browser to [http://localhost:15032](http://localhost:15032).

It is also possible to use a Kubernetes ingress by specifying the Helm chart option `--set tracing.ingress.enabled=true`.

</details>

<details><summary>LightStep</summary>

1.  Load the LightStep [𝑥]PM [web UI](https://app.lightstep.com/).

1.  Navigate to Explorer.

1.  Find the query bar at the top. The query bar allows you to interactively filter results by a **Service**, **Operation**, and **Tag** values.

</details>

## Generating traces using the Bookinfo sample

With the Bookinfo application up and running, generate trace information by accessing
`http://$GATEWAY_URL/productpage` one or more times.

<details><summary>Jaeger</summary>

From the left-hand pane of the dashboard, select `productpage` from the Service drop-down list and click
Find Traces. You should see something similar to the following:

{{< image width="100%" ratio="52.68%"
    link="./istio-tracing-list.png"
    caption="Tracing Dashboard"
    >}}

If you click on the top (most recent) trace, you should see the details corresponding to your
latest refresh of the `/productpage`.
The page should look something like this:

{{< image width="100%" ratio="36.32%"
    link="./istio-tracing-details.png"
    caption="Detailed Trace View"
    >}}

</details>

<details><summary>Zipkin</summary>

*** TO BE DONE ***

</details>

<details><summary>LightStep</summary>

1.  Select `productpage.default` from the **Service** drop-down list.

1.  Click **Run**. You see something similar to the following:

    {{< image width="100%" ratio="50%"
    link="./istio-tracing-list-lightstep.png"
    caption="Explorer"
    >}}

1.  Click on the first row in the table of example traces below the latency histogram to see the details
    corresponding to your refresh of the `/productpage`. The page then looks similar to:

    {{< image width="100%" ratio="50%"
    link="./istio-tracing-details-lightstep.png"
    caption="Detailed Trace View"
    >}}

The screenshot shows that the trace is comprised of a set of spans. Each span corresponds to a Bookinfo service invoked
during the execution of a `/productpage` request.

Two spans in the trace represent every RPC. For example, the call from `productpage` to `reviews` starts
with the span labeled with the `reviews.default.svc.cluster.local:9080/*` operation and the
`productpage.default: proxy client` service. This service represents the client-side span of the call. The screenshot shows
that the call took 15.30 ms. The second span is labeled with the `reviews.default.svc.cluster.local:9080/*` operation
and the `reviews.default: proxy server` service. The second span is a child of the first span and represents the
server-side span of the call. The screenshot shows that the call took 14.60 ms.

> {{< warning_icon >}} The LightStep integration does not currently capture spans generated by Istio's internal operation components such as Mixer.

</details>

As you can see, the trace is comprised of a set of spans,
where each span corresponds to a Bookinfo service invoked during the execution of a `/productpage` request.

Every RPC is represented by two spans in the trace. For example, the call from `productpage` to `reviews` starts
with the span labeled `productpage reviews.default.svc.cluster.local:9080/`, which represents the client-side
span for the call. It took 24.13 ms. The second span (labeled `reviews reviews.default.svc.cluster.local:9080/`)
is a child of the first span and represents the server-side span for the call. It took 22.99 ms.

The trace for the call to the `reviews` services reveals two subsequent RPC's in the trace. The first is to the `istio-policy`
service, reflecting the server-side Check call made for the service to authorize access. The second is the call out to
the `ratings` service.

## Understanding what happened

Although Istio proxies are able to automatically send spans, they need some hints to tie together the entire trace.
Applications need to propagate the appropriate HTTP headers so that when the proxies send span information,
the spans can be correlated correctly into a single trace.

To do this, an application needs to collect and propagate the following headers from the incoming request to any outgoing requests:

* `x-request-id`
* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`
* `x-ot-span-context`

If you look in the sample services, you can see that the `productpage` service (Python) extracts the required headers from an HTTP request:

{{< text python >}}
def getForwardHeaders(request):
    headers = {}

    if 'user' in session:
        headers['end-user'] = session['user']

    incoming_headers = [ 'x-request-id',
                         'x-b3-traceid',
                         'x-b3-spanid',
                         'x-b3-parentspanid',
                         'x-b3-sampled',
                         'x-b3-flags',
                         'x-ot-span-context'
    ]

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val
            #print "incoming: "+ihdr+":"+val

    return headers
{{< /text >}}

The reviews application (Java) does something similar:

{{< text jzvz >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId,
                            @HeaderParam("end-user") String user,
                            @HeaderParam("x-request-id") String xreq,
                            @HeaderParam("x-b3-traceid") String xtraceid,
                            @HeaderParam("x-b3-spanid") String xspanid,
                            @HeaderParam("x-b3-parentspanid") String xparentspanid,
                            @HeaderParam("x-b3-sampled") String xsampled,
                            @HeaderParam("x-b3-flags") String xflags,
                            @HeaderParam("x-ot-span-context") String xotspan) {
  int starsReviewer1 = -1;
  int starsReviewer2 = -1;

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), user, xreq, xtraceid, xspanid, xparentspanid, xsampled, xflags, xotspan);
{{< /text >}}

When you make downstream calls in your applications, make sure to include these headers.

## Trace sampling

Istio captures a trace for all requests by default. For example, when
using the Bookinfo sample application above, every time you access
`/productpage` you see a corresponding trace in the Jaeger
dashboard. This sampling rate is suitable for a test or low traffic
mesh. For a high traffic mesh you can lower the trace sampling
percentage in one of two ways:

* During the mesh setup, use the Helm option `pilot.traceSampling` to
  set the percentage of trace sampling. See the
  [Helm Install](/docs/setup/kubernetes/helm-install/) documentation for
  details on setting options.
* In a running mesh, edit the `istio-pilot` deployment and
  change the environment variable with the following steps:

    1. To open your text editor with the deployment configuration file
       loaded, run the following command:

        {{< text bash >}}
        $ kubectl -n istio-system edit deploy istio-pilot
        {{< /text >}}

    1. Find the `PILOT_TRACE_SAMPLING` environment variable, and change
       the `value:` to your desired percentage.

In both cases, valid values are from 0.0 to 100.0 with a precision of 0.01.

## Cleanup

<details><summary>Jaeger or Zipkin</summary>

*   Remove any `kubectl port-forward` processes that may still be running:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

</details>

<details><summary>LightStep</summary>

*   Remove the secret generated for LightStep [𝑥]PM:

    {{< text bash >}}
    $ kubectl delete secret lightstep.cacert
    {{< /text >}}

</details>

*   If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.

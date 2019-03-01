---
title: Overview
description: Overview of distributed tracing in Istio.
weight: 1
keywords: [telemetry,tracing]
---

After completing this task, you understand how to have your application participate in tracing,
regardless of the language, framework, or platform you use to build your application.

This task uses the [Bookinfo](/docs/examples/bookinfo/) sample as the example application.

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

{{< text java >}}
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
`/productpage` you see a corresponding trace in the
dashboard. This sampling rate is suitable for a test or low traffic
mesh. For a high traffic mesh you can lower the trace sampling
percentage in one of two ways:

* During the mesh setup, use the Helm option `pilot.traceSampling` to
  set the percentage of trace sampling. See the
  [Helm Install](/docs/setup/kubernetes/install/helm/) documentation for
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



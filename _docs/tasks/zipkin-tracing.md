---
title: Distributed Request Tracing
overview: How to configure the proxies to send tracing requests to Zipkin

order: 120

layout: docs
type: markdown
---
{% include home.html %}

This task shows you how Istio-enabled applications 
can be configured to collect trace spans using [Zipkin](http://zipkin.io). 
After completing this task, you should understand all of the assumptions about your
application and how to have it participate in tracing, regardless of what
language/framework/platform you use to build your application.

The [BooiInfo]({{home}}/docs/samples/bookinfo.html) sample is used as the
example application for this task.


## Before you begin

* Setup Istio by following the instructions in the [Installation guide](./installing-istio.html).

  If you didn't start the Zipkin addon during installation,
  you can run the following command to start it now:
  
  ```bash
  kubectl apply -f install/kubernetes/addons/zipkin.yaml
  ```

* Deploy the [BookInfo]({{home}}/docs/samples/bookinfo.html) sample application.


## Accessing the Zipkin dashboard

Locate the Zipkin dashboard URL (external IP, nodePort, or port-forwarding).
For example, using port-forwarding:

```bash
kubectl port-forward $(kubectl get pod -l app=zipkin -o jsonpath='{.items[0].metadata.name}') 9411:9411
```

Then open your browser at [http://localhost:9411](http://localhost:9411)


## Generating traces using the Bookinfo sample

With the Bookinfo application up and running, generate trace information by accessing
`http://$GATEWAY_URL/productpage` one or more times.

If you now look at the Zipkin dashboard, you should see something similar to the following:

{% include figure.html
   file="./img/zipkin_dashboard.png"
   max-width="100%"
   alt="Zipkin Istio Dashboard"
%}

If you click on the top (most recent) trace, you should see the details corresponding to your
latest refresh of the `/productpage`.
The page should look something like this:

{% include figure.html
   file="./img/zipkin_span.png"
   max-width="100%"
   alt="Zipkin Istio Dashboard"
%}

As you can see, there are 4 spans (only 3, if version v1 of the `reviews` service was used),
where each span corresponds to a Bookinfo service invoked during the execution of a `/productpage` request.
Although every service has the same label, `istio-proxy`, because the tracing is being done by
the Istio sidecar (Envoy proxy) which wraps the call to the actual service,
the label of the destination (to the right) identifies the service for which the time is represented by each line.

The first line represents the external call to the `productpage` service. The label `192.168.64.3:32000` is the host
value used for the external request (i.e., $GATEWAY_URL). As you can see in the trace,
the request took a total of roughly 290ms to complete. During its execution, the `productpage` called the `details` service,
which took about 24ms, and then called the `reviews` service.
The `reviews` service took about 243ms to execute, including a 15ms call to `ratings`.

## Understanding what happened

Although Istio proxies are able to automatically send spans to Zipkin, they need some hints to tie together the entire trace.
Applications need to propogate the appropriate HTTP headers so that when the proxies send span information to Zipkin,
the spans can be correlated correctly into a single trace.

To do this, an application needs to collect and propogate the following headers from the incoming request to any outgoing requests:

* `x-request-id`
* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`
* `x-ot-span-context`

If you look in the sample services, you can see that the productpage application (Python) extracts the required headers from an HTTP request:

```python
def getForwardHeaders(request):
    headers = {}

    user_cookie = request.cookies.get("user")
    if user_cookie:
        headers['Cookie'] = 'user=' + user_cookie

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
```

The reviews application (Java) does something similar:
 
```java
    @GET
    @Path("/reviews")
    public Response bookReviews(@CookieParam("user") Cookie user,
                                @HeaderParam("x-request-id") String xreq,
                                @HeaderParam("x-b3-traceid") String xtraceid,
                                @HeaderParam("x-b3-spanid") String xspanid,
                                @HeaderParam("x-b3-parentspanid") String xparentspanid,
                                @HeaderParam("x-b3-sampled") String xsampled,
                                @HeaderParam("x-b3-flags") String xflags,
                                @HeaderParam("x-ot-span-context") String xotspan) {
      String r1 = "";
      String r2 = "";

      if(ratings_enabled){
        JsonObject ratings = getRatings(user, xreq, xtraceid, xspanid, xparentspanid, xsampled, xflags, xotspan);
``` 

When you make downstream calls in your applications, make sure to include these headers.

## What's next

* Learn more about [Metrics and Logs]({{home}}/docs/tasks/metrics-logs.html)

* If you are not planning to explore any follow-on tasks, refer to the
  [BookInfo cleanup]({{home}}/docs/samples/bookinfo.html#cleanup) instructions
  to shutdown the application and cleanup the associated rules.

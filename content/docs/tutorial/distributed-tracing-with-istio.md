---
title: Distributed tracing with Istio
overview: Add Zipkin distributed tracing system.

weight: 105

---

The Istio dashboard and the log database can show which microservice called which microservice, for example,
_productpage_ called _reviews_, and what was the latency of the call. However, it is not enough.
You also want to know what happened during the whole call chain, in your case that _productpage_ called _reviews_ which
in turn called _ratings_. You want the time it took to process each step in the chain and the latency of each call in
the same chain.

To get data about a chain of calls between microservices, you need a
distributed tracing](https://microservices.io/patterns/observability/distributed-tracing.html) system. Istio comes
out-of-the-box with [Jaeger](https://www.jaegertracing.io), a distributed tracing system.

In this module you examine the traces of your application.

1.  Access your application's webpage several times.

1.  Access Jaeger UI at [http://my-istio-tracing.io](http://my-istio-tracing.io).
    (The `my-istio-logs-tracing.io` URL should be in your /etc/hosts file, you set it
    [previously](/docs/tutorial/run-bookinfo-with-kubernetes/#update-your-etc-hosts-file)).

    {{< image width="80%"
        link="images/jaeger-ui.png"
        caption="Jaeger UI"
        >}}

    Select your _productpage_ from the _Service_ drop-down menu, in the _Find Traces_ sidebar on the left,
    in the _Search_ tab. The service of the form `productpage.<your namespace>`.

1.  Examine one of the returned traces on the right:

    {{< image width="80%"
        link="images/jaeger-ui-productpage.png"
        caption="Jaeger UI, productpage trace"
        >}}

    You can see the date and the time when the trace was captured and that the whole chain of calls took 29.46 ms.
    You can see that _productpage_ called _details_ and that it took 2.33 ms for _details_ to return a response.
    For _productpage_, the time that elapsed between the call to _details_ and getting a response from it,
    was 3.11 ms.
    _productpage_ also called _reviews_ which called _ratings_. For _ratings_ it took 1.14 ms to return a response,
    for _reviews_, the time that elapsed between the call to _ratings_ and getting a response from it, was 2.12 ms.
    For _reviews_ it took 13.71 ms to return a response. You can see from the trace that the major contribution to the
    latency of the chain was by _reviews_ (13.71 ms out of the whole 29.46 ms).

Note that most of the Istio features are transparent to applications, which means you need to change neither the
applications' code nor their container environment.
Distributed tracing, however, comes with a price. You must change the code of your application to pass a set of HTTP
headers down the chain.
The list of the headers and code snippets in Python and Java are shown in
[Distributed Tracing Overview](/docs/tasks/telemetry/distributed-tracing/overview/#understanding-what-happened).

---
title: Logging with Istio
overview: Collecting and querying logs.
weight: 72
---

Logs and monitoring are important aspects of microservice architecture and are crucial to support transitioning to the microservices architecture style. Other requirements include rapid provisioning and rapid deployment, according to [this article](https://aadrake.com/posts/2017-05-20-enough-with-the-microservices.html).

With Istio, you gain monitoring and logging of the traffic between microservices by default.
You can use the Istio Dashboard for monitoring your microservices in real time.

In this module, you will learn how to inspect and query logs related to the traffic between your microservices.

1.  Store the name of your namespace in the `NAMESPACE` environment variable.
    You will need it to recognize your microservices in the logs:

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

1.  View the access log entries, related to your namespace:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep "accesslog.instance.istio-system" | grep "\"destinationNamespace\": \"$NAMESPACE\"" | grep '"reporter": "destination"'
    ...
    {"level":"info","time":"2019-02-17T06:49:14.078599Z","instance":"accesslog.logentry.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"mutual_tls","destinationApp":"details","destinationIp":"AAAAAAAAAAAAAP//rB5taA==","destinationName":"details-v1-58c68b9ff-l287q","destinationNamespace":"tutorial","destinationOwner":"kubernetes://apis/apps/v1/namespaces/tutorial/deployments/details-v1","destinationPrincipal":"cluster.local/ns/tutorial/sa/default","destinationServiceHost":"details.tutorial.svc.cluster.local","destinationWorkload":"details-v1","grpcMessage":"","grpcStatus":"","httpAuthority":"details:9080","latency":"2.403666ms","method":"GET","permissiveResponseCode":"none","permissiveResponsePolicyID":"none","protocol":"http","receivedBytes":1023,"referer":"","reporter":"destination","requestId":"b2094a51-367f-9e6c-8cfb-9f9a1166076c","requestSize":0,"requestedServerName":"outbound_.9080_._.details.tutorial.svc.cluster.local","responseCode":200,"responseFlags":"-","responseSize":178,"responseTimestamp":"2019-02-17T06:49:14.080840Z","sentBytes":313,"sourceApp":"productpage","sourceIp":"AAAAAAAAAAAAAP//rB5tTg==","sourceName":"productpage-v1-59b4f9f8d5-5z6r9","sourceNamespace":"tutorial","sourceOwner":"kubernetes://apis/apps/v1/namespaces/tutorial/deployments/productpage-v1","sourcePrincipal":"cluster.local/ns/tutorial/sa/default","sourceWorkload":"productpage-v1","url":"/details/0","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15","xForwardedFor":"0.0.0.0"}
    {"level":"info","time":"2019-02-17T06:49:14.094427Z","instance":"accesslog.logentry.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"mutual_tls","destinationApp":"ratings","destinationIp":"AAAAAAAAAAAAAP//rB6STA==","destinationName":"ratings-v1-b7b7fbbc9-c6lh5","destinationNamespace":"tutorial","destinationOwner":"kubernetes://apis/apps/v1/namespaces/tutorial/deployments/ratings-v1","destinationPrincipal":"cluster.local/ns/tutorial/sa/default","destinationServiceHost":"ratings.tutorial.svc.cluster.local","destinationWorkload":"ratings-v1","grpcMessage":"","grpcStatus":"","httpAuthority":"ratings:9080","latency":"956.847µs","method":"GET","permissiveResponseCode":"none","permissiveResponsePolicyID":"none","protocol":"http","receivedBytes":1039,"referer":"","reporter":"destination","requestId":"b2094a51-367f-9e6c-8cfb-9f9a1166076c","requestSize":0,"requestedServerName":"outbound_.9080_._.ratings.tutorial.svc.cluster.local","responseCode":200,"responseFlags":"-","responseSize":48,"responseTimestamp":"2019-02-17T06:49:14.095225Z","sentBytes":166,"sourceApp":"reviews","sourceIp":"AAAAAAAAAAAAAP//rB6SSA==","sourceName":"reviews-v3-6cf47594fd-5svrx","sourceNamespace":"tutorial","sourceOwner":"kubernetes://apis/apps/v1/namespaces/tutorial/deployments/reviews-v3","sourcePrincipal":"cluster.local/ns/tutorial/sa/default","sourceWorkload":"reviews-v3","url":"/ratings/0","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15","xForwardedFor":"0.0.0.0"}
    {"level":"info","time":"2019-02-17T06:49:14.085630Z","instance":"accesslog.logentry.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"mutual_tls","destinationApp":"reviews","destinationIp":"AAAAAAAAAAAAAP//rB6SSA==","destinationName":"reviews-v3-6cf47594fd-5svrx","destinationNamespace":"tutorial","destinationOwner":"kubernetes://apis/apps/v1/namespaces/tutorial/deployments/reviews-v3","destinationPrincipal":"cluster.local/ns/tutorial/sa/default","destinationServiceHost":"reviews.tutorial.svc.cluster.local","destinationWorkload":"reviews-v3","grpcMessage":"","grpcStatus":"","httpAuthority":"reviews:9080","latency":"13.630935ms","method":"GET","permissiveResponseCode":"none","permissiveResponsePolicyID":"none","protocol":"http","receivedBytes":1023,"referer":"","reporter":"destination","requestId":"b2094a51-367f-9e6c-8cfb-9f9a1166076c","requestSize":0,"requestedServerName":"outbound_.9080_.v3_.reviews.tutorial.svc.cluster.local","responseCode":200,"responseFlags":"-","responseSize":375,"responseTimestamp":"2019-02-17T06:49:14.099090Z","sentBytes":555,"sourceApp":"productpage","sourceIp":"AAAAAAAAAAAAAP//rB5tTg==","sourceName":"productpage-v1-59b4f9f8d5-5z6r9","sourceNamespace":"tutorial","sourceOwner":"kubernetes://apis/apps/v1/namespaces/tutorial/deployments/productpage-v1","sourcePrincipal":"cluster.local/ns/tutorial/sa/default","sourceWorkload":"productpage-v1","url":"/reviews/0","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15","xForwardedFor":"0.0.0.0"}
    {"level":"info","time":"2019-02-17T06:49:14.071252Z","instance":"accesslog.logentry.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"none","destinationApp":"productpage","destinationIp":"AAAAAAAAAAAAAP//rB5tTg==","destinationName":"productpage-v1-59b4f9f8d5-5z6r9","destinationNamespace":"tutorial","destinationOwner":"kubernetes://apis/apps/v1/namespaces/tutorial/deployments/productpage-v1","destinationPrincipal":"","destinationServiceHost":"productpage.tutorial.svc.cluster.local","destinationWorkload":"productpage-v1","grpcMessage":"","grpcStatus":"","httpAuthority":"tutorial.bookinfo.com","latency":"30.980332ms","method":"GET","permissiveResponseCode":"none","permissiveResponsePolicyID":"none","protocol":"http","receivedBytes":737,"referer":"","reporter":"destination","requestId":"b2094a51-367f-9e6c-8cfb-9f9a1166076c","requestSize":0,"requestedServerName":"","responseCode":200,"responseFlags":"-","responseSize":5845,"responseTimestamp":"2019-02-17T06:49:14.102102Z","sentBytes":6062,"sourceApp":"","sourceIp":"AAAAAAAAAAAAAP//AAAAAA==","sourceName":"unknown","sourceNamespace":"default","sourceOwner":"unknown","sourcePrincipal":"","sourceWorkload":"unknown","url":"/productpage","userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15","xForwardedFor":"10.127.220.66"}
    {{< /text >}}

    Notice the `sourceName` and `destinationName` attributes that identify who called whom, for example `productpage`
    called `reviews`. (For `productpage`, `sourceName` is a pod of `istio-ingressgateway`).
    Notice the HTTP-related attributes: `responseCode`, `url`, `method`.
    Also observe general communication attributes: `responseSize`, `responseTimestamp`, `latency`.

    Note that the log entries from all of Bookinfo microservices appear in one place.
    You do not have to go after each and every microservice and to display their logs one by one.

While you can work with logs as text files, you can do something smarter. Use
a log database, where you can query your logs, similar to querying structured
data in SQL databases. Querying a database is more efficient than searching
text, so you can run sophisticated queries to quickly get precise results. You
can also let the database process the results, for example to aggregate some
metrics.

Istio is integrated out-of-the-box with
[Prometheus time series database and monitoring system](https://prometheus.io). Prometheus collects various
traffic-related metrics and provides
[a rich query language](https://prometheus.io/docs/prometheus/latest/querying/basics/) for them.

See below several examples of Prometheus Istio-related queries.

1.  Access the Prometheus UI at [http://my-istio-logs-database.io](http://my-istio-logs-database.io).
(The `my-istio-logs-database.io` URL should be in your /etc/hosts file, you set it
[previously](/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)).

    {{< image width="80%" link="prometheus.png" caption="Prometheus Query UI" >}}

1.  Run the following example queries in the _Expression_ input box. Push the _Execute_ button to see query results in
the _Console_ tab. The queries use `tutorial` as the name of the application's namespace, substitute it with the name of
your namespace. For best results, run the real-time traffic simulator described in the previous steps when querying data.

    1. Get all the requests in your namespace:

        {{< text plain >}}
        istio_requests_total{destination_service_namespace="tutorial", reporter="destination"}
        {{< /text >}}

    1.  Get the sum of all the requests in your namespace:

        {{< text plain >}}
        sum(istio_requests_total{destination_service_namespace="tutorial", reporter="destination"})
        {{< /text >}}

    1.  Get the requests to `reviews` microservice:

        {{< text plain >}}
        istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}
        {{< /text >}}

    1.  [Rate](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate) of requests over the past 5 minutes to all instances of the `reviews` microservice:

        {{< text plain >}}
        rate(istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}[5m])
        {{< /text >}}

The queries above use the `istio_requests_total` metric, which is a standard Istio metric. You can observe
other metrics, in particular, the ones of Envoy ([Envoy](https://www.envoyproxy.io) is the sidecar proxy of Istio). You
can see the collected metrics in the _insert metric at cursor_ drop-down menu.

You can even [define your own metrics](/docs/tasks/observability/metrics/collecting-metrics/).

You are ready to [enable mutual TLS authentication with Istio](/docs/examples/microservices-istio/add-mtls).

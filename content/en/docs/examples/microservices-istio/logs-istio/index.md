---
title: Monitoring with Istio
overview: Collecting and querying mesh metrics.
weight: 72
---

Monitoring is crucial to support transitioning to the microservices architecture style. Other requirements include rapid provisioning and rapid deployment, according to [this article](https://aadrake.com/posts/2017-05-20-enough-with-the-microservices.html).

With Istio, you gain monitoring of the traffic between microservices by default.
You can use the Istio Dashboard for monitoring your microservices in real time.

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

You are ready to [enable mutual TLS authentication with Istio](/docs/examples/microservices-istio/add-mtls).

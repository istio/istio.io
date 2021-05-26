---
title: Monitoring with Istio
overview: Collecting and querying mesh metrics.
weight: 72
owner: istio/wg-docs-maintainers
test: no
---

Monitoring is crucial to support transitioning to the microservices architecture style.

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

## Next steps

Congratulations on completing the tutorial!

These tasks are a great place for beginners to further evaluate Istio's
features using this `demo` installation:

- [Request routing](/docs/tasks/traffic-management/request-routing/)
- [Fault injection](/docs/tasks/traffic-management/fault-injection/)
- [Traffic shifting](/docs/tasks/traffic-management/traffic-shifting/)
- [Querying metrics](/docs/tasks/observability/metrics/querying-metrics/)
- [Visualizing metrics](/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Accessing external services](/docs/tasks/traffic-management/egress/egress-control/)
- [Visualizing your mesh](/docs/tasks/observability/kiali/)

Before you customize Istio for production use, see these resources:

- [Deployment models](/docs/ops/deployment/deployment-models/)
- [Deployment best practices](/docs/ops/best-practices/deployment/)
- [Pod requirements](/docs/ops/deployment/requirements/)
- [General installation instructions](/docs/setup/)

## Join the Istio community

We welcome you to ask questions and give us feedback by joining the
[Istio community](/get-involved/).

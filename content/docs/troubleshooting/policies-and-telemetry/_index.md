---
title: Policy and Telemetry
weight: 10
type: section-index
---

## No traces appearing in Zipkin when running Istio locally on Mac

Istio is installed and everything seems to be working except there are no traces showing up in Zipkin when there
should be.

This may be caused by a known [Docker issue](https://github.com/docker/for-mac/issues/1260) where the time inside
containers may skew significantly from the time on the host machine. If this is the case,
when you select a very long date range in Zipkin you will see the traces appearing as much as several days too early.

You can also confirm this problem by comparing the date inside a docker container to outside:

{{< text bash >}}
$ docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

To fix the problem, you'll need to shutdown and then restart Docker before reinstalling Istio.

## No Grafana output when connecting from a local web client to Istio remotely hosted

Validate the client and server date and time match.

The time of the web client (e.g. Chrome) affects the output from Grafana. A simple solution
to this problem is to verify a time synchronization service is running correctly within the
Kubernetes cluster and the web client machine also is correctly using a time synchronization
service. Some common time synchronization systems are NTP and Chrony. This is especially
problematic is engineering labs with firewalls. In these scenarios, NTP may not be configured
properly to point at the lab-based NTP services.

## Where are the metrics for my service?

The expected flow of metrics is:

1. Envoy reports attributes to Mixer in batch (asynchronously from requests)
1. Mixer translates the attributes from Mixer into instances based on
   operator-provided configuration.
1. The instances are handed to Mixer adapters for processing and backend storage.
1. The backend storage systems record metrics data.

The default installations of Mixer ship with a [Prometheus](https://prometheus.io/)
adapter, as well as configuration for generating a basic set of metric
values and sending them to the Prometheus adapter. The
[Prometheus add-on](/docs/tasks/telemetry/querying-metrics/#about-the-prometheus-add-on)
also supplies configuration for an instance of Prometheus to scrape
Mixer for metrics.

If you do not see the expected metrics in the Istio Dashboard and/or via
Prometheus queries, there may be an issue at any of the steps in the flow
listed above. Below is a set of instructions to troubleshoot each of
those steps.

### Verify Mixer is receiving Report calls

Mixer generates metrics for monitoring the behavior of Mixer itself.
Check these metrics.

1.  Establish a connection to the Mixer self-monitoring endpoint.

    In Kubernetes environments, execute the following command:

    {{< text bash >}}
    $ kubectl -n istio-system port-forward <mixer pod> 9093 &
    {{< /text >}}

1.  Verify successful report calls.

    On the [Mixer self-monitoring endpoint](http://localhost:9093/metrics),
    search for `grpc_server_handled_total`.

    You should see something like:

    {{< text plain >}}
    grpc_server_handled_total{grpc_code="OK",grpc_method="Report",grpc_service="istio.mixer.v1.Mixer",grpc_type="unary"} 68
    {{< /text >}}

If you do not see any data for `grpc_server_handled_total` with a
`grpc_method="Report"`, then Mixer is not being called by Envoy to report
telemetry. In this case, ensure that the services have been properly
integrated into the mesh (either by via
[automatic](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)
or [manual](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection) sidecar injection).

### Verify Mixer metrics configuration exists

1.  Verify Mixer rules exist.

    In Kubernetes environments, issue the following command:

    {{< text bash >}}
    $ kubectl get rules --all-namespaces
    NAMESPACE      NAME        KIND
    istio-system   promhttp    rule.v1alpha2.config.istio.io
    istio-system   promtcp     rule.v1alpha2.config.istio.io
    istio-system   stdio       rule.v1alpha2.config.istio.io
    {{< /text >}}

    If you do not see anything named `promhttp` or `promtcp`, then there is
    no Mixer configuration for sending metric instances to a Prometheus adapter.
    You will need to supply configuration for rules that connect Mixer metric
    instances to a Prometheus handler.
<!-- todo replace ([example](https://github.com/istio/istio/blob/master/install/kubernetes/istio.yaml#L892)). -->

1.  Verify Prometheus handler config exists.

    In Kubernetes environments, issue the following command:

    {{< text bash >}}
    $ kubectl get prometheuses.config.istio.io --all-namespaces
    NAMESPACE      NAME           KIND
    istio-system   handler        prometheus.v1alpha2.config.istio.io
    {{< /text >}}

    If there are no prometheus handlers configured, you will need to reconfigure
    Mixer with the appropriate handler configuration.
<!-- todo replace ([example](https://github.com/istio/istio/blob/master/install/kubernetes/istio.yaml#L819)) -->

1.  Verify Mixer metric instances config exists.

    In Kubernetes environments, issue the following command:

    {{< text bash >}}
    $ kubectl get metrics.config.istio.io --all-namespaces
    NAMESPACE      NAME                         KIND
    istio-system   requestcount                 metric.v1alpha2.config.istio.io
    istio-system   requestduration              metric.v1alpha2.config.istio.io
    istio-system   requestsize                  metric.v1alpha2.config.istio.io
    istio-system   responsesize                 metric.v1alpha2.config.istio.io
    istio-system   stackdriverrequestcount      metric.v1alpha2.config.istio.io
    istio-system   stackdriverrequestduration   metric.v1alpha2.config.istio.io
    istio-system   stackdriverrequestsize       metric.v1alpha2.config.istio.io
    istio-system   stackdriverresponsesize      metric.v1alpha2.config.istio.io
    istio-system   tcpbytereceived              metric.v1alpha2.config.istio.io
    istio-system   tcpbytesent                  metric.v1alpha2.config.istio.io
    {{< /text >}}

    If there are no metric instances configured, you will need to reconfigure
    Mixer with the appropriate instance configuration.
<!-- todo replace ([example](https://github.com/istio/istio/blob/master/install/kubernetes/istio.yaml#L727)) -->

1.  Verify Mixer configuration resolution is working for your service.

    1.  Establish a connection to the Mixer self-monitoring endpoint.

        Setup a `port-forward` to the Mixer self-monitoring port as described in
        [Verify Mixer is receiving Report calls](#verify-mixer-is-receiving-report-calls).

    1.  On the [Mixer self-monitoring port](http://localhost:9093/metrics), search
        for `mixer_config_resolve_count`.

        You should find something like:

        {{< text plain >}}
        mixer_config_resolve_count{error="false",target="details.default.svc.cluster.local"} 56
        mixer_config_resolve_count{error="false",target="ingress.istio-system.svc.cluster.local"} 67
        mixer_config_resolve_count{error="false",target="mongodb.default.svc.cluster.local"} 18
        mixer_config_resolve_count{error="false",target="productpage.default.svc.cluster.local"} 59
        mixer_config_resolve_count{error="false",target="ratings.default.svc.cluster.local"} 26
        mixer_config_resolve_count{error="false",target="reviews.default.svc.cluster.local"} 54
        {{< /text >}}

    1.  Validate that there are values for `mixer_config_resolve_count` where
        `target="<your service>"` and `error="false"`.

        If there are only instances where `error="true"` where `target=<your service>`,
        there is likely an issue with Mixer configuration for your service. Logs
        information is needed to further debug.

        In Kubernetes environments, retrieve the Mixer logs via:

        {{< text bash >}}
        $ kubectl -n istio-system logs <mixer pod> -c mixer
        {{< /text >}}

        Look for errors related to your configuration or your service in the
        returned logs.

More on viewing Mixer configuration can be found [here](/help/faq/mixer/#mixer-self-monitoring)

### Verify Mixer is sending metric instances to the Prometheus adapter

1.  Establish a connection to the Mixer self-monitoring endpoint.

    Setup a `port-forward` to the Mixer self-monitoring port as described in
    [Verify Mixer is receiving Report calls](#verify-mixer-is-receiving-report-calls).

1.  On the [Mixer self-monitoring port](http://localhost:9093/metrics), search
    for `mixer_adapter_dispatch_count`.

    You should find something like:

    {{< text plain >}}
    mixer_adapter_dispatch_count{adapter="prometheus",error="false",handler="handler.prometheus.istio-system",meshFunction="metric",response_code="OK"} 114
    mixer_adapter_dispatch_count{adapter="prometheus",error="true",handler="handler.prometheus.default",meshFunction="metric",response_code="INTERNAL"} 4
    mixer_adapter_dispatch_count{adapter="stdio",error="false",handler="handler.stdio.istio-system",meshFunction="logentry",response_code="OK"} 104
    {{< /text >}}

1.  Validate that there are values for `mixer_adapter_dispatch_count` where
    `adapter="prometheus"` and `error="false"`.

    If there are are no recorded dispatches to the Prometheus adapter, there
    is likely a configuration issue. Please see
    [Verify Mixer metrics configuration exists](#verify-mixer-metrics-configuration-exists).

    If dispatches to the Prometheus adapter are reporting errors, check the
    Mixer logs to determine the source of the error. Most likely, there is a
    configuration issue for the handler listed in `mixer_adapter_dispatch_count`.

    In Kubernetes environment, check the Mixer logs via:

    {{< text bash >}}
    $ kubectl -n istio-system logs <mixer pod> -c mixer
    {{< /text >}}

    Filter for lines including something like `Report 0 returned with: INTERNAL
    (1 error occurred:` (with some surrounding context) to find more information
    regarding Report dispatch failures.

### Verify Prometheus configuration

1. Connect to the Prometheus UI and verify that it can successfully
scrape Mixer.

    In Kubernetes environments, setup port-forwarding as follows:

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

1. Visit [http://localhost:9090/targets](http://localhost:9090/targets) and confirm that the target `istio-mesh` has a status of **UP**.

1. Visit [http://localhost:9090/config](http://localhost:9090/config) and confirm that an entry exists that looks like:

    {{< text yaml >}}
    - job_name: istio-mesh
    scrape_interval: 5s
    scrape_timeout: 5s
    metrics_path: /metrics
    scheme: http
    kubernetes_sd_configs:
    - api_server: null
        role: endpoints
        namespaces:
        names: []
    relabel_configs:
    - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        separator: ;
        regex: istio-system;istio-telemetry;prometheus
        replacement: $1
        action: keep
    {{< /text >}}

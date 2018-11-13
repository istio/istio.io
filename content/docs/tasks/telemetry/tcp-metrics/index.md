---
title: Collecting Metrics for TCP services
description: This task shows you how to configure Istio to collect metrics for TCP services.
weight: 25
keywords: [telemetry,metrics,tcp]
---

This task shows how to configure Istio to automatically gather telemetry for TCP
services in a mesh. At the end of this task, a new metric will be enabled for
calls to a TCP service within your mesh.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used
as the example application throughout this task.

## Before you begin

* [Install Istio](/docs/setup/) in your cluster and deploy an
application.

* This task assumes that the Bookinfo sample will be deployed in the `default`
namespace. If you use a different namespace, you will need to update the
example configuration and commands.

## Collecting new telemetry data

1.  Create a new YAML file to hold configuration for the new metrics that Istio
will generate and collect automatically.

    Save the following as `tcp_telemetry.yaml`:

    {{< text yaml >}}
    # Configuration for a metric measuring bytes sent from a server
    # to a client
    apiVersion: "config.istio.io/v1alpha2"
    kind: metric
    metadata:
      name: mongosentbytes
      namespace: default
    spec:
      value: connection.sent.bytes | 0 # uses a TCP-specific attribute
      dimensions:
        source_service: source.workload.name | "unknown"
        source_version: source.labels["version"] | "unknown"
        destination_version: destination.labels["version"] | "unknown"
      monitoredResourceType: '"UNSPECIFIED"'
    ---
    # Configuration for a metric measuring bytes sent from a client
    # to a server
    apiVersion: "config.istio.io/v1alpha2"
    kind: metric
    metadata:
      name: mongoreceivedbytes
      namespace: default
    spec:
      value: connection.received.bytes | 0 # uses a TCP-specific attribute
      dimensions:
        source_service: source.workload.name | "unknown"
        source_version: source.labels["version"] | "unknown"
        destination_version: destination.labels["version"] | "unknown"
      monitoredResourceType: '"UNSPECIFIED"'
    ---
    # Configuration for a Prometheus handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: prometheus
    metadata:
      name: mongohandler
      namespace: default
    spec:
      metrics:
      - name: mongo_sent_bytes # Prometheus metric name
        instance_name: mongosentbytes.metric.default # Mixer instance name (fully-qualified)
        kind: COUNTER
        label_names:
        - source_service
        - source_version
        - destination_version
      - name: mongo_received_bytes # Prometheus metric name
        instance_name: mongoreceivedbytes.metric.default # Mixer instance name (fully-qualified)
        kind: COUNTER
        label_names:
        - source_service
        - source_version
        - destination_version
    ---
    # Rule to send metric instances to a Prometheus handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: mongoprom
      namespace: default
    spec:
      match: context.protocol == "tcp"
             && destination.service.host == "mongodb.default.svc.cluster.local"
      actions:
      - handler: mongohandler.prometheus
        instances:
        - mongoreceivedbytes.metric
        - mongosentbytes.metric
    {{< /text >}}

1.  Push the new configuration.

    {{< text bash >}}
    $ kubectl apply -f tcp_telemetry.yaml
    Created config metric/default/mongosentbytes at revision 3852843
    Created config metric/default/mongoreceivedbytes at revision 3852844
    Created config prometheus/default/mongohandler at revision 3852845
    Created config rule/default/mongoprom at revision 3852846
    {{< /text >}}

1.  Setup Bookinfo to use MongoDB.

    1.  Install `v2` of the `ratings` service.

        If you are using a cluster with automatic sidecar injection enabled,
        simply deploy the services using `kubectl`:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        {{< /text >}}

        If you are using manual sidecar injection, use the following command instead:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
        deployment "ratings-v2" configured
        {{< /text >}}

    1.  Install the `mongodb` service:

        If you are using a cluster with automatic sidecar injection enabled,
        simply deploy the services using `kubectl`:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
        {{< /text >}}

        If you are using manual sidecar injection, use the following command instead:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@)
        service "mongodb" configured
        deployment "mongodb-v1" configured
        {{< /text >}}

    1.  The Bookinfo sample deploys multiple versions of each microservice, so you will start by creating destination rules
        that define the service subsets corresponding to each version, and the load balancing policy for each subset.

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
        {{< /text >}}

        If you enabled mutual TLS, please run the following instead

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
        {{< /text >}}

        You can display the destination rules with the following command:

        {{< text bash >}}
        $ kubectl get destinationrules -o yaml
        {{< /text >}}

        Since the subset references in virtual services rely on the destination rules,
        wait a few seconds for destination rules to propagate before adding virtual services that refer to these subsets.

    1.  Create `ratings` and `reviews` virtual services:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
        Created config virtual-service/default/reviews at revision 3003
        Created config virtual-service/default/ratings at revision 3004
        {{< /text >}}

1.  Send traffic to the sample application.

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or issue the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Verify that the new metric values are being generated and collected.

    In a Kubernetes environment, setup port-forwarding for Prometheus by
    executing the following command:

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

    View values for the new metric via the [Prometheus UI](http://localhost:9090/graph#%5B%7B%22range_input%22%3A%221h%22%2C%22expr%22%3A%22istio_mongo_received_bytes%22%2C%22tab%22%3A1%7D%5D).

    The provided link opens the Prometheus UI and executes a query for values of
    the `istio_mongo_received_bytes` metric. The table displayed in the
    **Console** tab includes entries similar to:

    {{< text plain >}}
    istio_mongo_received_bytes{destination_version="v1",instance="172.17.0.18:42422",job="istio-mesh",source_service="ratings-v2",source_version="v2"}
    {{< /text >}}

    > Istio also collects protocol-specific statistics for MongoDB. For
    > example, the value of total OP_QUERY messages sent from the `ratings` service
    > is collected in the following metric:
    > `envoy_mongo_outbound_27017__mongodb_default_svc_cluster_local_collection_ratings_query_total`
    > (click [here](http://localhost:9090/graph#%5B%7B%22range_input%22%3A%221h%22%2C%22expr%22%3A%22envoy_mongo_outbound_27017__mongodb_default_svc_cluster_local_collection_ratings_query_total%22%2C%22tab%22%3A1%7D%5D)
    > to execute the query).

## Understanding TCP telemetry collection

In this task, you added Istio configuration that instructed Mixer to
automatically generate and report a new metric for all traffic to a TCP service
within the mesh.

Similar to the [Collecting Metrics and
Logs](/docs/tasks/telemetry/metrics-logs/) Task, the new
configuration consisted of _instances_, a _handler_, and a _rule_. Please see
that Task for a complete description of the components of metric collection.

Metrics collection for TCP services differs only in the limited set of
attributes that are available for use in _instances_.

### TCP attributes

Several TCP-specific attributes enable TCP policy and control within Istio.
These attributes are generated by server-side Envoy proxies. They are forwarded to Mixer at connection establishment, and forwarded periodically when connection is alive (periodical report), and forwarded at connection close (final report). The default interval for periodical report is 10 seconds, and it should be at least 1 second. Additionally, context attributes provide the ability to distinguish between `http` and `tcp`
protocols within policies.

{{< image width="100%" ratio="192.50%"
    link="./istio-tcp-attribute-flow.svg"
    alt="Attribute Generation Flow for TCP Services in an Istio Mesh."
    caption="TCP Attribute Flow"
    >}}

## Cleanup

*   Remove the new telemetry configuration:

    {{< text bash >}}
    $ kubectl delete -f tcp_telemetry.yaml
    {{< /text >}}

*   Remove the `port-forward` process:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.

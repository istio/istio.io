---
title: Collecting Metrics for TCP services
description: This task shows you how to configure Istio to collect metrics for TCP services.
weight: 20
keywords: [telemetry,metrics,tcp]
aliases:
    - /docs/tasks/telemetry/tcp-metrics
    - /docs/tasks/telemetry/metrics/tcp-metrics/
---

This task shows how to configure Istio to automatically gather telemetry for TCP
services in a mesh. At the end of this task, a new metric will be enabled for
calls to a TCP service within your mesh.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used
as the example application throughout this task.

## Before you begin

* [Install Istio](/docs/setup) in your cluster and deploy an
application.

* This task assumes that the Bookinfo sample will be deployed in the `default`
namespace. If you use a different namespace, you will need to update the
example configuration and commands.

## Collecting new telemetry data

1.  Apply a YAML file with configuration for the new metrics that Istio
will generate and collect automatically.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/tcp-metrics.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/tcp-metrics-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

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

    View values for the new metric in the Prometheus browser window.  Select **Graph**.
    Enter the `istio_mongo_received_bytes` metric and select **Execute**.
    The table displayed in the
    **Console** tab includes entries similar to:

    {{< text plain >}}
    istio_mongo_received_bytes{destination_version="v1",instance="172.17.0.18:42422",job="istio-mesh",source_service="ratings-v2",source_version="v2"}
    {{< /text >}}

## Understanding TCP telemetry collection

In this task, you added Istio configuration that instructed Mixer to
automatically generate and report a new metric for all traffic to a TCP service
within the mesh.

Similar to the [Collecting Metrics](/docs/tasks/observability/mixer/metrics/collecting-metrics/) Task, the new
configuration consisted of _instances_, a _handler_, and a _rule_. Please see
that Task for a complete description of the components of metric collection.

Metrics collection for TCP services differs only in the limited set of
attributes that are available for use in _instances_.

### TCP attributes

Several TCP-specific attributes enable TCP policy and control within Istio.
These attributes are generated by server-side Envoy proxies. They are forwarded to Mixer at connection establishment, and forwarded periodically when connection is alive (periodical report), and forwarded at connection close (final report). The default interval for periodical report is 10 seconds, and it should be at least 1 second. Additionally, context attributes provide the ability to distinguish between `http` and `tcp`
protocols within policies.

{{< image link="./istio-tcp-attribute-flow.svg"
    alt="Attribute Generation Flow for TCP Services in an Istio Mesh."
    caption="TCP Attribute Flow"
    >}}

## Cleanup

*   Remove the new telemetry configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/tcp-metrics.yaml@
    {{< /text >}}

    If you are using Istio 1.1.2 or prior:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/tcp-metrics-crd.yaml@
    {{< /text >}}

*   Remove the `port-forward` process:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.

---
title: Collecting Metrics for TCP Services
description: This task shows you how to configure Istio to collect metrics for TCP services.
weight: 20
keywords: [telemetry,metrics,tcp]
aliases:
    - /docs/tasks/telemetry/tcp-metrics
    - /docs/tasks/telemetry/metrics/tcp-metrics/
---

This task shows how to configure Istio to automatically gather telemetry for TCP
services in a mesh. At the end of this task, you can query default TCP metrics for your mesh.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used
as the example throughout this task.

## Before you begin

* [Install Istio](/docs/setup) in your cluster and deploy an
application.

* This task assumes that the Bookinfo sample will be deployed in the `default`
namespace. If you use a different namespace, update the
example configuration and commands.

## Collecting new telemetry data

1.  Setup Bookinfo to use MongoDB.

    1.  Install `v2` of the `ratings` service.

        If you are using a cluster with automatic sidecar injection enabled,
        deploy the services using `kubectl`:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        {{< /text >}}

        If you are using manual sidecar injection, run the following command instead:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
        deployment "ratings-v2" configured
        {{< /text >}}

    1.  Install the `mongodb` service:

        If you are using a cluster with automatic sidecar injection enabled,
        deploy the services using `kubectl`:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
        {{< /text >}}

        If you are using manual sidecar injection, run the following command instead:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@)
        service "mongodb" configured
        deployment "mongodb-v1" configured
        {{< /text >}}

    1.  The Bookinfo sample deploys multiple versions of each microservice, so begin by creating destination rules
        that define the service subsets corresponding to each version, and the load balancing policy for each subset.

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
        {{< /text >}}

        If you enabled mutual TLS, run the following command instead:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
        {{< /text >}}

        To display the destination rules, run the following command:

        {{< text bash >}}
        $ kubectl get destinationrules -o yaml
        {{< /text >}}

        Wait a few seconds for destination rules to propagate before adding virtual services that refer to these subsets, because the subset references in virtual services rely on the destination rules.

    1.  Create `ratings` and `reviews` virtual services:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
        Created config virtual-service/default/reviews at revision 3003
        Created config virtual-service/default/ratings at revision 3004
        {{< /text >}}

1.  Send traffic to the sample application.

    Set `$GATEWAY_URL` using [these instructions](/docs/setup/getting-started/#determining-the-ingress-ip-and-ports)

    For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
    browser or use the following command:

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  Verify that the TCP metric values are being generated and collected.

    In a Kubernetes environment, setup port-forwarding for Prometheus by
    using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

    View the values for the TCP metrics in the Prometheus browser window.  Select **Graph**.
    Enter the `istio_tcp_connections_opened_total` metric or `istio_tcp_connections_closed_total` and select **Execute**.
    The table displayed in the
    **Console** tab includes entries similar to:

    {{< text plain >}}
    istio_tcp_connections_opened_total{destination_version="v1",instance="172.17.0.18:42422",job="istio-mesh",source_service="ratings-v2",source_version="v2"}
    {{< /text >}}

    {{< text plain >}}
    istio_tcp_connections_closed_total{destination_version="v1",instance="172.17.0.18:42422",job="istio-mesh",source_service="ratings-v2",source_version="v2"}
    {{< /text >}}

## Understanding TCP telemetry collection

In this task, you used Istio configuration to
automatically generate and report metrics for all traffic to a TCP service
within the mesh.

### TCP attributes

Several TCP-specific attributes enable TCP policy and control within Istio.
These attributes are generated by Envoy Proxies and obtained from Istio using Envoy's Node Metadata.
Envoy forwards Node Metadata to Peer Envoys using ALPN based tunneling and a prefix based protocol.
We define a new protocol `istio-peer-exchange`, that is advertised and prioritized by the client and the server sidecars
in the mesh. ALPN negotiation resolves the protocol to `istio-peer-exchange` for connections between Istio enabled
proxies, but not between an Istio enabled proxy and any other proxy.
This protocol extends TCP as follows:

1.  TCP client, as a first sequence of bytes, sends a magic byte string and a length prefixed payload.
1.  TCP server, as a first sequence of bytes, sends a magic byte sequence and a length prefixed payload. These payloads
 are protobuf encoded serialized metadata.
1.  Client and server can write simultaneously and out of order. The extension filter in Envoy then does the further
 processing in downstream and upstream until either the magic byte sequence is not matched or the entire payload is read.

{{< image link="./alpn-based-tunneling-protocol.svg"
    alt="Attribute Generation Flow for TCP Services in an Istio Mesh."
    caption="TCP Attribute Flow"
    >}}

## Cleanup

*   Remove the `port-forward` process:

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.

---
title: Customizing Istio Metrics
description: This task shows you how to customize the Istio metrics.
weight: 25
keywords: [telemetry,metrics,customize]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

This task shows you how to customize the metrics that Istio generates.

Istio generates telemetry that various dashboards consume to help you visualize
your mesh. For example, dashboards that support Istio include:

* [Grafana](/docs/tasks/observability/metrics/using-istio-dashboard/)
* [Kiali](/docs/tasks/observability/kiali/)
* [Prometheus](/docs/tasks/observability/metrics/querying-metrics/)

By default, Istio defines and generates a set of standard metrics (e.g.
`requests_total`), but you can also customize them and create new metrics
using the [Telemetry API](/docs/tasks/observability/telemetry/).

## Before you begin

[Install Istio](/docs/setup/) in your cluster and deploy an application.
Alternatively, you can set up custom statistics as part of the Istio
installation.

The [Bookinfo](/docs/examples/bookinfo/) sample application is used as
the example application throughout this task. For installation instructions, see [deploying the Bookinfo application](/docs/examples/bookinfo/#deploying-the-application).

## Enable custom metrics

To customize telemetry v2 metrics, for example, to add `request_host`
and `destination_port` dimensions to the `requests_total` metric emitted by both
gateways and sidecars in the inbound and outbound direction, use the following:

{{< text bash >}}
$ cat <<EOF > ./custom_metrics.yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: namespace-metrics
spec:
  metrics:
  - providers:
    - name: prometheus
    overrides:
    - match:
        metric: REQUEST_COUNT
      tagOverrides:
        destination_port:
          value: "string(destination.port)"
        request_host:
          value: "request.host"
EOF
$ kubectl apply -f custom_metrics.yaml
{{< /text >}}

## Verify the results

Send traffic to the mesh. For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
browser or issue the following command:

{{< text bash >}}
$ curl "http://$GATEWAY_URL/productpage"
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` is the value set in the [Bookinfo](/docs/examples/bookinfo/) example.
{{< /tip >}}

Use the following command to verify that Istio generates the data for your new
or modified dimensions:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -- curl -sS 'localhost:15000/stats/prometheus' | grep istio_requests_total
{{< /text >}}

For example, in the output, locate the metric `istio_requests_total` and
verify it contains your new dimension.

{{< tip >}}
It might take a short period of time for the proxies to start applying the config. If the metric is not received,
you may retry sending requests after a short wait, and look for the metric again.
{{< /tip >}}

## Use expressions for values

The values in the metric configuration are common expressions, which means you
must double-quote strings in JSON, e.g. "'string value'". Unlike Mixer
expression language, there is no support for the pipe (`|`) operator, but you
can emulate it with the `has` or `in` operator, for example:

{{< text plain >}}
has(request.host) ? request.host : "unknown"
{{< /text >}}

For more information, see [Common Expression Language](https://opensource.google/projects/cel).

Istio exposes all standard [Envoy attributes](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/attributes).
Peer metadata is available as attributes `upstream_peer` for outbound and `downstream_peer` for inbound with the following fields:

|Field   | Type  | Value |
|---|---|---|
| `name` | `string` | Name of the pod. |
| `namespace` | `string` | Namespace that the pod runs in. |
| `labels` | `map` | Workload labels. |
| `owner` | `string` | Workload owner. |
| `workload_name` | `string` | Workload name. |
| `platform_metadata` | `map` |  Platform metadata with prefixed keys. |
| `istio_version` | `string` | Version identifier for the proxy. |
| `mesh_id` | `string` | Unique identifier for the mesh. |
| `app_containers` | `list<string>` | List of short names for application containers. |
| `cluster_id` | `string` | Identifier for the cluster to which this workload belongs. |

For example, the expression for the peer `app` label to be used in an outbound configuration is
`upstream_peer.labels['app'].value`.

## Cleanup

To delete the `Bookinfo` sample application and its configuration, see
[`Bookinfo` cleanup](/docs/examples/bookinfo/#cleanup).

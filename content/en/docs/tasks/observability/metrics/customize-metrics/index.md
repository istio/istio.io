---
title: Customizing Istio Metrics
description: This task shows you how to customize the Istio metrics.
weight: 25
keywords: [telemetry,metrics,customize]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

This task shows you how to customize the metrics that Istio generates.

Istio generates telemetry that various dashboards consume to help you visualize
your mesh. For example, dashboards that support Istio include:

* [Grafana](/docs/tasks/observability/metrics/using-istio-dashboard/)
* [Kiali](/docs/tasks/observability/kiali/)
* [Prometheus](/docs/tasks/observability/metrics/querying-metrics/)

By default, Istio defines and generates a set of standard metrics (e.g.
`requests_total`), but you can also customize them and create new metrics.

## Custom statistics configuration

Istio uses the Envoy proxy to generate metrics and provides its configuration in
the `EnvoyFilter` at
[`manifests/charts/istio-control/istio-discovery/templates/telemetryv2_1.6.yaml`]({{<github_blob>}}/manifests/charts/istio-control/istio-discovery/templates/telemetryv2_1.6.yaml).

Configuring custom statistics involves two sections of the
`EnvoyFilter`: `definitions` and `metrics`. The `definitions` section
supports creating new metrics by name, the expected value expression, and the
metric type (`counter`, `gauge`, and `histogram`). The `metrics` section
provides values for the metric dimensions as expressions, and allows you to
remove or override the existing metric dimensions. You can modify the standard
metric definitions using `tags_to_remove` or by re-defining a dimension.

For more information, see [Stats Config reference](/docs/reference/config/proxy_extensions/stats/).

## Before you begin

[Install Istio](/docs/setup/) in your cluster and deploy an application.
Alternatively, you can set up custom statistics as part of the Istio
installation.

## Enable custom metrics

Edit the `EnvoyFilter` to add or modify dimensions and metrics. Then, add
annotations to all the Istio-enabled pods to extract the new or modified
dimensions.

1. Find the `stats-filter-1.6` `EnvoyFilter` resource from the `istio-system`
   namespace, using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter | grep ^stats-filter-1.6
    stats-filter-1.6                    2d
    {{< /text >}}

1. Create a local file system copy of the `EnvoyFilter` configuration, using the
   following command:

    {{< text bash >}}
    $ kubectl -n istio-system get envoyfilter stats-filter-1.6 -o yaml > stats-filter-1.6.yaml
    {{< /text >}}

1. Open `stats-filter-1.6.yaml` with a text editor and locate the
   `envoy.wasm.stats` extension configuration. The default configuration is in
   the `configuration` section and looks like this example:

    {{< text json >}}
    {
    "debug": "false",
    "stat_prefix": "istio"
    }
    {{< /text >}}

1. Edit `stats-filter-1.6.yaml` and modify the configuration section for each
   instance of the extension configuration. For example, to add
   `destination_port` and `request_host` dimensions to the standard
   `requests_total` metric, change the configuration section to look like the
   following. Istio automatically prefixes all metric names with `istio_`, so
   omit the prefix from the name field in the metric specification.

    {{< text json >}}
    {
        "debug": "false",
        "stat_prefix": "istio",
        "metrics": [
            {
                "name": "requests_total",
                "dimensions": {
                    "destination_port": "string(destination.port)",
                    "request_host": "request.host"
                }
            }
        ]
    }
    {{< /text >}}

1. Save `stats-filter-1.6.yaml` and then apply the configuration using the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f stats-filter-1.6.yaml
    {{< /text >}}

1. Apply the following annotation to all injected pods with the list of the
   dimensions to extract into a Prometheus
   [time series](https://en.wikipedia.org/wiki/Time_series) using the following command:

    {{< tip >}}
    This step is needed only  if your dimensions are not already in
    [DefaultStatTags list]({{<github_blob>}}/pkg/bootstrap/config.go)
    {{< /tip >}}

    {{< text yaml >}}
    apiVersion: apps/v1
    kind: Deployment
    spec:
      template: # pod template
        metadata:
          annotations:
            sidecar.istio.io/extraStatTags: destination_port,request_host
    {{< /text >}}

## Verify the results

Use the following command to verify that Istio generates the data for your new
or modified dimensions:

{{< text bash >}}
$ kubectl exec pod-name -c istio-proxy -- curl 'localhost:15000/stats/prometheus' | grep istio
{{< /text >}}

For example, in the output, locate the metric `istio_requests_total` and
verify it contains your new dimension.

## Use expressions for values

The values in the metric configuration are common expressions, which means you
must double-quote strings in JSON, e.g. "'string value'". Unlike Mixer
expression language, there is no support for the pipe (`|`) operator, but you
can emulate it with the `has` or `in` operator, for example:

{{< text plain >}}
has(request.host) ? request.host : "unknown"
{{< /text >}}

For more information, see [Common Expression Language](https://opensource.google/projects/cel).

Istio exposes all standard Envoy attributes. Additionally, you can use the
following extra attributes.

|Attribute   | Type  | Value |
|---|---|---|
| `listener_direction` | int64 | Enumeration value for [listener direction](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/core/base.proto#envoy-api-enum-core-trafficdirection) |
| `listener_metadata` | [metadata](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/core/base.proto#core-metadata) | Per-listener metadata |
| `route_metadata` | [metadata](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/core/base.proto#core-metadata) | Per-route metadata |
| `cluster_metadata` | [metadata](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/core/base.proto#core-metadata) | Per-cluster metadata |
| `node` | [node](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/core/base.proto#core-node) | Node description |
| `cluster_name` | string | Upstream cluster name |
| `route_name` | string | Route name |
| `filter_state` | map[string, bytes] | Per-filter state blob |
| `plugin_name` | string | Wasm extension name |
| `plugin_root_id` | string | Wasm root instance ID |
| `plugin_vm_id` | string | Wasm VM ID |

For more information, see [configuration reference](/docs/reference/config/proxy_extensions/stats/).

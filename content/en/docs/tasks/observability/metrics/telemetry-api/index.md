---
title: Customizing Istio Metrics with Telemetry API
description: This task shows you how to customize the Istio metrics with Telemetry API.
weight: 10
keywords: [telemetry,metrics,customize]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

Telemetry API has been in Istio as a first-class API for quite sometime now.
Previously users had to configure metrics in the `telemetry` section of Istio configuration,
This task shows you how to customize the metrics that Istio generates with Telemetry API.

## Before you begin

[Install Istio](/docs/setup/) in your cluster and deploy an application.
Telemetry API can not work together with the `EnvoyFilter` way, for more details please checkout [this](https://github.com/istio/istio/issues/39772).
From `1.18`, stats `EnvoyFilter` will not be installed by default.
For version before `1.18`, you should install with following configuration in `IstioOperator` configuration:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    telemetry:
      enabled: true
      v2:
        enabled: false
{{< /text >}}

## Override metrics

The `metrics` section provides values for the metric dimensions as expressions,
and allows you to remove or override the existing metric dimensions.
You can modify the standard metric definitions using `tags_to_remove` or by re-defining a dimension.

1. Remove `grpc_response_status` tags from `REQUEST_COUNT` metric

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: remove-tags
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - match:
                mode: CLIENT_AND_SERVER
                metric: REQUEST_COUNT
              tagOverrides:
                grpc_response_status:
                  operation: REMOVE
    {{< /text >}}

1. Add custom tags for `REQUEST_COUNT` metric

    Telemetry API can not update `extraStatTags` in `MeshConfig`,
    you need update `extraStatTags` and rollout deployment manually.

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: custom-tags
      namespace: istio-system
    spec:
      metrics:
        - overrides:
            - match:
                metric: ALL_METRICS
                mode: CLIENT
              tagOverrides:
                destination_x:
                  value: upstream_peer.labels['app'].value
            - match:
                metric: ALL_METRICS
                mode: SERVER
              tagOverrides:
                source_x:
                  value: downstream_peer.labels['app'].value
          providers:
            - name: prometheus
    {{< /text >}}

## Disable metrics

1. Disable all metrics by following configuration:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: remove-all-metrics
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT_AND_SERVER
                metric: ALL_METRICS
    {{< /text >}}

1. Disable `REQUEST_COUNT` metrics by following configuration:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: remove-request-count
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT_AND_SERVER
                metric: REQUEST_COUNT
    {{< /text >}}

1. Disable `REQUEST_COUNT` metrics for client by following configuration:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: remove-client
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT
                metric: REQUEST_COUNT
    {{< /text >}}

1. Disable `REQUEST_COUNT` metrics for server by following configuration:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: remove-server
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: SERVER
                metric: REQUEST_COUNT
    {{< /text >}}

## Custom metric reporting interval

Telemetry API allows configuration of the time between calls out to for TCP metrics reporting.
The default duration is `5s`, changing to `10s` by following configuration:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: reporting-interval
  namespace: istio-system
spec:
  metrics:
    - providers:
        - name: prometheus
      reportingInterval: 10s
{{< /text >}}

{{< tip >}}
This currently only supports TCP metrics but we may use this for long duration HTTP streams in the future.
{{< /tip >}}

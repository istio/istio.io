---
title: Configure access logs with Telemetry API
description: This task shows you how to configure Envoy proxies to send access logs with Telemetry API.
weight: 10
keywords: [telemetry,logs]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Telemetry API has been in Istio as a first-class API for quite sometime now.
Previously users had to configure telemetry in the `MeshConfig` section of Istio configuration.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## Installation

In this example, we will send logs to [Grafana Loki](https://grafana.com/oss/loki/) so make sure it is installed:

{{< text syntax=bash snip_id=install_loki >}}
$ istioctl install -f @samples/open-telemetry/loki/iop.yaml@ --skip-confirmation
$ kubectl apply -f @samples/addons/loki.yaml@ -n istio-system
$ kubectl apply -f @samples/open-telemetry/loki/otel.yaml@ -n istio-system
{{< /text >}}

## Get started with Telemetry API

1. Enable access logging

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n istio-system -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: mesh-logging-default
    spec:
      accessLogging:
      - providers:
        - name: otel
    EOF
    {{< /text >}}

    The above example uses the built-in `envoy` access log provider, and we do not configure anything other than default settings.

1. Disable access log for specific workload

    You can disable access log for `sleep` service with the following configuration:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: disable-sleep-logging
      namespace: default
    spec:
      selector:
        matchLabels:
          app: sleep
      accessLogging:
      - providers:
        - name: otel
        disabled: true
    EOF
    {{< /text >}}

1. Filter access log with workload mode

    You can disable inbound access log for `httpbin` service with the following configuration:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: disable-httpbin-logging
    spec:
      selector:
        matchLabels:
          app: httpbin
      accessLogging:
      - providers:
        - name: otel
        match:
          mode: SERVER
        disabled: true
    EOF
    {{< /text >}}

1. Filter access log with CEL expression

    The following configuration displays access log only when response code is greater or equal to 500:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: filter-sleep-logging
    spec:
      selector:
        matchLabels:
          app: sleep
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: response.code >= 500
    EOF
    {{< /text >}}

1. Set default filter access log with CEL expression

    The following configuration displays access logs only when the response code is greater or equal to 400 or the request went to the BlackHoleCluster or the PassthroughCluster:
    Note: The `xds.cluster_name` is only available with Istio release 1.16.2 and higher

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: default-exception-logging
      namespace: istio-system
    spec:
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: "response.code >= 400 || xds.cluster_name == 'BlackHoleCluster' ||  xds.cluster_name == 'PassthroughCluster' "

    EOF
    {{< /text >}}

    For more information, see [Use expressions for values](/docs/tasks/observability/metrics/customize-metrics/#use-expressions-for-values)

## Work with OpenTelemetry provider

Istio supports sending access logs with [OpenTelemetry](https://opentelemetry.io/) protocol, as explained [here](/docs/tasks/observability/logs/otel-provider).

## Cleanup

1.  Remove all Telemetry API:

    {{< text bash >}}
    $ kubectl delete telemetry --all -A
    {{< /text >}}

1.  Remove `loki`:

    {{< text bash >}}
    $ kubectl delete -f @samples/addons/loki.yaml@ -n istio-system
    $ kubectl delete -f @samples/open-telemetry/loki/otel.yaml@ -n istio-system
    {{< /text >}}

1.  Uninstall Istio from the cluster:

    {{< text bash >}}
    $ istioctl uninstall --purge --skip-confirmation
    {{< /text >}}

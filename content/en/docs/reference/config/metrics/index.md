---
title: Istio Standard Metrics
description: Istio standard metrics exported by Istio telemetry.
weight: 50
keywords: [telemetry,metrics]
owner: istio/wg-user-experience-maintainers
test: n/a
aliases:
    - /docs/reference/config/telemetry/metrics/
---

The following are the standard service level metrics exported by Istio.

The telemetry component is implemented as a [Proxy extension](https://github.com/istio/proxy/tree/master/source/extensions/filters/http/istio_stats).
A `COUNTER` is a strictly increasing integer.
A `DISTRIBUTION` maps ranges of values to frequency.
`COUNTER` and `DISTRIBUTION` correspond to the metrics counter and histogram
in [the Envoy document](https://github.com/envoyproxy/envoy/blob/main/source/docs/stats.md).

## Metrics

For HTTP, HTTP/2, and GRPC traffic, Istio generates the following metrics:

*   **Request Count** (`istio_requests_total`): This is a `COUNTER` incremented for every request handled by an Istio proxy.

*   **Request Duration** (`istio_request_duration_milliseconds`): This is a `DISTRIBUTION` which measures the duration of requests.

*   **Request Size** (`istio_request_bytes`): This is a `DISTRIBUTION` which measures HTTP request body sizes.

*   **Response Size** (`istio_response_bytes`): This is a `DISTRIBUTION` which measures HTTP response body sizes.

*   **gRPC Request Message Count** (`istio_request_messages_total`): This is a `COUNTER` incremented for every gRPC message sent from a client.

*   **gRPC Response Message Count** (`istio_response_messages_total`): This is a `COUNTER` incremented for every gRPC message sent from a server.

For TCP traffic, Istio generates the following metrics:

*   **Tcp Bytes Sent** (`istio_tcp_sent_bytes_total`): This is a `COUNTER` which measures the size of total bytes sent during response in case of a TCP
    connection.

*   **Tcp Bytes Received** (`istio_tcp_received_bytes_total`): This is a `COUNTER` which measures the size of total
    bytes received during request in case of a TCP connection.

*   **Tcp Connections Opened** (`istio_tcp_connections_opened_total`): This is a `COUNTER` incremented for every opened connection.

*   **Tcp Connections Closed** (`istio_tcp_connections_closed_total`): This is a `COUNTER` incremented for every closed connection.

The metrics Istio emits can be overridden with [the `Telemetry` resource's `metricsOverrides` field](/docs/reference/config/telemetry/#MetricsOverrides); see [Telemetry API](/docs/tasks/observability/telemetry/).

## Labels

Labels are added to metrics to identify unique series or provide auxiliary
information.

The label name exposed in Prometheus scrapes and used when referring to the
label in configuration is shown in parentheses below.

*   **Reporter** (`reporter`): This identifies the reporter of the request. It is set to `destination`
    if report is from a server Istio proxy and `source` if report is from a client
    Istio proxy or a gateway.

*   **Source Workload** (`source_workload`): This identifies the name of source workload which
    controls the source, or `unknown` if the source information is missing.

    See also workload label
    [`service.istio.io/workload-name`](/docs/reference/config/labels/index.html)
    and proxy env-var `ISTIO_META_WORKLOAD_NAME`.

*   **Source Workload Namespace** (`source_workload_namespace`): This identifies the namespace of the source
    workload, or `unknown` if the source information is missing.

*   **Source Principal** (`source_princpial`): This identifies the peer principal of the traffic source.
    It is set when peer authentication is used.

*   **Source App** (`source_app`): This identifies the source application based on `app` label
    of the source workload, or `unknown` if the source information is missing.

*   **Source Version** (`source_version`): This identifies the version of the source workload, or
    `unknown` if the source information is missing.

*   **Destination Workload** (`destination_workload`): This identifies the name of destination workload,
    or `unknown` if the destination information is missing.

    See also workload label
    [`service.istio.io/workload-name`](/docs/reference/config/labels/index.html)
    and proxy env-var `ISTIO_META_WORKLOAD_NAME`.

*   **Destination Workload Namespace** (`DESTINATION_WORKLOAD_NAMESPACE`): This identifies the namespace of the
    destination workload, or `unknown` if the destination information is
    missing.

*   **Destination Principal** (`destination_principal`): This identifies the peer principal of the traffic destination.
    It is set when peer authentication is used.

*   **Destination App** (`destination_app`): This identifies the destination application based on
    `app` label of the destination workload, or `unknown` if the destination
    information is missing.

*   **Destination Version** (`destination_version`): This identifies the version of the destination workload,
    or `unknown` if the destination information is missing.

*   **Destination Service** (`destination_service`): This identifies destination service host responsible
    for an incoming request. Ex: `details.default.svc.cluster.local`.

*   **Destination Service Name** (`destination_service_name`): This identifies the destination service name.
    Ex: `details`.

*   **Destination Service Namespace** (`destination_service_namespace`): This identifies the namespace of
    destination service.

*   **Request Protocol** (`request_protocol`): This identifies the protocol of the request. It is set
    to request or connection protocol.

*   **Response Code** (`response_code`): This identifies the response code of the request. This
    label is present only on HTTP metrics.

*   **Connection Security Policy** (`connection_security_policy`): This identifies the service authentication policy of
    the request. It is set to `mutual_tls` when Istio is used to make communication
    secure and report is from destination. It is set to `unknown` when report is from
    source since security policy cannot be properly populated.

*   **Response Flags** (`response_flags`): Additional details about the response or connection from proxy.
    In case of Envoy, see `%RESPONSE_FLAGS%` in [Envoy Access Log](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags)
    for more detail.

*   **Canonical Service**: A workload belongs to exactly one canonical service, whereas it can belong to multiple services.
    A canonical service has a name and a revision so it results in the following labels.

    {{< text yaml >}}
    source_canonical_service
    source_canonical_revision
    destination_canonical_service
    destination_canonical_revision
    {{< /text >}}

    See also labels
    [`service.istio.io/canonical-name`](/docs/reference/config/labels/#ServiceCanonicalName)
    and
    [`service.istio.io/canonical-revision`](/docs/reference/config/labels/#ServiceCanonicalRevision).

*   **Destination Cluster** (`destination_cluster`): This identifies the cluster of the destination workload.
    This is set by: `global.multiCluster.clusterName` at cluster install time.

*   **Source Cluster** (`source_cluster`): This identifies the cluster of the source workload.
    This is set by: `global.multiCluster.clusterName` at cluster install time.

*   **gRPC Response Status** (`grpc_response_status`): This identifies the response status of the gRPC. This
    label is present only on gRPC metrics.

Metric dimensions can be suppressed with [the `Telemetry` resource's `metricsOverrides.tagOverride` field](/docs/reference/config/telemetry/#MetricsOverrides); see [Telemetry API](/docs/tasks/observability/telemetry/). Labels may also be added or modified using [metric classification](docs/tasks/observability/metrics/classify-metrics/) filters.

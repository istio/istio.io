---
title: Istio Standard Metrics
description: Istio standard metrics exported by Istio telemetry.
weight: 50
---

The following are the standard service level metrics exported by Istio.
Istio standard metrics are directly exported by the Envoy proxy since Istio 1.5.
The telemetry component is [implemented](https://github.com/istio/proxy/tree/master/extensions/stats) as a [Proxy-wasm](https://github.com/proxy-wasm/spec) plugin.

In prior Istio releases Mixer produced these metrics.

## Metrics

For HTTP, HTTP/2, and GRPC traffic, Istio generates the following metrics:

*   **Request Count** (`istio_requests_total`): This is a `COUNTER` incremented for every request handled by an Istio proxy.

*   **Request Duration** (`istio_request_duration_milliseconds`): This is a `DISTRIBUTION` which measures the duration of requests.

*   **Request Size** (`istio_request_bytes`): This is a `DISTRIBUTION` which measures HTTP request body sizes.

*   **Response Size** (`istio_response_bytes`): This is a `DISTRIBUTION` which measures HTTP response body sizes.

For TCP traffic, Istio generates the following metrics:

*   **Tcp Byte Sent** (`istio_tcp_sent_bytes_total`): This is a `COUNTER` which measures the size of total bytes sent during response in case of a TCP
    connection.

*   **Tcp Byte Received** (`istio_tcp_received_bytes_total`): This is a `COUNTER` which measures the size of total
    bytes received during request in case of a TCP connection.

*   **Tcp Connections Opened** (`istio_tcp_connections_opened_total`): This is a `COUNTER` incremented for every opened connection.

*   **Tcp Connections Closed** (`istio_tcp_connections_closed_total`): This is a `COUNTER` incremented for every closed connection.

## Labels

*   **Reporter**: This identifies the reporter of the request. It is set to `destination`
    if report is from a server Istio proxy and `source` if report is from a client
    Istio proxy or a gateway.

*   **Source Workload**: This identifies the name of source workload which
    controls the source, or "unknown" if the source information is missing.

*   **Source Workload Namespace**: This identifies the namespace of the source
    workload, or "unknown" if the source information is missing.

*   **Source Principal**: This identifies the peer principal of the traffic source.
    It is set when peer authentication is used.

*   **Source App**: This identifies the source application based on `app` label
    of the source workload, or "unknown" if the source information is missing.

*   **Source Version**: This identifies the version of the source workload, or
    "unknown" if the source information is missing.

*   **Destination Workload**: This identifies the name of destination workload,
    or "unknown" if the destination information is missing.

*   **Destination Workload Namespace**: This identifies the namespace of the
    destination workload, or "unknown" if the destination information is
    missing.

*   **Destination Principal**: This identifies the peer principal of the traffic destination.
    It is set when peer authentication is used.

*   **Destination App**: This identifies the destination application based on
    `app` label of the destination workload, or "unknown" if the destination
    information is missing.

*   **Destination Version**: This identifies the version of the destination workload,
    or "unknown" if the destination information is missing.

*   **Destination Service**: This identifies destination service host responsible
    for an incoming request. Ex: `details.default.svc.cluster.local`.

*   **Destination Service Name**: This identifies the destination service name.
    Ex: "details".

*   **Destination Service Namespace**: This identifies the namespace of
    destination service.

*   **Request Protocol**: This identifies the protocol of the request. It is set
    to request or connection protocol.

*   **Response Code**: This identifies the response code of the request. This
    label is present only on HTTP metrics.

*   **Connection Security Policy**: This identifies the service authentication policy of
    the request. It is set to `mutual_tls` when Istio is used to make communication
    secure and report is from destination. It is set to `unknown` when report is from
    source since security policy cannot be properly populated.

*   **Response Flags**: Additional details about the response or connection from proxy.
    In case of Envoy, see `%RESPONSE_FLAGS%` in [Envoy Access Log](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#configuration)
    for more detail.

*   **Canonical Service**: A workload belongs to exactly one canonical service, whereas it can belong to multiple services.
    A canonical service has a name and a revision so it results in the following labels.

    {{< text yaml >}}
    source_canonical_service
    source_canonical_revision
    destination_canonical_service
    destination_canonical_revision
    {{< /text >}}

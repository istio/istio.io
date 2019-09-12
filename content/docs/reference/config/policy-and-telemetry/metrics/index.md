---
title: Default Metrics
description: Default Metrics exported from Istio through Mixer.
weight: 50
---

This page presents details about the metrics that Istio collects when using its initial configuration. You can add and remove metrics by changing configuration at any time, but this
is the built-in set. They can be found [here]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)
under the section with "kind: metric”. It uses [metric
template](/docs/reference/config/policy-and-telemetry/templates/metric/) to define these metrics.

We will describe metrics first and then the labels for each metric.

## Metrics

For HTTP, HTTP/2, and GRPC traffic, Istio generates the following metrics:

*   **Request Count** (`istio_requests_total`): This is a `COUNTER` incremented for every request handled by an Istio proxy.

*   **Request Duration** (`istio_request_duration_seconds`): This is a `DISTRIBUTION` which measures the duration of requests.

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
    Istio proxy.

    {{< text yaml >}}
    reporter: conditional((context.reporter.kind | "inbound") == "outbound", "source", "destination")
    {{< /text >}}

*   **Source Workload**: This identifies the name of source workload which
    controls the source.

    {{< text yaml >}}
    source_workload: source.workload.name | "unknown"
    {{< /text >}}

*   **Source Workload Namespace**: This identifies the namespace of the source
    workload.

    {{< text yaml >}}
    source_workload_namespace: source.workload.namespace | "unknown"
    {{< /text >}}

*   **Source Principal**: This identifies the peer principal of the traffic source.
    It is set when peer authentication is used.

    {{< text yaml >}}
    source_principal: source.principal | "unknown"
    {{< /text >}}

*   **Source App**: This identifies the source app based on `app` label of the
    source workload.

    {{< text yaml >}}
    source_app: source.labels["app"] | "unknown"
    {{< /text >}}

*   **Source Version**: This identifies the version of the source workload.

    {{< text yaml >}}
    source_version: source.labels["version"] | "unknown"
    {{< /text >}}

*   **Destination Workload**: This identifies the name of destination workload.

    {{< text yaml >}}
    destination_workload: destination.workload.name | "unknown"
    {{< /text >}}

*   **Destination Workload Namespace**: This identifies the namespace of the destination
    workload.

    {{< text yaml >}}
    destination_workload_namespace: destination.workload.namespace | "unknown"
    {{< /text >}}

*   **Destination Principal**: This identifies the peer principal of the traffic destination.
    It is set when peer authentication is used.

    {{< text yaml >}}
    destination_principal: destination.principal | "unknown"
    {{< /text >}}

*   **Destination App**: This identifies the destination app based on `app` label of the
    destination workload.

    {{< text yaml >}}
    destination_app: destination.labels["app"] | "unknown"
    {{< /text >}}

*   **Destination Version**: This identifies the version of the destination workload.

    {{< text yaml >}}
    destination_version: destination.labels["version"] | "unknown"
    {{< /text >}}

*   **Destination Service**: This identifies destination service host responsible
    for an incoming request. Ex: `details.default.svc.cluster.local`.

    {{< text yaml >}}
    destination_service: destination.service.host | "unknown"
    {{< /text >}}

*   **Destination Service Name**: This identifies the destination service name.
    Ex: "details".

    {{< text yaml >}}
    destination_service_name: destination.service.name | "unknown"
    {{< /text >}}

*   **Destination Service Namespace**: This identifies the namespace of
    destination service.

    {{< text yaml >}}
    destination_service_namespace: destination.service.namespace | "unknown"
    {{< /text >}}

*   **Request Protocol**: This identifies the protocol of the request. It is set
    to API protocol if provided, otherwise request or connection protocol.

    {{< text yaml >}}
    request_protocol: api.protocol | context.protocol | "unknown"
    {{< /text >}}

*   **Response Code**: This identifies the response code of the request. This
    label is present only on HTTP metrics.

    {{< text yaml >}}
    response_code: response.code | 200
    {{< /text >}}

*   **Connection Security Policy**: This identifies the service authentication policy of
    the request. It is set to `mutual_tls` when Istio is used to make communication
    secure and report is from destination. It is set to `unknown` when report is from
    source since security policy cannot be properly populated.

    {{< text yaml >}}
    connection_security_policy: conditional((context.reporter.kind | "inbound") == "outbound", "unknown", conditional(connection.mtls | false, "mutual_tls", "none"))
    {{< /text >}}

*   **Response Flags**: Additional details about the response or connection from proxy.
    In case of Envoy, see `%RESPONSE_FLAGS%` in [Envoy Access Log](https://www.envoyproxy.io/docs/envoy/latest/configuration/access_log#configuration)
    for more detail.

    {{< text yaml >}}
    response_flags: context.proxy_error_code | "-"
    {{< /text >}}

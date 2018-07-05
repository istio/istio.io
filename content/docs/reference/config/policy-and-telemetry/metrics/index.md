---
title: Default Metrics
description: Default Metrics exported from Istio through Mixer.
weight: 50
---

This page presents details about the metrics that Istio collects when using its initial configuration. You can add and remove metrics by changing configuration at any time, but this
is the built-in set. They can be found [here]({{< github_file >}}/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)
under the section with “kind: metric”. It uses [metric
template](/docs/reference/config/policy-and-telemetry/templates/metric/) to define these metrics.

We will describe metrics first and then the labels for each metric.

## Metrics

*   **Request Count**: This is a `COUNTER`
    `[metric]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L786:9)`
    incremented for every request handled by an Istio proxy.

*   **Request Duration**: This is a `DISTRIBUTION`
    `[metric]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L802:9)`
    which measures the duration of the request (as observed by the server-side
    proxy).

*   **Request Size**: This is a `DISTRIBUTION`
    `[metric]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L818:9)`
    which measures the size of the HTTP request’s body size.

*   **Response Size**: This is a `DISTRIBUTION`
    `[metric]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L834:9)`
    which measures the size of the HTTP response body size.

*   **Tcp Byte Sent**: This is a `COUNTER`
    `[metric]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L850:9)`
    which measures the size of total bytes sent during response in case of a TCP
    connection as measured by the server-side proxy.

*   **Tcp Byte Received**: This is a `COUNTER`
    `[metric]({{< github_file >}}/install/kubernetes/templates/istio-mixer.yaml.tmpl#L867:9)`
    which measures the size of total bytes received during request in case of a
    TCP connection as measured by the server-side proxy.

## Labels

*   **Source Service**: This identifies the source service responsible for an
    incoming request. This is also the FQDN for a source service. Ex:
    "reviews.default.svc.cluster.local".

    {{< text yaml >}}
    source_service: source.service | "unknown"
    {{< /text >}}

*   **Source Version**: This identifies the version of the source service of the
    request.

    {{< text yaml >}}
    source_version: source.labels["version"] | "unknown"
    {{< /text >}}

*   **Destination Service**: This identifies the destination service responsible
    for an incoming request. This is also the FQDN for a source service. Ex:
    "details.default.svc.cluster.local".

    {{< text yaml >}}
    destination_service: destination.service | "unknown"
    {{< /text >}}

*   **Destination Version**: This identifies the version of the source service
    of the request.

    {{< text yaml >}}
    destination_version: destination.labels["version"] | "unknown"
    {{< /text >}}

*   **Response Code**: This identifies the response code of the request. This
    label is present only on HTTP metrics.

    {{< text yaml >}}
    response_code: response.code | 200
    {{< /text >}}

*   **Connection mTLS**: This identifies the service authentication policy of
    the request. It is set to `true`, when Istio is used to make
    communication secure.

    {{< text yaml >}}
    connection_mtls: connection.mtls | false
    {{< /text >}}

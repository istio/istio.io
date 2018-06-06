---
title: Metrics
description: Default Metrics exported from Istio through Mixer.
weight: 50
---

Istio exports metrics through Mixer. They can be found
[here](https://github.com/istio/istio/blob/master/install/kubernetes/helm/istio/charts/mixer/templates/config.yaml)
under the section with “kind: metric”. It uses [metric
template](/docs/reference/config/policy-and-telemetry/templates/metric/) to define these metrics.

We will describe metrics first and then the labels for each metric.

## Metrics

*   **Request Count**: This is a `COUNTER`
    [metric](https://github.com/istio/istio/blob/b6fa713dc8356cb49bbc1bda37f2fd9b5bce1e31/install/kubernetes/templates/istio-mixer.yaml.tmpl#L786:9)
    incremented for every request handled by an Istio proxy.

*   **Request Duration**: This is a `DISTRIBUTION`
    [metric](https://github.com/istio/istio/blob/b6fa713dc8356cb49bbc1bda37f2fd9b5bce1e31/install/kubernetes/templates/istio-mixer.yaml.tmpl#L802:9)
    which measures the duration of the request (as observed by the server-side
    proxy). This metric is obtained from envoy proxy.

*   **Request Size**: This is a `DISTRIBUTION`
    [metric](https://github.com/istio/istio/blob/b6fa713dc8356cb49bbc1bda37f2fd9b5bce1e31/install/kubernetes/templates/istio-mixer.yaml.tmpl#L818:9)
    which measures the size of the HTTP request’s body size. This metric is
    obtained from envoy proxy.

*   **Response Size**: This is a `DISTRIBUTION`
    [metric](https://github.com/istio/istio/blob/b6fa713dc8356cb49bbc1bda37f2fd9b5bce1e31/install/kubernetes/templates/istio-mixer.yaml.tmpl#L834:9)
    which measures the size of the HTTP response body size. This metric is
    obtained from envoy proxy.

*   **Tcp Byte Sent**: This is a `COUNTER`
    [metric](https://github.com/istio/istio/blob/b6fa713dc8356cb49bbc1bda37f2fd9b5bce1e31/install/kubernetes/templates/istio-mixer.yaml.tmpl#L850:9)
    which measures the size of total bytes sent during response in case of a TCP
    connection as measured by the server-side proxy. This metric is obtained
    from envoy proxy.

*   **Tcp Byte Received**: This is a `COUNTER`
    [metric](https://github.com/istio/istio/blob/b6fa713dc8356cb49bbc1bda37f2fd9b5bce1e31/install/kubernetes/templates/istio-mixer.yaml.tmpl#L867:9)
    which measures the size of total bytes received during request in case of a
    TCP connection as measured by the server-side proxy. This metric is obtained
    from envoy proxy.

## Labels

*   **Source Service**: This identifies the source service responsible for an
    incoming request. This is also the FQDN for a source service. Ex:
    "reviews.default.svc.cluster.local".

    ```yaml
       #Default Attribute Expression
       source_service: source.service | "unknown"
    ```

*   **Source Version**: This identifies the version of the source service of the
    request.

    ```yaml
       #Default Attribute Expression
       source_version: source.labels["version"] | "unknown"
    ```

*   **Destination Service**: This identifies the destination service responsible
    for an incoming request. This is also the FQDN for a source service. Ex:
    "details.default.svc.cluster.local".

    ```yaml
       #Default Attribute Expression
       destination_service: destination.service | "unknown"
    ```

*   **Destination Version**: This identifies the version of the source service
    of the request.

    ```yaml
       #Default Attribute Expression
       destination_version: destination.labels["version"] | "unknown"
    ```

*   **Response Code**: This identifies the response code of the request. This
    label is present only on HTTP metrics.

    ```yaml
       #Default Attribute Expression
       response_code: response.code | 200
    ```

*   **Connection mTLS**: This identifies the service authentication policy of
    the request. It is set to true, when istio is used to make secure
    communications.

    ```yaml
       #Default Attribute Expression
       connection_mtls: connection.mtls | false
    ```

## Example

Request Count metric instance would look as follows:

```yaml
istio_request_count
{
  connection_mtls="false",
  destination_service="istio-pilot.istio-system.svc.cluster.local",
  destination_version="unknown",
  instance="10.40.0.6:42422",
  job="istio-mesh",
  response_code="200",
  source_service="details.default.svc.cluster.local",
  source_version="v1"
}
Value: 2
```

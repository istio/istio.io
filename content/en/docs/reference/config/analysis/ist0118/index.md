---
title: PortNameIsNotUnderNamingConvention
layout: analysis-message
---

This message occurs when the port doesn't follow the [Istio service port naming convention](/docs/ops/deployment/requirements/)
or the port is unnamed.

## Example

You will receive this message:

{{< text plain >}}
Info [IST0118] (Service httpbin.default) Port name foo-http (port: 80, targetPort: 80) doesn't follow the naming convention of Istio port.
{{< /text >}}

when your cluster has following service:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: foo-http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
{{< /text >}}

In this example, the port `foo-http` does follow the syntax: `name: <protocol>[-<suffix>]`.

## How to resolve

- If you know the protocol the service port is serving, renaming the port with `<protocol>[-<suffix>]` format;
- If you don't know the protocol the service port is serving, you need to [query metrics from Prometheus](/docs/tasks/observability/metrics/querying-metrics/)
    - Running query `istio_requests_total{reporter="destination",destination_service_name="SERVICE_NAME",response_code="200"}[TIME_RANGE]`. If you are using Mixer v2,
      you can also run query `istio_requests_total{reporter="destination",destination_service_name="SERVICE_NAME",response_code="200",destination_port="TARGET_PORT"}[TIME_RANGE]`.
    - If there are outputs, you can find the `request_protocol` from the record. E.g., if the `request_protocol` is "http", renaming port to "http-foo";
    - If there is no output, you can leave the port as it is.

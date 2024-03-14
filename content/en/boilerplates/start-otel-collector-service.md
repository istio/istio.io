---
---
*   Create a namespace for the OpenTelemetry Collector:

    {{< text bash >}}
    $ kubectl create namespace observability
    {{< /text >}}

*   Deploy the OpenTelemetry Collector. You can use this example configuration as a starting point:
    [`otel.yaml`]({{< github_blob >}}/samples/open-telemetry/otel.yaml)

    {{< text bash >}}
    $ kubectl apply -f @samples/open-telemetry/otel.yaml@ -n observability
    {{< /text >}}

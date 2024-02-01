---
---
*   Create a namespace for the OpenTelemetry Collector:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl create namespace otel-collector
    {{< /text >}}

*   Deploy the OpenTelemetry Collector. You can use this example configuration as a starting point:
    [`otel.yaml`]({{< github_blob >}}/samples/open-telemetry/otel.yaml)

    {{< text bash >}}
    $ kubectl apply -f @samples/open-telemetry/otel.yaml@ -n otel-collector
    {{< /text >}}

---
---
Create a namespace for the OpenTelemetry Collector:

{{< text bash >}}
$ kubectl create namespace observability
{{< /text >}}

Deploy the OpenTelemetry Collector. You can use [this example configuration]({{< github_blob >}}/samples/open-telemetry/otel.yaml) as a starting point.

{{< text bash >}}
$ kubectl apply -f @samples/open-telemetry/otel.yaml@ -n observability
{{< /text >}}

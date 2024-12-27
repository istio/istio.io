---
---
Створіть простір імен для OpenTelemetry Collector:

{{< text bash >}}
$ kubectl create namespace observability
{{< /text >}}

Розгорніть OpenTelemetry Collector. Ви можете використовувати цей [приклад конфігурації]({{< github_blob >}}/samples/open-telemetry/otel.yaml) як відправну точку.

{{< text bash >}}
$ kubectl apply -f @samples/open-telemetry/otel.yaml@ -n observability
{{< /text >}}

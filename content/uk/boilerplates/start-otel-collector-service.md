---
---
*   Створіть простір імен для OpenTelemetry Collector:

    {{< text bash >}}
    $ kubectl create namespace observability
    {{< /text >}}

*   Розгорніть OpenTelemetry Collector. Ви можете використовувати цей приклад конфігурації як відправну точку:
    [`otel.yaml`]({{< github_blob >}}/samples/open-telemetry/otel.yaml)

    {{< text bash >}}
    $ kubectl apply -f @samples/open-telemetry/otel.yaml@ -n observability
    {{< /text >}}

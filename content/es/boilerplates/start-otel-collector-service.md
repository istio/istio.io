---
---
Crea un namespace para el Recopilador de OpenTelemetry:

{{< text bash >}}
$ kubectl create namespace observability
{{< /text >}}

Despliega el Recopilador de OpenTelemetry. Puedes usar [esta configuración de ejemplo]({{< github_blob >}}/samples/open-telemetry/otel.yaml) como punto de partida.

{{< text bash >}}
$ kubectl apply -f @samples/open-telemetry/otel.yaml@ -n observability
{{< /text >}}

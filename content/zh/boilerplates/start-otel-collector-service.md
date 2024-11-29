---
---
为 OpenTelemetry Collector 创建命名空间：

{{< text bash >}}
$ kubectl apply -f @samples/open-telemetry/otel.yaml@ -n istio-system
$ kubectl create namespace observability
{{< /text >}}

部署 OpenTelemetry Collector。
您可以使用[此示例配置]({{< github_blob >}}/samples/open-telemetry/otel.yaml)作为起点。

{{< text bash >}}
$ kubectl apply -f @samples/open-telemetry/otel.yaml@ -n observability
{{< /text >}}

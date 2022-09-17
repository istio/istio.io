---
---
要查看追踪数据，必须向服务发送请求。请求的数量取决于 Istio 的采样率，可以使用 [Telemetry API](/zh/docs/tasks/observability/telemetry/) 进行配置。默认采样速率为 1%，在第一个跟踪可见之前，您需要发送至少 100 个请求。
使用以下命令向 `productpage` 服务发送 100 个请求：

{{< text bash >}}
$ for i in `seq 1 100`; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done
{{< /text >}}

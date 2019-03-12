要查看追踪数据，您必须向您的服务发送请求。请求的数量取决于 Istio 的采样率。
您在安装 Istio 时设置过这个采样速率参数，默认采样率为 1%。
在第一个追踪可见之前，您需要发送至少 100 个请求。
要向 `productpage` 服务发送 100 个请求，请使用以下命令：

{{< text bash >}}
$ for i in `seq 1 100`; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done
{{< /text >}}
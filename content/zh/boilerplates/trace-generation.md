---
---
要查看跟踪数据，必须将请求发送到服务。请求数量取决于Istio的采样率。
这个采用率在安装 Istio 时进行设置。 默认值为1％，即需要发送100个请求，才能显示第一条跟踪数据。
以下命令示例了如何将100个请求发送到`productpage`服务：
{{< text bash >}}
$ for i in `seq 1 100`; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done
{{< /text >}}
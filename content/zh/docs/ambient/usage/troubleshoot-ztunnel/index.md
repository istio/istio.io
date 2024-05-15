---
title: ztunnel 的连接问题排查
description: 如何验证节点代理是否具有正确的配置。
weight: 60
owner: istio/wg-networking-maintainers
test: no
---

本指南介绍了用于监控 ztunnel 代理配置和数据路径的一些选项。
此信息还可以帮助进行一些高级故障排查，以及识别在出现任何问题时可在错误报告中收集和提供的有用信息。

## 查看 ztunnel 代理状态 {#viewing-ztunnel-proxy-state}

ztunnel 代理通过 xDS API 从 istiod {{< gloss "control plane" >}}控制平面{{< /gloss >}}获取配置和发现信息。

`istioctl x ztunnel-config` 命令允许您查看 ztunnel 代理所看到的和发现的工作负载。

在第一个示例中，您会看到 ztunnel 当前正在跟踪的所有工作负载和控制平面组件，
包括有关连接到该组件时要使用的 IP 地址和协议的信息，以及是否存在与该工作负载关联的 waypoint 代理。

{{< text bash >}}
$ istioctl x ztunnel-config workloads
NAMESPACE          POD NAME                                IP          NODE                  WAYPOINT PROTOCOL
default            bookinfo-gateway-istio-59dd7c96db-q9k6v 10.244.1.11 ambient-worker        None     TCP
default            details-v1-cf74bb974-5sqkp              10.244.1.5  ambient-worker        None     HBONE
default            notsleep-5c785bc478-zpg7j               10.244.2.7  ambient-worker2       None     HBONE
default            productpage-v1-87d54dd59-fn6vw          10.244.1.10 ambient-worker        None     HBONE
default            ratings-v1-7c4bbf97db-zvkdw             10.244.1.6  ambient-worker        None     HBONE
default            reviews-v1-5fd6d4f8f8-knbht             10.244.1.16 ambient-worker        None     HBONE
default            reviews-v2-6f9b55c5db-c94m2             10.244.1.17 ambient-worker        None     HBONE
default            reviews-v3-7d99fd7978-7rgtd             10.244.1.18 ambient-worker        None     HBONE
default            sleep-7656cf8794-r7zb9                  10.244.1.12 ambient-worker        None     HBONE
istio-system       istiod-7ff4959459-qcpvp                 10.244.2.5  ambient-worker2       None     TCP
istio-system       ztunnel-6hvcw                           10.244.1.4  ambient-worker        None     TCP
istio-system       ztunnel-mf476                           10.244.2.6  ambient-worker2       None     TCP
istio-system       ztunnel-vqzf9                           10.244.0.6  ambient-control-plane None     TCP
kube-system        coredns-76f75df574-2sms2                10.244.0.3  ambient-control-plane None     TCP
kube-system        coredns-76f75df574-5bf9c                10.244.0.2  ambient-control-plane None     TCP
local-path-storage local-path-provisioner-7577fdbbfb-pslg6 10.244.0.4  ambient-control-plane None     TCP

{{< /text >}}

`ztunnel-config` 命令可用于查看持有 TLS 证书的 Secret，
ztunnel 代理已从 istiod 控制平面接收到用于 mTLS 的证书。

{{< text bash >}}
$ istioctl x ztunnel-config certificates "$ZTUNNEL".istio-system
CERTIFICATE NAME                                              TYPE     STATUS        VALID CERT     SERIAL NUMBER                        NOT AFTER                NOT BEFORE
spiffe://cluster.local/ns/default/sa/bookinfo-details         Leaf     Available     true           c198d859ee51556d0eae13b331b0c259     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-details         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-productpage     Leaf     Available     true           64c3828993c7df6f85a601a1615532cc     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-productpage     Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-ratings         Leaf     Available     true           720479815bf6d81a05df8a64f384ebb0     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-ratings         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/bookinfo-reviews         Leaf     Available     true           285697fb2cf806852d3293298e300c86     2024-05-05T09:17:47Z     2024-05-04T09:15:47Z
spiffe://cluster.local/ns/default/sa/bookinfo-reviews         Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
spiffe://cluster.local/ns/default/sa/sleep                    Leaf     Available     true           fa33bbb783553a1704866842586e4c0b     2024-05-05T09:25:49Z     2024-05-04T09:23:49Z
spiffe://cluster.local/ns/default/sa/sleep                    Root     Available     true           bad086c516cce777645363cb8d731277     2034-04-24T03:31:05Z     2024-04-26T03:31:05Z
{{< /text >}}

使用这些命令，您可以检查 ztunnel 代理是否配置了所有预期的工作负载和 TLS 证书。
此外，缺失的信息可用于排除任何网络错误。

您可以使用 `all` 选项通过单个 CLI 命令查看 ztunnel-config 的所有部分：

{{< text bash >}}
$ istioctl x ztunnel-config all -o json
{{< /text >}}

您还可以通过 `curl` 查看 ztunnel 代理的原始配置转储到其 Pod 内的端点：

{{< text bash >}}
$ kubectl debug -it $ZTUNNEL -n istio-system --image=curlimages/curl -- curl localhost:15000/config_dump
{{< /text >}}

## 查看 ztunnel xDS 资源的 Istiod 状态 {#viewing-istiod-state-for-ztunnel-xds-resources}

有时您可能希望以专门为 ztunnel 代理定义的 xDS API 资源的格式查看
istiod 控制平面中维护的 ztunnel 代理配置资源的状态。这可以通过执行 istiod Pod 并从给定
ztunnel 代理的端口 15014 获取此信息来完成，如下例所示。
然后，还可以使用漂亮的 JSON 打印格式化实用程序保存和查看此输出，以便于浏览（示例中未展示）。

{{< text bash >}}
$ export ISTIOD=$(kubectl get pods -n istio-system -l app=istiod -o=jsonpath='{.items[0].metadata.name}')
$ kubectl debug -it $ISTIOD -n istio-system --image=curlimages/curl -- curl localhost:15014/debug/config_dump?proxyID="$ZTUNNEL".istio-system
{{< /text >}}

## 通过日志验证 ztunnel 流量 {#verifying-ztunnel-traffic-through-logs}

可以使用标准 Kubernetes 日志工具来查询 ztunnel 的流量日志。

{{< text bash >}}
$ kubectl -n default exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://productpage:9080/; done'
HTTP/1.1 200 OK
Server: Werkzeug/3.0.1 Python/3.12.1
--snip--
{{< /text >}}

响应显示了确认客户端 Pod 收到来自服务的响应。
您现在可以检查 ztunnel Pod 的日志，以确认流量是通过 HBONE 隧道发送的。

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
2024-05-04T09:59:05.028709Z info    access  connection complete src.addr=10.244.1.12:60059 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.10:9080 dst.hbone_addr="10.244.1.10:9080" dst.service="productpage.default.svc.cluster.local" dst.workload="productpage-v1-87d54dd59-fn6vw" dst.namespace="productpage" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-productpage" direction="inbound" bytes_sent=175 bytes_recv=80 duration="1ms"
2024-05-04T09:59:05.028771Z info    access  connection complete src.addr=10.244.1.12:58508 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.10:15008 dst.hbone_addr="10.244.1.10:9080" dst.service="productpage.default.svc.cluster.local" dst.workload="productpage-v1-87d54dd59-fn6vw" dst.namespace="productpage" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-productpage" direction="outbound" bytes_sent=80 bytes_recv=175 duration="1ms"
--snip--
{{< /text >}}

这些日志消息确认流量是通过 ztunnel 代理发送的。
可以通过检查与流量的源 Pod 和目标 Pod 位于同一节点上的特定 ztunnel
代理实例上的日志来完成额外的细粒度监控。如果没有看到这些日志，
则可能是[流量重定向](/zh/docs/ambient/architecture/traffic-redirection)无法正常工作。

{{< tip >}}
即使流量的源和目标位于同一计算节点上，流量也始终穿过 ztunnel Pod。
{{< /tip >}}

### 验证 ztunnel 负载均衡 {#verifying-ztunnel-load-balancing}

如果目标是具有多个端点的服务，ztunnel 代理会自动执行客户端负载均衡。
无需额外配置。负载均衡算法是内部固定的 L4 轮循算法，根据 L4 连接状态分配流量，用户不可配置。

{{< tip >}}
如果目标是具有多个实例或 Pod 的服务，并且没有与目标服务关联的 waypoint，
则源 ztunnel 直接跨这些实例或服务后端执行 L4 负载均衡，
然后通过与这些后端关联的远程 ztunnel 代理发送流量。如果目标服务配置为使用一个或多个 waypoint 代理，
则源 ztunnel 代理通过在这些 waypoint 代理之间分配流量来执行负载均衡，
并通过托管 waypoint 代理实例节点上的远程 ztunnel 代理发送流量。
{{< /tip >}}

通过调用具有多个后端的服务，我们可以验证客户端流量在服务副本之间是否平衡。

{{< text bash >}}
$ kubectl -n default exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://reviews:9080/; done'
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "outbound"
--snip--
2024-05-04T10:11:04.964851Z info    access  connection complete src.addr=10.244.1.12:35520 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.9:15008 dst.hbone_addr="10.244.1.9:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v3-7d99fd7978-zznnq" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.969578Z info    access  connection complete src.addr=10.244.1.12:35526 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.9:15008 dst.hbone_addr="10.244.1.9:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v3-7d99fd7978-zznnq" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.974720Z info    access  connection complete src.addr=10.244.1.12:35536 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.7:15008 dst.hbone_addr="10.244.1.7:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v1-5fd6d4f8f8-26j92" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
2024-05-04T10:11:04.979462Z info    access  connection complete src.addr=10.244.1.12:35552 src.workload="sleep-7656cf8794-r7zb9" src.namespace="default" src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.244.1.8:15008 dst.hbone_addr="10.244.1.8:9080" dst.service="reviews.default.svc.cluster.local" dst.workload="reviews-v2-6f9b55c5db-c2dtw" dst.namespace="reviews" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-reviews" direction="outbound" bytes_sent=84 bytes_recv=169 duration="2ms"
{{< /text >}}

这是一种轮询负载均衡算法，并且独立于可以在 `VirtualService` 的 `TrafficPolicy`
字段中配置的任何负载均衡算法，因为如前所述，`VirtualService` API 对象的所有方面都被实例化在
waypoint 代理上而不是 ztunnel 代理上。

### Ambient 模式流量的可观测性 {#observability-of-ambient-mode-traffic}

除了检查 ztunnel 日志和上面提到的其他监控选项之外，
您还可以使用普通的 Istio 监控和可观测功能来使用 Ambient 数据平面模式监控应用程序流量。

* [安装 Prometheus](/zh/docs/ops/integrations/prometheus/#installation)
* [安装 Kiali](/zh/docs/ops/integrations/kiali/#installation)
* [Istio 指标](/zh/docs/reference/config/metrics/)
* [从 Prometheus 查询指标](/zh/docs/tasks/observability/metrics/querying-metrics/)

如果服务仅使用 ztunnel 提供的安全覆盖，则报告的 Istio 指标将仅为 L4 TCP 指标
（即 `istio_tcp_sent_bytes_total`、`istio_tcp_received_bytes_total`、`istio_tcp_connections_opened_total`、`istio_tcp_connections_filled_total`）。
如果使用 waypoint 代理，则会报告全套 Istio 和 Envoy 指标。

---
title: 验证双向 TLS 已启用
description: 了解如何在 Ambient 网格中验证工作负载之间已启用 mTLS。 
weight: 15
owner: istio/wg-networking-maintainers
test: no
---

一旦您将应用添加到 Ambient 网格中，您就可以使用以下一种或多种方法轻松校验工作负载之间是否启用了 mTLS：

## 使用工作负载的 ztunnel 配置来校验 mTLS {#validate-mtls-using-workloads-ztunnel-configurations}

通过方便的 `istioctl ztunnel-config workloads` 命令，您可以查看工作负载是否被配置为通过
`PROTOCOL` 列的值发送和接收 HBONE 流量。例如：

{{< text syntax=bash >}}
$ istioctl ztunnel-config workloads
NAMESPACE    POD NAME                                IP         NODE                     WAYPOINT PROTOCOL
default      details-v1-857849f66-ft8wx              10.42.0.5  k3d-k3s-default-agent-0  None     HBONE
default      kubernetes                              172.20.0.3                          None     TCP
default      productpage-v1-c5b7f7dbc-hlhpd          10.42.0.8  k3d-k3s-default-agent-0  None     HBONE
default      ratings-v1-68d5f5486b-b5sbj             10.42.0.6  k3d-k3s-default-agent-0  None     HBONE
default      reviews-v1-7dc5fc4b46-ndrq9             10.42.1.5  k3d-k3s-default-agent-1  None     HBONE
default      reviews-v2-6cf45d556b-4k4md             10.42.0.7  k3d-k3s-default-agent-0  None     HBONE
default      reviews-v3-86cb7d97f8-zxzl4             10.42.1.6  k3d-k3s-default-agent-1  None     HBONE
{{< /text >}}

在您的工作负载上配置了 HBONE 并不意味着您的工作负载会拒绝任何明文流量。
如果您希望工作负载拒绝明文流量，请为您的工作负载创建一个将 mTLS 模式设置为 `STRICT` 的 `PeerAuthentication` 策略。

## 基于指标校验 mTLS {#validate-mtls-from-metrics}

如果您已[安装 Prometheus](/zh/docs/ops/integrations/prometheus/#installation)，
您可以设置端口转发并使用以下命令打开 Prometheus UI：

{{< text syntax=bash >}}
$ istioctl dashboard prometheus
{{< /text >}}

在 Prometheus 中，您可以查看 TCP 指标的值。首先，选择 Graph 并输入一个指标，例如
`istio_tcp_connections_opened_total`、`istio_tcp_connections_closed_total`、
`istio_tcp_received_bytes_total` 或 `istio_tcp_sent_bytes_total`。
最后，点击 Execute。数据将包含如下条目：

{{< text syntax=plain >}}
istio_tcp_connections_opened_total{
  app="ztunnel",
  connection_security_policy="mutual_tls",
  destination_principal="spiffe://cluster.local/ns/default/sa/bookinfo-details",
  destination_service="details.default.svc.cluster.local",
  reporter="source",
  request_protocol="tcp",
  response_flags="-",
  source_app="sleep",
  source_principal="spiffe://cluster.local/ns/default/sa/sleep",source_workload_namespace="default",
  ...}
{{< /text >}}

校验 `connection_security_policy` 值是否设置为 `mutual_tls`，以及期望的源和目标身份信息。

## 基于日志校验 mTLS {#validate-mtls-from-logs}

您还可以结合对等身份来查看源或目标 ztunnel 日志以确认 mTLS 是否已启用。
以下是从 `sleep` 服务到 `details` 服务请求的源 ztunnel 的日志示例：

{{< text syntax=plain >}}
2024-08-21T15:32:05.754291Z info access connection complete src.addr=10.42.0.9:33772 src.workload="sleep-7656cf8794-6lsm4" src.namespace="default"
src.identity="spiffe://cluster.local/ns/default/sa/sleep" dst.addr=10.42.0.5:15008 dst.hbone_addr=10.42.0.5:9080 dst.service="details.default.svc.cluster.local"
dst.workload="details-v1-857849f66-ft8wx" dst.namespace="default" dst.identity="spiffe://cluster.local/ns/default/sa/bookinfo-details"
direction="outbound" bytes_sent=84 bytes_recv=358 duration="15ms"
{{< /text >}}

校验 `src.identity` 和 `dst.identity` 值是否正确。
它们是用于源工作负载和目标工作负载之间 mTLS 通信的身份。
有关细节请参阅[通过日志验证 ztunnel 流量部分](/zh/docs/ambient/usage/troubleshoot-ztunnel/#verifying-ztunnel-traffic-through-logs)。

## 使用 Kiali 仪表板校验 {#validate-with-kiali-dashboard}

如果您已安装 Kiali 和 Prometheus，您可以使用 Kiali 的仪表板可视化您的工作负载通信。
您可以结合对等身份信息来查看任意工作负载之间的连接是否具有锁定图标，以验证 mTLS 是否已启用：

{{< image link="./kiali-mtls.png" caption="Kiali 仪表板" >}}

有关细节请参阅[可视化应用和指标](/zh/docs/ambient/getting-started/secure-and-visualize/#visualize-the-application-and-metrics)文档。

## 使用 `tcpdump` 验证 {#validate-with-tcpdump}

如果您可以访问 Kubernetes 工作节点，您可以运行 `tcpdump` 命令以捕获网络接口上的所有流量，
可以选择聚焦于应用端口和 HBONE 端口。在此示例中，端口 `9080` 是 `details` 服务端口，`15008` 是 HBONE 端口：

{{< text syntax=bash >}}
$ tcpdump -nAi eth0 port 9080 or port 15008
{{< /text >}}

您应该在 `tcpdump` 命令的输出中看到加密的流量。

如果您无法访问工作节点，您可以使用
[netshoot 容器镜像](https://hub.docker.com/r/nicolaka/netshoot)来轻松运行以下命令：

{{< text syntax=bash >}}
$ POD=$(kubectl get pods -l app=details -o jsonpath="{.items[0].metadata.name}")
$ kubectl debug $POD -i --image=nicolaka/netshoot -- tcpdump -nAi eth0 port 9080 or port 15008
{{< /text >}}

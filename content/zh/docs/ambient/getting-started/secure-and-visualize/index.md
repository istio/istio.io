---
title: 保护和可视化应用程序
description: 启用 Ambient 模式并保护应用程序之间的通信。
weight: 3
owner: istio/wg-networking-maintainers
test: yes
---

将应用程序添加到 Ambient 网格就像标记应用程序所在的命名空间一样简单。
通过将应用程序添加到网格，您可以自动保护它们之间的通信，
并且 Istio 开始收集 TCP 可观测数据。而且，您无需重新启动或重新部署应用程序！

## 将 Bookinfo 添加到网格 {#add-bookinfo-to-the-mesh}

您可以通过简单地标记命名空间来使给定命名空间中的所有 Pod 成为 Ambient 网格的一部分：

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
namespace/default labeled
{{< /text >}}

恭喜！您已成功将默认命名空间中的所有 Pod 添加到 Ambient 网格。🎉

如果您在浏览器中打开 Bookinfo 应用程序，就像之前一样，您将看到产品页面。
这次的不同之处在于 Bookinfo 应用程序 Pod 之间的通信使用 mTLS 加密。
此外，Istio 正在收集 Pod 之间所有流量的 TCP 可观测数据。

{{< tip >}}
现在，所有 Pod 之间都有 mTLS 加密 - 并且无需重新启动或重新部署任何应用程序！
{{< /tip >}}

## 可视化应用程序和指标 {#visualize-the-application-and-metrics}

使用 Istio 的仪表板、Kiali 和 Prometheus 指标引擎，
您可以可视化 Bookinfo 应用程序。部署它们：

{{< text syntax=bash snip_id=none >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/prometheus.yaml
$ kubectl apply -f {{< github_file >}}/samples/addons/kiali.yaml
{{< /text >}}

您可以通过运行以下命令访问 Kiali 仪表板：

{{< text syntax=bash snip_id=none >}}
$ istioctl dashboard kiali
{{< /text >}}

让我们向 Bookinfo 应用程序发送一些流量，以便 Kiali 生成流量图：

{{< text bash >}}
$ for i in $(seq 1 100); do curl -s http://localhost:8080/productpage; done
{{< /text >}}

接下来，单击 Traffic Graph，您应该会看到 Bookinfo 应用程序：

{{< image link="./kiali-ambient-bookinfo.png" caption="Kiali 仪表盘" >}}

{{< tip >}}
如果您没有看到流量图，请尝试将流量重新发送到 Bookinfo 应用程序，
并确保在 Kiali 中的 **Namespace** 下拉菜单中选择了 **default** 命名空间。

要查看服务之间的 mTLS 状态，请单击 **Display** 下拉菜单，然后单击 **Security**。
{{</ tip >}}

如果您单击仪表板上连接两个服务的线，您可以看到 Istio 收集的入站和出站流量指标。

{{< image link="./kiali-tcp-traffic.png" caption="L4 流量" >}}

除了 TCP 指标之外，Istio 还为每个服务创建了一个强大的身份：SPIFFE ID。此身份可用于创建鉴权策略。

## 下一步 {#next-steps}

现在我们已为服务分配了身份，
接下来让我们[执行鉴权策略](/zh/docs/ambient/getting-started/enforce-auth-policies/)来确保应用程序访问的安全。

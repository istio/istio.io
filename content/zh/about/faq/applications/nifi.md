---
title: 我可以在 Istio 网格内运行 Apache NiFi 吗？
description: 如何在 Istio 上运行 Apache NiFi。
weight: 50
keywords: [nifi]
---

在 Istio 上运行 [Apache NiFi](https://nifi.apache.org) 是有一些挑战的。这些挑战来自集群运行的需求。
例如，要求群集组件必须在整个群集范围内都可以唯一寻址的主机名。该要求与 Istio 的要求（即工作负载在容器组中绑定并侦听“0.0.0.0”）相冲突。

根据您 NiFi 配置和部署情况，有不同的方法来绕开这些问题。 在 NiFi 中，至少有以下三种方法来指定群集网络应使用的主机名：

* [`nifi.remote.input.host`](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#site_to_site_properties)-
将提供给客户端以连接到该NiFi实例进行站点到站点通信的主机名。默认情况下使用 `InetAddress.getLocalHost().getHostName()` 来获取本机的主机名。
在类似 UNIX 的操作系统上，这通常是来自 `hostname` 命令。

* [`nifi.web.https.host`](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#web-properties)-HTTPS主机。
默认情况下为空白。jetty 服务器将在该主机名上运行，并且需要在整个群集中可寻址，以便与其他节点进行复制。

* [`nifi.cluster.node.address`](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#cluster_node_propertie)-
节点的标准地址。默认情况下为空白。这也用于集群协调，并且需要在集群内唯一地寻址。

一些注意事项：

* 由于对上述唯一寻址的联网要求, 对 `nifi.web.https.host` 使用空白或 `localhost` 的设置在这种情况下将不起作用。
* 除非您对所有在 NiFi 部署中具有所有访问角色的用户都表示满意，否则 HTTP 并不是可行的解决方案，因为 [NiFi 不会通过 HTTP 执行用户身份验证](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#user_authentication)。
* 明确指定 NiFi 应该使用的网络接口可以帮助解决问题并允许NiFi工作：
  修改 `nifi.properties`，其中 `xxx` 是与工作IP对应的网络接口（因环境/云提供商而异），`yyy` 是容器/容器组的环回接口（即 lo ）：

  {{< text plain >}}
    nifi.web.https.network.interface.default = xxx
    nifi.web.https.network.interface.lo = yyy
  {{< /text >}}

  真实示例（适用于 IBM Cloud，也许适用于其他示例）如下所示：

  {{< text plain >}}
    nifi.web.https.network.interface.default = eth0
    nifi.web.https.network.interface.lo = lo
  {{< /text >}}

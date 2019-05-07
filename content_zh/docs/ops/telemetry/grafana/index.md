---
title: Grafana
description: 处理 Grafana 相关问题。
weight: 90
---

如果您从本地 Web 客户端连接到远程托管的 Istio 时无法获得 Grafana 输出，那么您应验证客户端和服务器的日期和时间是否匹配。

Web 客户端（例如 Chrome）的时间会影响 Grafana 的输出。这个问题的一个简单的解决方案是验证时间同步服务是否 Kubernetes 集群内部正确运行并且 Web 客户端计算机也正确使用时间同步服务。一些常见的时间同步系统是 NTP 和 Chrony。特别是在有防火墙的工程实验室中会存在这种问题。在这些情况下，NTP 可能没有正确配置好去指向基于实验室的 NTP 服务。
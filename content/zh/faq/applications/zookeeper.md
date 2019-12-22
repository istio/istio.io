---
title: 我能在 Istio 内部运行 Zookeeper 吗?
description: 如何用 Istio 运行 Zookeeper。
weight: 50
keywords: [zookeeper]
---

默认情况下，Zookeeper 通过监听 pod 的 IP 地址用来在服务间通信。而 Istio 和其他的服务网格需要监听在 `localhost` （`127.0.0.1`）地址上。

有一个配置参数可以来修改这个默认行为：
[`quorumListenOnAllIPs`](https://zookeeper.apache.org/doc/r3.5.6/zookeeperAdmin.html)。
这个选项可以让 Zookeeper 监听所有的地址包括 `localhost`。
通过下面的命令可以把这个参数设置为 `true`，`$ZK_CONFIG_FILE` 是你 Zookeeper 配置文件的路径。

{{< text bash >}}
$ echo "quorumListenOnAllIPs=true" >> $ZK_CONFIG_FILE
{{< /text >}}


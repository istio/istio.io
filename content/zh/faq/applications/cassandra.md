---
title: 可以在 Istio mesh 中运行 Casandra 吗？
description: 如何在 Istio 上运行 Cassandra。
weight: 50
keywords: [cassandra]
---

默认情况下，Cassandra 广播用于绑定（接受连接）到其他 Cassandra 节点的地址作为其地址。这通常是 Pod IP 地址，无需服务网格即可正常工作。但是，对于服务网格，此配置不起作用。Istio 和其他服务网格需要 `localhost` （`127.0.0.1`）作为绑定地址。

有两个配置参数要注意：
[`listen_address`](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html?highlight=listen_address#listen-address) 和 [`broadcast_address`](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html?highlight=listen_address#broadcast-address)。为了在 Istio 网格中运行 Cassandra，应该将 `listen_address` 参数设置为 `127.0.0.1`，将 `broadcast_address` 参数设置为 Pod IP 地址。

这些配置参数在 Cassandra 配置目录（例如 `/etc/cassandra`）的 `cassandra.yaml` 中定义。有多种用于启动 Cassandra 的脚本（和 yaml 文件），应注意这些脚本如何设置这些参数。例如，一些用于配置和启动 Cassandra 的脚本使用环境变量 `CASSANDRA_LISTEN_ADDRESS` 的值来设置 `listen_address`。

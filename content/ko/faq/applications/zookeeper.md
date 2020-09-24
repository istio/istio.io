---
title: Can I run Zookeeper inside an Istio mesh?
description: How to run Zookeeper with Istio.
weight: 50
keywords: [zookeeper]
---

By default, Zookeeper listens on the pod IP address for communication
between servers. Istio and other service meshes require `localhost`
(`127.0.0.1`) to be the address to listen on.

There is a configuration parameter that can be used to change this
default behavior:
[`quorumListenOnAllIPs`](https://zookeeper.apache.org/doc/r3.5.7/zookeeperAdmin.html).
This option allows Zookeeper to listen on all addresses including the
`localhost`. Set this parameter to `true` by using the
following command where `$ZK_CONFIG_FILE` is your Zookeeper
configuration file.

{{< text bash >}}
$ echo "quorumListenOnAllIPs=true" >> $ZK_CONFIG_FILE
{{< /text >}}


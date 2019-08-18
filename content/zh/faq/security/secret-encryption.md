---
title: 工作负载中的密钥和证书是加密存储的么？
weight: 125
---

缺省情况下，这些数据会进行 Base64 编码，但是并没有加密。然而 Kubernetes 中的 [Secret 资源加密功能](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)是可以用来进行加密的。

注意 Google 容器引擎（GKE）中这一功能还未启用。因此 Master 节点上运行 ETCD 中的数据可能未被加密，而 Master 节点自身是加密的，请阅读 [GKE 相关文档](https://cloud.google.com/security/encryption-at-rest/default-encryption/#encryption_of_data_at_rest)了解更多相关细节。
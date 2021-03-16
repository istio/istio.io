---
title: 是否为工作负载中的密钥和证书进行了加密？
weight: 125
---

默认情况下，它们是 base64 编码的，但未加密。但是，您可以按照 Kubernetes 中支持的 [密钥加密功能](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) 来进行操作。

请注意，在 Google Container Engine (GKE) 中尚未启用此功能。虽然可能无法在主节点上运行的 etcd 内部对数据进行加密，但主节点本身的内容已加密，更多相关信息，请参照[此处](https://cloud.google.com/security/encryption-at-rest/default-encryption/#encryption_of_data_at_rest) 。

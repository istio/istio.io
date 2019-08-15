---
title: Kubernetes Env
description: 从 Kubernetes 环境中获取集群信息。
weight: 80
---

`kubernetesenv` 适配器能够从 Kubernetes 环境中获取信息，并生成 Istio 属性，供其它适配器使用。

这一适配器支持 [Kubernetes 模板](/zh/docs/reference/config/policy-and-telemetry/templates/kubernetes/)

## 参数

Kubernetes 适配器的配置参数，这些参数会影响到 Kubernetes 适配器对 Pod 信息的抓取和数据生成方式。

这个适配器通过使用 UID（格式为 `kubernetes://pod.namespace`） 进行 Pod 查找的方式完成工作。它的输入是一个 Map，其中包含三个流量相关的 UID（source、destination 以及 origin）。

有效的 UID 输入给适配器之后，适配器就会查找对应的 Pod，生成输出内容。

|字段|类型|描述|
|---|---|---|
|`kubeconfigPath`|`string`|`kubeconfig` 文件的路径。如果是集群内配置，可以不设置这一参数。如果是本地配置，就需要设置一个指向 `kubeconfig` 文件的路径，从而获取对 Kubernetes API Server 的访问能力。**如果有设置环境变量 `KUBEONFIG`，Kubernetes 适配器也会使用**，这一字段的缺省值为 `""`|
|`cacheRefreshDuration`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|控制 Kubernetes 集群信息的缓存。这些缓存会监控事件，并在指定时间之后重新同步。缺省值为五分钟|
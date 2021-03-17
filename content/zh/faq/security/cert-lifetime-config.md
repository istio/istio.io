---
title: 如何配置 Istio 证书的生命期？
weight: 70
---

对于在 Kubernetes 中运行的工作负载，其 Istio 证书的生命期由在Citadel中的 `workload-cert-ttl` 规定。

Citadel 使用 `max-workload-cert-ttl` 来控制颁发给工作负载的 Istio 证书的最长生命期。其默认值为 90 天。如果 Citadel 或 Istio 代理中的 `workload-cert-ttl` 大于 `max-workload-cert-ttl`，则 Citadel 将无法颁发证书。

你可以修改[生成清单](/zh/docs/setup/install/istioctl/#generate-a-manifest-before-installation)文件来自定义 Citadel 配置。以下的修改指定了在 Kubernetes 中运行的工作负载的 Istio 证书，其生命期为 1 小时。除此以外，允许 Istio 证书的最大生命期为 48 小时。

{{< text plain >}}
...
kind: Deployment
...
metadata:
  name: istio-citadel
  namespace: istio-system
spec:
  ...
  template:
    ...
    spec:
      ...
      containers:
      - name: citadel
        ...
        args:
          - --workload-cert-ttl=1h # Lifetime of certificates issued to workloads in Kubernetes.
          - --max-workload-cert-ttl=48h # Maximum lifetime of certificates issued to workloads by Citadel.
{{< /text >}}

对于在 VM 和裸机上运行的工作负载，其 Istio 证书的生命期由每个 Istio 代理中的 `workload-cert-ttl` 指定。其默认值也是 90 天。该值不应该大于 Citadel 中的 `max-workload-cert-ttl`。

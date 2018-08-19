---
title: 如何配置 Istio 证书的寿命？
weight: 70
---

对于在 Kubernetes 上运行的工作服在来说，它们的 Istio 证书是受到 Citadel 的 `workload-cert-ttl` 标志控制的。缺省值是 90 天。这个值不能大于 Citadel 的 `max-workload-cert-ttl`。

Citadel 使用标志 `max-workload-cert-ttl` 对 Istio 签发给工作负载的证书的寿命进行控制。缺省值是 90 天。如果 Citadel 或者 Node agent 中的 `workload-cert-ttl` 大于 `max-workload-cert-ttl`，Citadel 的证书签发就会失败。

可以对文件 `istio-demo-auth.yaml` 进行修改，从而对 Citadel 配置进行定制。下面的修改过程，让 Istio 为 Kubernetes 工作负载签发寿命为一小时的证书。并且 Istio 签发证书的最长寿命被设置为 48 小时。

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
          - --workload-cert-ttl=1h # 签发给 Kubernetes 工作负载的证书的寿命。 
          - --max-workload-cert-ttl=48h # Citadel 签发给 Kubernetes 工作负载的证书的最大寿命。
{{< /text >}}

对于运行于裸金属或者虚拟机上的工作负载来说，他们的 Istio 证书寿命是由每个 Node agent 的 `workload-cert-ttl` 决定的。其缺省值同样也是 90 天，这个值也不允许超出 Citadel 的 `max-workload-cert-ttl` 选项的值。

要定制这一配置，要在完成[设置虚拟机](/zh/docs/setup/kubernetes/mesh-expansion/#设置虚拟机)步骤之后，对 Node agent 服务（`/lib/systemd/system/istio-auth-node-agent.service`）的参数进行修改。

{{< text plain >}}
...
[Service]
ExecStart=/usr/local/bin/node_agent --workload-cert-ttl=24h # Specify certificate lifetime for workloads on this machine.
Restart=always
StartLimitInterval=0
RestartSec=10
...
{{< /text >}}

上面的配置中要求 Istio 为虚拟机或裸金属上运行的工作负载签发 24 小时寿命的证书。完成服务配置之后，需要重新启动 Node agent 服务。


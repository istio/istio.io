---
title: Istio 1.12 升级说明
description: 升级到 Istio 1.12.0 时需要考虑的重大变化。
publishdate: 2021-11-18
weight: 20
---

当您从 Istio 1.10.0 或 1.11.0 升级到 Istio 1.12.0 时，您需要考虑本页上的更改。
这些注释详细说明了故意打破 Istio 1.10.0 和 1.11.0 向后兼容性的更改。
注释中还提到了在引入新行为时保持向后兼容性的变化。
只有当新行为对 Istio 1.12.0 的用户来说是意想不到的时候，才会包含更改。

## TCP 探针现在按照预期工作{#TCP-probes-now-working-as-expected}

当对旧版本的 Istio 使用 TCP 探针时，检查总是成功的。TCP 探针只是简单地检查端口是否会接受连接，并且因为所有流量首先重定向到 Istio Sidecar，所以 Sidecar 将始终接受连接。
在 Istio 1.12 中，通过使用与 [HTTP 探针相同的机制](/zh/docs/ops/configuration/mesh/app-health-check/)解决了这个问题。
因此，1.12+ 中的 TCP 探针将开始正确检查配置端口的健康状况。当您的探针以前会失败时，现在将可能会接受到意外开始失败的反馈。
可以通过在 Istiod 部署中设置 `REWRITE_TCP_PROBES=false` 环境变量来临时禁用此更改。也可以[禁用](/zh/docs/ops/configuration/mesh/app-health-check/#liveness-and-readiness-probes-using-the-http-request-approach)整个探针重写功能（HTTP 和 TCP）。

## 执行基于修订的升级时必须切换为默认修订{#default-revision-must-be-switched-when-performing-a-revision-based-upgrade}

安装新的 Istio 控制平面修订版本时，之前的资源验证器将保持不变，以防止对现有稳定修订版产生意外影响。
一旦准备好迁移到新的控制平面版本，集群 Operators 就应该切换默认版本。
这可以通过 `istioctl tag set default --revision <new revision>` 来实现，
或者如果使用基于 Helm 的流程，则可以使用 `helm upgrade istio-base manifests/charts/base -n istio-system --set defaultRevision=<new revision>` 来完成。

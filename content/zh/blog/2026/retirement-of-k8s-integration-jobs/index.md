---
title: "针对不受支持的 Kubernetes 版本，停用 Kubernetes 集成作业"
description: Istio 的持续集成将不再针对不受支持的 Kubernetes 版本运行集成测试。
publishdate: 2026-09-16
attribution: "Francisco Herrera (Red Hat), Daniel Hawton (solo.io); Translated by Wilson Wu (DaoCloud)"
keywords: [Istio, Kubernetes, testing, CI]
---

Istio 测试和发布工作组将从 `master` 分支中淘汰旧 Kubernetes
版本的 CI 集成测试，这会影响 Istio 1.32 及更高版本。

## 发生了什么变化 {#what-s-changing}

以前，Istio 将支持一系列 Kubernetes 版本，通常是最新 Kubernetes
版本的 N-3 或 N-4，但会继续测试较旧的 Kubernetes 版本。
目前，这意味着我们正在测试 Kubernetes 1.23 到 1.36。

通过 [test-infra PR 6048](https://github.com/istio/test-infra/pull/6048)，
我们将从测试中删除已测试的旧 Kubernetes 版本，将我们的测试限制为仅支持的 Kubernetes 范围。
此更改是针对 `master` 分支进行的，因此将影响 Istio 版本 1.32 及更高版本。

## 我们为何做出此项变更 {#why-we-re-making-this-change}

这些 Kubernetes 版本要么已经终止生命周期 (EOL)，要么正在迅速接近终止生命周期。
上游 Kubernetes 支持大约 14 个月的次要版本；
请参阅 [Kubernetes 版本页面](https://kubernetes.io/zh-cn/releases/)了解官方支持状态。

维护旧节点映像并针对 EOL 版本运行测试会消耗宝贵的 CI 基础设施和时间。
退役这些工作使工作组可以将我们的测试资源集中在绝大多数社区运行的积极支持的版本上。

## 这对您意味着什么 {#what-this-means-for-you}

如果您仍然需要针对这些旧版本进行测试，
您可以使用 [kind](https://kind.sigs.k8s.io/) 在本地运行集成套件。

[`integ-suite-kind.sh`]({{< github_blob >}}/prow/integ-suite-kind.sh)
脚本是我们 CI 使用的确切入口点。您可以通过检查特定节点映像和配置的
[test-infra](https://github.com/istio/test-infra/blob/master/prow/aws/config/jobs/istio.yaml)
提交历史记录来针对所需的 Kubernetes 版本运行它：

{{< text bash >}}
$ prow/integ-suite-kind.sh \
      --node-image kind-node-target-version \
      --kind-config prow/config/mixedlb-service.yaml \
      test.integration.kube
{{< /text >}}

注意：将 `--node-image` 和 `--kind-config` 值替换为您要测试的
Kubernetes 版本之前在 CI 中使用的版本。

## 接下来做什么 {#what-s-next}

您始终可以在我们的[支持状态表](/zh/docs/releases/supported-releases/)中检查每个
Istio 版本当前经过测试的 Kubernetes 版本集。

如果您有任何疑问，请联系 Slack 上的 Istio 测试和发布工作组。

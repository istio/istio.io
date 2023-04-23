---
title: Istio 1.17 公告
linktitle: 1.17
subtitle: 大版本更新
description: Istio 1.17 发布公告。
publishdate: 2023-02-14
release: 1.17.0
aliases:
    - /zh/news/announcing-1.17
    - /zh/news/announcing-1.17.0
---

我们很高兴地宣布 Istio 1.17 发布。这是 2023 年的第一个 Istio 版本。
我们要感谢整个 Istio 社区对 1.17.0 版本发布所作出的帮助。
我们要感谢此版本的几位发布经理：来自 IBM 的`Mariam John`，来自 Tetrate 的 `Paul Merrison` 和来自 Microsoft 的 `Kalya Subramanian`。
这些发布经理们要特别感谢测试和发布工作组负责人 Eric Van Norman (IBM) 在整个发布周期中提供的帮助和指导。
我们还要感谢 Istio 工作组的维护者和更广泛的 Istio 社区，感谢他们在整个发布过程中通过及时的反馈、评论、社区测试以及所有支持来帮助我们确保及时发布。

{{< relnote >}}

{{< tip >}}
Istio 1.17.0 已得到 Kubernetes `1.23` 到 `1.26` 的官方正式支持。
{{< /tip >}}

## 新特性{#what-is-new}

自 1.16 版本以来，我们添加了一些重要的新特性，还将现有的一些特性进阶至表示生产就绪的 Beta。
以下是一些亮点：

### 金丝雀升级和修订版标记进阶至 Beta{#canary-upgrade-and-revision-tags-to-beta}

All integration tests and end-to-end tests covering documentation have been completed for this feature to graduate to Beta.

Istio 1.6 版本中引入了对使用修订版按照金丝雀模式升级服务网格的基本支持。
使用这种方法，您可以在不影响现有部署的情况下并列运行多个控制平面，并将工作负载从旧控制平面缓慢迁移到新控制平面。
在 Istio 1.10 中，引入了修订标记作为对金丝雀升级的改进，以帮助减少操作员为使用修订版而不得不进行的更改次数，从而安全地升级 Istio 控制平面。
这是我们的用户在生产中广泛采用和使用的特性。
为了此特性进阶到 Beta，包含文档在内的所有集成测试和端到端测试都已完成。

### Helm 安装进阶至 Beta{#helm-install-promoted-to-beta}

基于 Helm 安装 Istio 首次在 Istio 0.4 中引入，现已进阶至 Beta。
这是在生产环境中安装 Istio 时使用最广泛一种方法。
在此版本中完成了将此特性进阶至 Beta 的所有要求，包括更新集成测试以使用 Helm Chart
进行安装/升级、更新 Helm 集成测试以及在 `values.yaml` 中记录高级 Helm Chart 自定义和属性。

### 升级了对 Kubernetes Gateway API 的支持{#upgraded-support-for-k8s-gateway-api}

Istio 的 [Gateway API](https://gateway-api.sigs.k8s.io/) 实现已进阶至且完全兼容最新版本的 API (0.6.1)。

### Istio 双栈支持{#dual-stack-support}

Kubernetes 在 1.16 版中添加了双栈模式下的 IPv6 支持，并在 Kubernetes 1.22 版中升级为稳定版。
在 Istio 中启用双栈支持的基础始于 Istio 1.16 版本。
在 Istio 1.17 版本中，添加了以下功能以在 Istio 中启用双重支持：

- 使用户能够在双栈集群上部署具有单栈或双栈 IP 系列的服务。
    例如，用户可以在双栈 Kubernetes 集群上分别部署仅 IPv4、仅 IPv6 和双栈 IP 系列的 3 个服务，使这些服务可以通过 Sidecar 相互访问。
- 为网关的侦听器添加额外的源地址配置以支持双堆栈模式，以便服务网格外的 IPv4 和 IPV6 客户端可以访问 Gateway。
    这仅适用于通过 Gateway 控制器自动部署的 Gateway，Kubernetes 的原生 Gateway 应该已经支持双栈。

这是实验性的特性，目前还在[积极开发中](https://github.com/istio/istio/issues/40394)。

### 在 Istio 中添加了对过滤器修补的支持{#added-support-for-filter-patching}

添加了对侦听器过滤器修补的支持，使用户能够在 Istio 的 `EnvoyFilter` 资源中对 `LISTENER_FILTER`
执行 `ADD`、`REMOVE`、`REPLACE`、`INSERT_FIRST`、`INSERT_BEFORE`、`INSERT_AFTER` 操作。

### 在 Istio 添加了对使用 `QuickAssist Technology` (QAT) `PrivateKeyProvider` 的支持{#added-support-for-using-qat}

添加了对在 SDS 中使用 `QuickAssist Technology` (QAT) `PrivateKeyProvider` 的支持，并添加了用于为网关和 Sidecar 选择 QAT 私钥提供程序的相应配置。
这是基于这样一个事实，即 Envoy 添加了[对 QAT 的支持](https://github.com/envoyproxy/envoy/issues/21531)，
作为 [CryptoMB]( https://istio.io/latest/blog/2022/cryptomb-privatekeyprovider/) 之外的另一个私钥提供程序。
有关 QAT 的更多信息，您可以参考[此处](https://www.intel.com/content/www/us/en/developer/articles/technical/envoy-tls-acceleration-with-quickassist-technology.html)。

### 对 `RequestAuth` API 的增强{#enhancements-to-requestauth}

添加了将 JWT 声明复制到 `RequestAuth` API 中的 HTTP 请求头的支持。

### 对 `istioctl` 命令的增强{#enhancements-to-istioctl}

为 istioctl 命令添加了一些增强功能，包括添加：

- `revision` 标记到 `istioctl admin log`，以便在 Istiod 之间切换控制
- `istioctl proxy-config ecds`，支持从 Envoy 为指定的 Pod 检索分类的扩展配置
- `istioctl proxy-config log`，为部署中的所有 Pod 设置代理日志级别
- `--revision` 标志到 `istioctl analyze`，以指定特定的修订版

## 欢迎参加 Istio Day, 2023{#join-istio-day-2023}

[Istio Day Europe 2023](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/)
定于 4 月 18 日举行，是 CNCF 主办的第一届 Istio 会议。
这将是与 [KubeCon + CloudNativeCon Europe 2023](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe) 共同举办的 Day 0 活动。
这是全球社区成员与 Istio 开发者、合作伙伴和供应商生态系统联系的绝佳机会。
有关本次活动的更多信息，请访问[会议网站](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/)。
我们希望您能加入 Istio Day Europe。

## 升级至 1.17{#upgrading-to-1.17}

我们想听听您关于升级到 Istio 1.17 的体验。
请花几分钟时间回复[简短调查](https://forms.gle/99uiMML96AmsXY5d6)，让我们知道自己做得怎样以及如何改进。

您还可以加入 [Discuss Istio](https://discuss.istio.io/) 的会话，
或加入我们的 [Slack 工作空间](https://slack.istio.io/)。
您想直接为 Istio 做贡献吗？
找到并加入我们的某个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，
帮助我们改进。

---
title: 版本支持
description: 当前支持的 Istio 版本。
weight: 35
aliases:
    - /zh/about/supported-releases
    - /zh/latest/about/supported-releases
owner: istio/wg-docs-maintainers
test: n/a
---

此页面列出了当前支持的版本的状态、时间表和策略。
受支持的 Istio 版本包括处于维护窗口期以及为安全问题和错误提供了补丁的版本。
Minor 版本中的补丁版本不包含向后的兼容性。

- [支持策略](#support-policy)
- [命名方案](#naming-scheme)
- [控制面/数据面偏差](#control-planedata-plane-skew)
- [Istio 版本的支持状态](#support-status-of-istio-releases)
- [没有已知的 CVE 和常见漏洞的受支持版本](#supported-releases-without-known-common-vulnerabilities-and-exposures-cves)
- [Istio 和 Envoy 之间的关系](#supported-envoy-versions)

## 支持策略 {#support-policy}

每个提交会产生 Istio 构建版本。大约每个季度我们会构建一个 Minor
版本并进行大量测试和发行认证。并对在 Minor 版本中发现的问题发布补丁版本。

不同类型代表不同的产品质量，Istio 团队对其有不同的支持力度。
在这种情况下，标明 **支持** 意味着我们将为关键问题发布补丁并提供技术支持。
另外，第三方和合作伙伴也可能提供长期支持方案。

|类型              | 支持级别                                                                                                         | 质量和建议使用场景
|------------------|-----------------------------------------------------------------------------------------------------------------------|----------------------------
|开发构建 | 不支持                                                                                                            | 危险，不完全可靠。建议用于实验、测试场景。
|Minor 版本     | 在 N+2 Minor 版本发布后提供6个星期的支持（例如在 1.13.0 版本发布后，对 1.11 版本提供 6 个星期的支持
|补丁             | 与相应的 Minor 版本相同                                                                               | 建议用户在补丁可用时尽快采用。
|安全补丁    | 与补丁相同，但是除了上一个补丁程序的安全修复之外，它将不包含任何其他代码 | 因为安全修复的重要性，**强烈** 建议用户采用发行版本后的安全补丁。

您可以在[发布页面](https://github.com/istio/istio/releases)上找到可用的版本，
如果您愿意冒险，可以在[每日构建 wiki](https://github.com/istio/istio/wiki/Daily-builds)上了解我们的每日构建，
也可以在[此处](/zh/news)找到每个 Minor 版本和补丁版本的高级发行说明。

## 命名方案 {#naming-scheme}

我们的命名方案如下：

{{< text plain >}}
<major>.<minor>.<patch>
{{< /text >}}

其中 `<minor>` 在每个版本中递增，`<patch>` 代表了当前 `<minor>` 版本的补丁数。
对于 `<minor>` 版本来说一个补丁通常是一个很小的变更。

## 控制面/数据面偏差 {#control-planedata-plane-skew}

Istio 控制面可以比数据面高一个版本。但数据面的版本不能比控制面高。
我们推荐使用[修订版](/zh/docs/setup/upgrade/canary/)，使得控制面和数据面之间没有偏差。

迄今为止，数据面到数据面在所有版本上都是兼容的；但未来可能有所变化。

## Istio 版本的支持状态 {#support-status-of-istio-releases}

{{< support_status_table >}}

## 没有已知的 CVE 和常见漏洞的受支持版本 {#supported-releases-without-known-common-vulnerabilities-and-exposures-cves}

{{< warning >}}
Istio 不保证超出支持窗口期的 Minor 版本都有已知的 CVE 补丁。请使用最新和受支持的版本。
{{< /warning >}}

| Minor 版本 | 没有已知 CVE 的补丁版本                        |
| ---------- | ------------------------------------------ |
| 1.18.x     | 1.18.0                                     |
| 1.17.x     | 1.17.2+                                    |
| 1.16.x     | 1.16.4+                                    |
| 1.15.x     | 1.15.7 - 生命周期结束。不会针对新的 CVE 打补丁。 |

## 支持的 Envoy 版本 {#supported-envoy-versions}

Istio 的数据面基于 [Envoy](https://github.com/envoyproxy/envoy)。

这两个项目之间的版本关系如下：

| Istio 版本 | Envoy 版本 |
| ---------- | ---------- |
| 1.18.x     | 1.26.x     |
| 1.17.x     | 1.25.x     |
| 1.16.x     | 1.24.x     |

通常，Istio 版本倾向于与 Envoy 版本逐一对应。
您可以在 [`istio/proxy`](https://github.com/istio/proxy/blob/master/WORKSPACE#L38)
中找到 Istio 所使用的确切的 Envoy Commit。

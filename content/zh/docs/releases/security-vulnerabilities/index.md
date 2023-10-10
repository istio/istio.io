---
title: 安全漏洞
description: 我们如何处理安全漏洞。
weight: 35
aliases:
    - /zh/about/security-vulnerabilities
    - /zh/latest/about/security-vulnerabilities
owner: istio/wg-docs-maintainers
test: n/a
---

我们非常感谢那些报告 Istio 安全漏洞的安全研究人员和用户。
我们会彻底分析和评估每份报告。

## 报告漏洞  {#reporting-a-vulnerability}

要进行漏洞报告，请将包含漏洞详细信息的电子邮件发送到
[istio-security-vulnerability-reports@googlegroups.com](mailto:istio-security-vulnerability-reports@googlegroups.com)，
对于与潜在安全漏洞无关的普通产品错误，
请转到我们的[报告错误](/zh/docs/releases/bugs/)页面以了解如何操作。

### 何时报告安全漏洞？  {#when-to-report-a-security-vulnerability}

只要您有以下情况，请向我们发送报告：

- 认为 Istio 具有潜在的安全漏洞。
- 不确定漏洞是否或如何影响 Istio。
- 认为 Istio 依赖的另一个项目中存在漏洞。例如 Envoy、Docker 或 Kubernetes。

当不确定的时候，请向我们私下披露。这包括但不限于：

- 任何的崩溃，特别是在 Envoy 中
- 任何的安全策略（比如认证或授权）的绕过或者脆弱性
- 任何潜在的拒绝服务（DoS）

### 什么时候不报告安全漏洞？  {#when-not-to-report-a-security-vulnerability}

在以下情况下，请勿发送漏洞报告：

- 您需要帮助调整 Istio 组件的安全性。
- 您需要使用安全更新相关的帮助。
- 您的问题与安全性无关。
- 您的问题与基础镜像依赖关系有关（查看[基础镜像](#base-images)）。

## 评估  {#evaluation}

Istio 安全团队会在三个工作日内确认并分析每个漏洞报告。

您与 Istio 安全团队共享的任何漏洞信息都属于 Istio 项目，
我们仅共享解决问题所需的信息，不会将信息传播给其他项目。

从 `triaged` 到 `identified fix` 再到
`release planning`，我们会随时反馈安全问题的状态。

## 修复问题  {#fixing-the-issue}

一旦对安全漏洞进行了充分描述，Istio 团队就会开发出修复程序。
修复程序的开发和测试在私有 GitHub 仓库中进行，以防止过早披露此漏洞信息。

## 早期披露  {#early-disclosure}

Istio 项目维护了一个邮件列表，用于在私下及早的公开安全漏洞。
该列表用于提供可操作的信息给与 Istio 密切的合作伙伴。
该列表不用于让个人了解安全问题。

请参阅[早期披露的安全漏洞](https://github.com/istio/community/blob/master/EARLY-DISCLOSURE.md)以获取更多信息。

## 公开披露  {#public-disclosure}

在选择公开披露的当天，下面一系列动作会尽可能快的进行：

- 将私有 GitHub 仓库中拥有修复程序的分支与公共仓库的相应分支进行合并。

- 发布工程师确保所有必要的二进制文件都可以迅速生成和发布。

- 二进制文件可用后，将通过以下渠道发送公告：

    - [Istio 博客](/zh/blog)
    - discuss.istio.io 上的 [Announcements](https://discuss.istio.io/c/announcements) 栏目
    - [Istio Twitter feed](https://twitter.com/IstioMesh)
    - Slack 上的 [#announcements](https://istio.slack.com/messages/CFXS256EQ/) 频道

该公告将尽可能包含客户在升级到固定版本之前能够采取的任何缓解措施，
这些公告的建议发布时间是 UTC 时间星期一至四的 16:00。
这意味着该公告将在太平洋时间的早上、欧洲傍晚和亚洲傍晚发布。

## 基础镜像  {#base-images}

Istio 提供了两组基于 `ubuntu` 和基于 `distroless` 的默认 Docker 镜像，
更多详情请查阅（[加固 Docker 容器镜像](/zh/docs/ops/configuration/security/harden-docker-images/)）。
这些镜像中偶尔会存在一些新发现的 CVE 安全漏洞。
Istio 安全团队会对这些镜像进行自动扫描，以确保基础镜像中没有已知的 CVE 安全漏洞。

当在镜像中检测到 CVE 安全漏洞时，新的镜像将被自动构建并用于所有后续构建。
此外，安全团队会分析这些漏洞，查验这些漏洞是否可以直接在 Istio 中被利用。
在大多数情况下，这些漏洞可能存在于基础镜像包中，但无法在 Istio 使用这些镜像时被人加以利用。
对于这些情况，新版本通常不会仅仅为了解决这些 CVE 而发布，具体的修复将包含在下一个定期发布的版本中。

因此，基础镜像 CVE 安全漏洞不应被[报告](#reporting-a-vulnerability)，
除非有证据表明它可以在 Istio 中被利用。

如果减少基础镜像 CVE 安全漏洞对您很重要，强烈建议使用
[`distroless`](/zh/docs/ops/configuration/security/harden-docker-images/) 基础镜像。

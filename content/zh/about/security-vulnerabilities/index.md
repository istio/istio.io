---
title: 报告 Istio 安全漏洞
description: 负责披露 Istio 安全漏洞。
weight: 35
icon: vulnerabilities
---

我们非常感谢报告 Istio 安全漏洞的安全研究人员和用户。我们会对每个报告进行彻底调查。

## 报告漏洞{#Reporting-a-vulnerability}

创建报告，可以发送电子邮件至 [istio-security-vulnerability-reports@googlegroups.com](mailto:istio-security-vulnerability-reports@googlegroups.com) 邮件列表，包含漏洞详细信息。对于与潜在安全漏洞无关的常见产品错误，请访问我们的[`报告错误页面`](/zh/about/bugs)了解该怎么做。

### 何时报告安全漏洞？

以下情况您可以发送安全漏洞报告：

- 考虑 Istio 存在潜在的安全漏洞。
- 不确定漏洞是否或如何影响 Istio 。
- 认为 Istio 所依赖的另一个项目中存在漏洞。例如：Envoy 、Docker 或 Kubernetes 。

### 何时不应该报告安全漏洞？

以下情况下不要发送漏洞报告：

- 您需要帮助调优 Istio 组件以确保安全性。
- 您需要帮助应用与安全相关的更新。
- 您的问题与安全性无关。

## 评估{#evaluation}

Istio 安全团队在三个工作日内确认并分析每个漏洞报告。

您与 Istio 安全团队共享的任何漏洞信息都保留在 Istio 项目中。我们不会将信息传播给其他项目。我们仅根据需要共享信息以解决问题。

随着安全问题的状态从 `triaged` 转变为 `identified fix`，再到 `release planning`，我们随时更新给报告者。

## 解决问题{#fixing-the-issue}

一旦证实了安全漏洞，Istio 团队就会开发修复程序。修复程序的开发和测试在私有 GitHub 存储库中，以防止过早泄露漏洞。

## 早期披露{#early-disclosure}

在向公众披露漏洞之前，有一小部分 Istio 合作伙伴会获得早期私下披露。这是为了使分发 Istio 二进制文件的合作伙伴能够充分准备分发修复程序。

在完全公开披露之前三个工作日就会发生早期披露。

请填写[早期安全漏洞披露](https://github.com/istio/community/issues/new?template=early-disclosure-request.md)表单，以请求添加到早期披露邮件列表中。

## 公开披露{#public-disclosure}

在选择公开披露的那一天，一系列活动尽快进行：

- 更改将从包含修订的私有 GitHub 存储库合并到适当的公共分支中。

- 发布工程师确保及时构建和发布所有必需的二进制文件。

- 二进制文件可用后，将在以下渠道发送通知：

    - [Istio博客](/zh/blog)
    - discuss.istio.io 上的[公告](https://discuss.istio.io/c/announcements)类别
    - [Istio Twitter 反馈](https://twitter.com/IstioMesh)
    - [Slack 上的 #announcement 频道](https://istio.slack.com/messages/CFXS256EQ/)

该公告应该尽可能具有可执行性，包括用户在升级到固定版本之前可以采取的临时解决方案。这些公告的建议时间是周一至周四的 16:00（UTC）。这意味着该公告将在太平洋早晨，欧洲傍晚和亚洲傍晚发出。

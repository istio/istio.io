---
title: 报告 Istio 安全漏洞
description: 负责披露 Istio 安全漏洞。
weight: 35
icon: vulnerabilities
---

我们非常感谢报告 Istio 安全漏洞的安全研究人员和用户。我们会对每个报告进行彻底调查。

创建报告，可以发送电子邮件至 [`istio-security-vulnerabilities@googlegroups.com`](mailto:istio-security-vulnerabilities@googlegroups.com) 邮件列表，包含漏洞详细信息。对于与潜在安全漏洞无关的常见产品错误，请访问我们的[`报告错误页面`](/about/bugs)了解该怎么做。

## 何时报告安全漏洞？

以下情况您可以发送安全漏洞报告：

- 考虑 Istio 存在潜在的安全漏洞。
- 不确定漏洞是否或如何影响 Istio 。
- 认为 Istio 所依赖的另一个项目中存在漏洞。例如：Envoy 、Docker 或 Kubernetes 。

## 何时不应该报告安全漏洞？

以下情况下不要发送漏洞报告：

- 您需要帮助调优 Istio 组件以确保安全性。
- 您需要帮助应用与安全相关的更新。
- 您的问题与安全性无关。

## 安全漏洞响应

Istio 安全团队将在三个工作日内确认并分析每份报告。

您与 Istio 安全团队共享的任何漏洞信息都保留在 Istio 项目中。我们不会将信息传播给其他项目。我们仅根据需要共享信息以解决问题。

随着安全问题的状态从 `triaged` ，到 `identified fix` ，再到 `release planning` ，我们会保持报告者进行更新。

## 公开披露时间

Istio 安全团队和错误提交者协商公开披露日期。我们希望在用户缓解措施可用后尽快完全披露该错误。当错误或修复尚未完全理解，解决方案未经过充分测试或供应商协调时，我们考虑合理延迟披露。如果问题已经公开已知,披露的时间是即时的，或持续几周。我们预计报告日期和披露日期相隔七天。 Istio 安全团队在设定披露日期方面拥有最终决定权。

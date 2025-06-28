---
title: "快速入门"
description: 了解如何通过简单的示例安装开始。
weight: 50
keywords: [introduction]
owner: istio/wg-docs-maintainers-chinese
skip_seealso: true
test: n/a
---

感谢您对 Istio 的关注！

Istio 有两种主要模式：**Ambient 模式**和 **Sidecar 模式**。

* [Ambient 模式](/zh/docs/overview/dataplane-modes/#ambient-mode)是一种全新改进的模型，
  旨在弥补 Sidecar 模式的不足。在 Ambient 模式下，每个节点都会安装一个安全隧道，
  您可以选择安装代理（通常按命名空间安装）来启用其全部功能。
* [Sidecar 模式](/zh/docs/overview/dataplane-modes/#sidecar-mode)是
  Istio 于 2017 年首创的传统服务网格模型。在 Sidecar 模式下，
  代理会与每个 Kubernetes Pod 或其他工作负载一起部署。

Istio 社区的大部分精力都投入到了 Ambient 模式的改进上，
尽管 Sidecar 模式仍然得到全面支持。任何贡献给项目的主要新功能都有望在两种模式下运行。

一般来说，**我们建议新用户从 Ambient 模式开始**。它速度更快、
成本更低，而且更易于管理。有些[高级用例](/zh/docs/overview/dataplane-modes/#unsupported-features)仍然需要使用 Sidecar 模式，
但弥补这些不足是我们 2025 年路线图上的目标。

<div style="text-align: center;">
  <div style="display: inline-block;">
    <a href="/zh/docs/ambient/getting-started"
       style="display: inline-block; min-width: 18em; margin: 0.5em;"
       class="btn btn--secondary"
       id="get-started-ambient">开始使用 Ambient 模式</a>
    <a href="/zh/docs/setup/getting-started"
       style="display: inline-block; min-width: 18em; margin: 0.5em;"
       class="btn btn--secondary"
       id="get-started-sidecar">开始使用 Sidecar 模式</a>
  </div>
</div>

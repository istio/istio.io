---
title: 文档审阅流程
description: 向您展示如何审阅和批准对 Istio 文档和网站的更改。
weight: 6
keywords: [contribute,community,github,pr,documentation,review, approval]
---

Istio 文档工作组（Docs WG）的维护者和工作组负责人审批针对 [Istio 网站](/zh/docs/)的所有更改。

**文档审阅者** 是一个受信任的贡献者，负责批准符合[审阅标准](#review-criteria)的内容。
所有审阅都遵循 [PR 内容审阅](#review-content-prs)中描述的流程。

只有文档维护者和工作组负责人才能将内容合并到 [istio.io 存储库](https://github.com/istio/istio.io)。

与 Istio 相关的内容通常需要在短时间内完成审阅，并非所有内容都具有同样的相关性。
鉴于投稿的时效性和有限的审阅者数量，我们必须确定内容审阅的优先级，以便大规模运作。
该页面提供了明确的审阅标准，以确保所有审阅工作**一致**、**可靠**且遵循**相同的质量标准**。

## PR 内容审阅{#review-content-prs}

文档审阅者、维护者和工作组负责人，对 PR 内容的审阅必须遵循审阅流程，以确保所有审阅一致。流程如下：

1. **贡献者**提交新的 PR 到 istio.io 仓库。
1. **审阅者**进行内容审阅，并确定它是否符合[绝对验收标准](#required-acceptance-criteria)。
1. 如果贡献者尚未加入任何与贡献内相关的技术工作组，则**审阅者**可将其加入到相应工作组。
1. **贡献者**和**审阅者**协同工作，直到内容符合所有[绝对验收标准](#required-acceptance-criteria)，且 Issue 得到完全解决。
1. 如果内容非常紧急，且满足[补充验收标准](#required-acceptance-criteria)需要大量工作，**审阅者** 可在 istio.io 仓库提交[跟进 Issue](#follow-up-issues)，以在后续处理这些问题。
1. **贡献者**根据审阅者和贡献者的意见，处理所有反馈。[跟进 Issue](#follow-up-issues) 中提到的问题将在后续解决。
1. 当 **技术**工作组负责人或维护者批准 PR 内容，**审阅者** 可以批准 PR。
1. 如果 Docs WG 维护者或负责人审阅了内容，则他们不仅会批准内容，还会对其进行合并。否则，维护者和负责人将自动收到**审阅者**的批准通知，并优先批准和合并已审阅的内容。

下图描述了该流程：

{{< image width="75%" ratio="45.34%"
    link="./review-process.svg"
    alt="文档审阅流程"
    title="文档审阅流程"
    >}}

- **贡献者** 执行步骤在灰色节点。
- **审阅者** 执行步骤在蓝色节点。
- **文档维护者和工作组负责人** 执行步骤在绿色节点。

## 跟进 Issue{#follow-up-issues}

当**审阅者**在 [PR 内容审阅](#review-content-prs)中提出跟进 Issue 时，需在 Issue 中包含以下信息：

- 关于内容不符合[补充接受标准](#supplemental-acceptance-criteria)的详细信息。
- 指向原始 PR 的链接。
- 技术主题专家（SMEs）用户名。
- 添加 Labels 以便于问题排序。
- 工作量估计：审阅者提供与原始贡献者一起解决剩余问题所需的最佳估计时间。

## 审阅标准{#review-criteria}

审阅流程，通过将明确的审阅标准应用于所有内容以支持我们的[行为准则](https://www.contributor-covenant.org/version/2/0/code_of_conduct)。

### 绝对验收标准{#required-acceptance-criteria}

- 技术准确性：至少一名技术工作组负责人或维护者对内容进行审核和批准。
- 正确的编码：必须通过所有的 lint 检查和测试。
- 语言：内容必须清晰易懂。要了解更多信息，请参阅 Google 开发者风格指南的 [highlights](https://developers.google.com/style/highlights) 和 [general principles](https://developers.google.com/style/tone)。
- 链接和导航：内容中涉及的所有链接必须有效，且网站可以正常构建。

### 补充验收标准{#supplemental-acceptance-criteria}

- 内容结构：良好的信息结构可增强阅读体验。
- 一致性：内容遵循 [Istio 贡献指南](/zh/about/contribute/)中的所有建议。
- 风格：内容遵循 [Google 开发者风格指南](https://developers.google.com/style)。
- 图形附件：遵循 Istio [图形创建指南](/zh/about/contribute/diagrams/)。
- 示例代码：提供与内容密切相关且可测试的有效代码示例。
- 内容服用：任何可重复的内容都遵循使用样板文本的可重用性策略。
- 术语：所有新的术语都已经添加到术语表中，且定义清晰。

---
title: 样式指南
description: 编写 Istio 文档时候的“要”和“不要”。
weight: 70
keywords: [contribute]
---

本文为 Istio 文档提供内容指南。这是建议，不是规范，所以作者应自行做出最佳判断，也可以随时对本文以 PR 的形式提出变更建议。

## 格式标准

### 一致的大写方式

不建议使用大写的方式来表达强调。

在引用代码或配置文件中的名称的时候，应该以 \`\` 包围，不应该拆分为单词，并且要遵循原文的大小写方式，例如 `IstioRoleBinding`，不要改写为 `Istio Role Binding` 或者 `istio role binding`。

如果不是直接引用代码或配置内容，应该使用正常的大写方式，例如 "The Istio role binding configuration takes place
in a YAML file."

### 用尖括号标识占位符

使用下面的尖括号形式，告知读者占位符中想要表达的内容

1. 显示 Pod 的信息：

    {{< text bash >}}
    $ kubectl describe pod <pod-name>
    {{< /text >}}

    这里的 `<pod-name>` 就是 Pod 的名称。

### 使用 `**加粗显示**` 表达用户界面元素

|建议               |不建议
|-----------------|------
|点击**Fork**。  |点击 "Fork"。
|选择**Other**。|选择 'Other'。

### 使用 `**加粗显示**` 定义或引入新词汇

|建议                                         |不建议
|-------------------------------------------|---
|**集群**是一组节点 ...          | "集群"是一组节点 ...

### 使用 \`code\` 样式来表达文件名、目录名以及路径

|建议                                   |不建议
|-------------------------------------|------
|打开文件 `foo.yaml`。         | 打开文件 foo.yaml。
|进入 `/content/docs/tasks` 目录。|进入 /content/docs/tasks 目录。
|打开文件 `/data/args.yaml`。 | 打开文件 /data/args.yaml。

### 使用 \`code\` 表达行内代码和命令

|建议                                   |不建议
|----------------------------|------
| `foo run` 命令会创建一个 `Deployment`。|"foo run" 命令会创建一个 `Deployment`。
|声明式的管理，可以使用 `foo apply`。|声明式的管理，可以使用 "foo apply"。

### 使用 \`code\` 表示对象的字段名称

|建议                                   |不建议
|-----------------------------------------------------------------|------
|在配置文件中设置 `ports` 字段的值。 |在配置文件中设置 "ports" 字段的值。
|`rule` 字段的值是一个 `Rule` 对象。           | "rule" 字段的值是一个 `Rule` 对象。

### Front-matter 中的 title 字段应该使用标题方式的大写

Front matter 中的 `title:` 应该使用标题格式：除了连词和介词之外，每个单词的首字母都大写。

这一点和将要提到的文章内的多级标题是不一样的。

### 各级标题中只对头一个单词进行首字母大写

任何级别的标题，只对第一个字母进行首字母大写，除非涉及到缩写和专有名词。

|建议  |不建议
|------------------------|-----
|Configuring rate limits | Configuring Rate Limits
|Using Envoy for ingress | Using envoy for ingress
|Using HTTPS             | Using https

## 术语标准

为清晰起见，我们希望在文档中始终如一地使用一些标准术语。

### Envoy

推荐使用 "Envoy"，这一称呼相对于 "proxy" 来说更加具体，在文档中更加容易呼应。

同义词：

- "Envoy sidecar” -- 可以。
- "Envoy proxy” -- 可以。
- "Istio proxy” -- 最好避免，除非要谈论的是使用其他代理的高级场景。
- "Sidecar”  -- 绝大多数时间只会在概念性文档中使用。
- "Proxy" -- 只在上下文非常清晰的时候使用。

相关词汇：

- Proxy agent：这是一个重要的基础设施组件，只会出现在底层细节的文档之中。这一称呼并非专有名词。

### 杂项

|建议              |不建议
|----------------|------
| load balancing | `load-balancing`
| multicluster   | `multi-cluster`
| add-on         | `add-on`
| service mesh   | `Service Mesh`
| sidecar        | `side-car`, `Sidecar`
| Kubernetes     | `kubernetes`, `k8s`
| Bookinfo       | `BookInfo`, `bookinfo`
| Mixer          | `mixer`
| delete         | `kill`

## 最佳实践

### 使用现在时

|建议              |不建议
|-----------------------------|------
|This command starts a proxy. | This command will start a proxy.

例外：在必要的时候还是要使用将来时或过去时的。

### 使用主动语态

|建议              |不建议
|-------------------------------------------|------
|You can explore the API using a browser.   | The API can be explored using a browser.
|The YAML file specifies the replica count. | The replica count is specified in the YAML file.

例外: 在主动语态可能引起误会时，还是应该使用被动语态。

### 简单直接的表达方式

简单直接的陈述，避免使用不必要的文字，例如“请”。

|建议              |不建议
|----------------------------|------
|To create a `ReplicaSet`, ... | In order to create a `ReplicaSet`, ...
|See the configuration file. | Please see the configuration file.
|View the Pods.              | With this next command, we'll view the Pods.

### 称读者为“你”

|建议              |不建议
|---------------------------------------|------
|你可以创建一个 `Deployment` ...     | 我们来创建一个 `Deployment` ...
|在后续输出中，你会发现 ...| 在后续输出中，我们会看到 ...

### 使用有用的链接

链接有好坏。**这里**或者**点击这里**都是坏链接的例子。建议阅读下面链接中的文章，其中讲述了如何更好的使用超链接的问题，在创建或审核内容时，尝试遵循其中的建议。

[Why "click here” is a terrible link, and what to write instead](https://medium.com/@heyoka/dont-use-click-here-f32f445d1021).

### 避免使用“我们”

在句子中使用“我们”会让人迷惑，读者不易分辨自己是否“我们”之中的一员。

|建议              |不建议
|------------------------------------------|------
|1.4 版中包括 ...                  | 在 1.4 版中，我们加入了 ...
|Istio 提供了新的功能 ... | 我们提供了新的功能 ...
|本文将教会你如何使用 Pod。    | 本文中，我们将学习 Pod 的相关知识。

### 避免使用行话和习语

英文是部分读者的第二语言，为了让更多读者更方便的理解内容，应避免使用行话和习语

|建议              |不建议
|----------------------|------
|Internally, ...       | Under the hood, ...
|Create a new cluster. | Turn up a new cluster.

### 避免预言

避免预言或承诺未来。如果需要进行关于 Alpha 特性的讨论，请在标题下方用文字清晰的声明 Alpha 的相关信息。

### 避免使用快速过时的描述

避免“当前”或者“新的”这样的用词。今天的新功能可能几个月后就不新了。

|建议              |不建议
|------------------------------------|------
|1.4 版， ...                 | 当前版本，...
|联邦功能提供了 ... | 新的联邦功能提供了 ...

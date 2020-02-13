---
title: 风格指南
description: 介绍撰写 Istio 文档时应执行的行为规范。
weight: 20
aliases:
    - /zh/docs/welcome/contribute/style-guide.html
    - /zh/docs/reference/contribute/style-guide.html
keywords: [contribute]
---

本页提供 Istio 文档的内容准则。如果您对这些准则有更好的想法和建议，欢迎在 GitHub 中对本文档进行完善。

## 格式标准{#formatting-standards}

### 使用一致的大写{#use-consistent-capitalization}

请勿使用大写表示强调。

当您对代码或配置文件中的原始内容进行引用时，不要随意调整大小写，请确保与其原始风格一致。
在被引用的内容周围需使用反引号 \`\` 包括，以明确表示内容原自代码或配置。例如，使用 `IstioRoleBinding`，而不是 `Istio Role Binding` 或 `istio role binding`。

如果您不是直接引用值或代码，请使用常规的大写字母，例如，"The Istio role binding configuration takes place
in a YAML file."。

### 将尖括号用于占位符{#use-angle-brackets-for-placeholders}

将尖括号用于占位符，以告诉读者占位符代表什么。例如：

1.  显示有关 Pod 的信息：

    {{< text bash >}}
    $ kubectl describe pod <pod-name>
    {{< /text >}}

    位置 `<pod-name>` 表示需要用 Pod 的名字进行替换。

### 使用**加粗**样式书写用户界面元素{#use-bold-for-user-interface-elements}

| 正确做法          | 错误做法
|-----------------|------
| 点击 **Fork**。 | 点击 "Fork"。
| 选择 **Other**。| 选择 'Other'。

### 使用斜体书写定义或专用术语{#use-italics-to-define-or-introduce-new-terms}

| 正确做法                                    | 错误做法
|-------------------------------------------|---
| *集群* 是一组节点……          | "集群"是一组节点……
| 这些组件构成 *控制平面* 。 | 这些组件构成**控制平面**。

### 使用`代码`风格书写文件名、目录和路径{#use-code-style-for-filenames-directories-and-paths}

| 正确做法                                   | 错误做法
|-------------------------------------|------
| 打开 `foo.yaml` 文件。         | 打开文件 foo.yaml。
| 进入 `/content/en/docs/tasks` 目录。  | 进入 /content/en/docs/tasks 目录。
| 打开 `/data/args.yaml` 文件。 | 打开 /data/args.yaml 文件。

### 使用`代码`风格书写行内代码或命令{#use-code-style-for-inline-code-and-commands}

| 正确做法                          | 错误做法
|----------------------------|------
| 使用 `foo run` 命令创建 `Deployment`。 | 使用 "foo run" 命令创建 `Deployment`。
| 对于声明性管理，请使用 `foo apply`。 | 对于声明性管理，请使用 "foo apply"。

### 使用`代码`风格书写对象的字段名{#use-code-style-for-object-field-names}

| 正确做法                                            | 错误做法
|-----------------------------------------------------------------|------
| 在配置文件中设置 `ports` 字段。 | 在配置文件中设置 "ports" 字段。
| `rule` 字段的值是一个 `Rule` 对象。 | "rule" 字段的值是一个 `Rule` 对象。

### 字段 `title:` 的大写规则{#use-title-capitalization-for-title-front-matter}

在 front-matter 中 `title:` 字段大写规则为：大写除连词和介词外的所有单词首字母。
这与文档正文中的标题大写风格不同，见下面内容。

### 标题中仅将首字母大写{#only-capitalize-the-first-letter-of-headings}

仅将标题中第一个单词的首字母大写，专有名词或缩写除外。请注意，markdown 中 `title:` 注释的大小写规范。

| 正确做法                      | 错误做法
|------------------------|-----
|Configuring rate limits | Configuring Rate Limits
|Using Envoy for ingress | Using envoy for ingress
|Using HTTPS             | Using https

## 术语标准{#terminology-standards}

为了清晰起见，我们希望在本文档中一致地使用本节中的标准术语。

### Envoy

我们更喜欢使用 “Envoy”，因为它比 “proxy” 更具体，如果在整个文档中使用一致，则更容易引起共鸣。

同义词：

- "Envoy sidecar” - ok
- "Envoy proxy” - ok
- "The Istio proxy” - 最好避免使用，除非您正在谈论可能使用其他代理的高级方案。
- "Sidecar”  - 主要限于概念性文档
- "Proxy" - 仅在上下文明显的情况下使用

相关条款：

- Proxy agent  - 这是一个较小的基础结构组件，仅应出现在底层详细文档中。它不是专有名词。

### 其它{#miscellaneous}

| 正确做法              | 错误做法
|----------------|------
| load balancing | `load-balancing`
| multicluster   | `multi-cluster`
| addon          | `add-on`
| service mesh   | `Service Mesh`
| sidecar        | `side-car`, `Sidecar`
| Kubernetes     | `kubernetes`, `k8s`
| Bookinfo       | `BookInfo`, `bookinfo`
| Mixer          | `mixer`
| certificate    | `cert`
| configuration  | `config`
| delete         | `kill`

## 最佳实践{#best-practices}

### 使用现在时{#use-present-tense}

| 正确做法                           | 错误做法
|-----------------------------|------
| This command starts a proxy. | This command will start a proxy.

例外：确实需要通过使用将来时或过去时才能表达正确的含义时。这种例外极为罕见，应尽可能的避免。

### 使用主动句式{#use-active-voice}

| 正确做法                                         | 错误做法
|-------------------------------------------|------
| You can explore the API using a browser.   | The API can be explored using a browser.
| The YAML file specifies the replica count. | The replica count is specified in the YAML file.

### 使用简单直接的语言{#use-simple-and-direct-language}

使用简单直接的语言。避免使用不必要的短语，例如：“please”。

| 正确做法                          | 错误做法
|----------------------------|------
|To create a `ReplicaSet`, ... | In order to create a `ReplicaSet`, ...
|See the configuration file. | Please see the configuration file.
|View the Pods.              | With this next command, we'll view the Pods.

### 使用“您”称呼读者{address-the-reader-as-you}

| 正确做法                                     | 错误做法
|---------------------------------------|------
| 您可以通过 …… 创建 `Deployment`   | 我们将通过 …… 创建 `Deployment`
| 在前面的输出中，您可以看到…… | 在前面的输出中，我们可以看到……

### 创建语义清晰的链接{#create-useful-links}

链接有语义清晰也有不是最佳做法的。如：在 *此处* 或 *单击此处* 打开链接的常见做法就是不好的链接示例。
请查看[这篇出色的文章](https://medium.com/@heyoka/dont-use-click-here-f32f445d1021)，
其中解释了什么是好的超链接，并在创建或查看网站内容时牢记这些准则。

### 避免使用“我们”{#avoid-using-we}

在句子中使用“我们”可能会造成混淆，因为读者可能不知道他们是否属于您所描述的“我们”。

| 正确做法                                        | 错误做法
|------------------------------------------|------
| 1.4 版本中包括…                | 在 1.4 版本中，我们添加了…
| Istio 为 … 提供了一项新功能。 | 我们提供了一个新功能……
| 该页面教您如何使用 Pod。 | 在此页面中，我们将学习 Pod。

### 避免行话和成语{#avoid-jargon-and-idioms}

一些读者的母语不是英语，避免使用术语和习惯用语，以帮助他们更容易理解。

| 正确做法                    | 错误做法
|----------------------|------
| Internally, ...       | Under the hood, ...
| Create a new cluster. | Turn up a new cluster.

### 避免陈述未来{#avoid-statements-about-the-future}

避免做出承诺或暗示未来。如果您需要讨论 Alpha 功能，请将内容放在一个被标识为 Alpha 的标题下。

### 避免过时的声明{#avoid-statements-that-will-soon-be-out-of-date}

避免使用“当前”和“新”之类的词。今天的新功能可能在几个月后就不会被视为新功能。

| 正确做法                                  | 错误做法
|------------------------------------|------
| 在版本 1.4 中 …                |  在当前版本中 …
| 联合身份验证功能提供 …  | 新的联合身份验证功能提供了…

### 尽量减少使用标注{#minimize-use-of-callouts}

通过标注，您可以突出显示页面中的某些特定内容，但需要谨慎使用。标注旨在向用户提供特别提示，如果在整个站点中过度使用它们，
将降低其对读者的吸引力。

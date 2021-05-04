---
title: 风格指南
description: 介绍 Istio 文档所使用的风格规则。
weight: 11
aliases:
    - /zh/docs/welcome/contribute/style-guide.html
    - /zh/docs/reference/contribute/style-guide.html
keywords: [contribute]
---

Istio 文档所有的内容都必须 **清晰明了** 且 **易于理解**。我们根据 Google 开发者风格指南中的[重点](https://developers.google.com/style/highlights)和[通则](https://developers.google.com/style/tone)定义了标准。关于您贡献的内容是如何被审核、接受的，请参见[审核页面](/zh/about/contribute/review)获取详情。

您可以在此通过 Istio 特有的示例，找到 Istio 遵循的基本风格与实践指南的所有场景。

## 标题句首字母大写{#use-sentence-case-for-headings}

在您的文档中，为标题使用句首字母大写。即：仅将标题中第一个单词的首字母大写，专有名词或缩写除外。

| 正确做法                      | 错误做法
|------------------------|-----
|Configuring rate limits | Configuring Rate Limits
|Using Envoy for ingress | Using envoy for ingress
|Using HTTPS             | Using https

## front-matter 中 `title:` 字段的值使用首字母大写{#use-title-case-for-the-value-of-the-title-field-of-the-front-matter}

front-matter 中 `title:` 字段的文本必须使用首字母大小写。即：除连词和介词外，将每个单词的首字母大写。

## 使用现在时{#use-present-tense}

| 正确做法                           | 错误做法
|-----------------------------|------
| 命令启动代理服务器。 | 命令将启动代理服务器。

例外：确实需要通过使用将来时或过去时才能表达正确的含义时。这种例外极为罕见，应尽可能的避免。

## 使用主动句式{#use-active-voice}

| 正确做法                                         | 错误做法
|-------------------------------------------|------
| 您可以使用浏览器查询API。   | API可以使用浏览器被查询。
| YAML 指定了副本数量。 | 副本数量已被 YAML 指定。

## 使用简单直接的语言{#use-simple-and-direct-language}

使用简单直接的语言。避免使用不必要的短语，例如：“please”。

| 正确做法                          | 错误做法
|----------------------------|------
|创建 `ReplicaSet`, ... | 为了要创建 `ReplicaSet`, ...
|参见配置文件。 | 请参见配置文件。
|查看 Pods。              | 通过下一个命令，可查看 Pods。

## 使用“您”称呼读者{#address-the-reader-as-you}

| 正确做法                                     | 错误做法
|---------------------------------------|------
| 您可以通过 …… 创建 `Deployment`   | 我们将通过 …… 创建 `Deployment`
| 在前面的输出中，您可以看到…… | 在前面的输出中，我们可以看到……

## 创建语义清晰的链接{#create-useful-links}

链接有语义清晰也有不是最佳做法的。如：在 *此处* 或 *单击此处* 打开链接的常见做法就是不好的链接示例。
请查看[这篇出色的文章](https://medium.com/@heyoka/dont-use-click-here-f32f445d1021)，
其中解释了什么是好的超链接，并在创建或查看网站内容时牢记这些准则。

## 避免使用“我们”{#avoid-using-we}

在句子中使用“我们”可能会造成混淆，因为读者可能不知道他们是否属于您所描述的“我们”。

| 正确做法                                        | 错误做法
|------------------------------------------|------
| 1.4 版本中包括…                | 在 1.4 版本中，我们添加了…
| Istio 为 … 提供了一项新功能。 | 我们提供了一个新功能……
| 该页面教您如何使用 Pod。 | 在此页面中，我们将学习 Pod。

## 避免俚语和方言{#avoid-jargon-and-idioms}

一些读者的母语不是英语，避免使用术语和习惯用语，可用以帮助他们更轻松的理解。

| 正确做法                    | 错误做法
|----------------------|------
|内部地, ...       | 在里面, ...
|创建集群。 | 打开新的集群。
|首先, ...        | 开头, ...

## 避免陈述未来{#avoid-statements-about-the-future}

避免暗示或承诺未来。如果您需要讨论开发中的功能，请在标题下方添加一个样板，以便标识相应地信息。

### 避免过时的声明{#avoid-statements-that-will-soon-be-out-of-date}

避免使用“当前”和“新”之类的词。今天的新功能可能在几个月后就不会被视为新功能。

| 正确做法                                  | 错误做法
|------------------------------------|------
| 在版本 1.4 中 …                |  在当前版本中 …
| 联合身份验证功能提供 …  | 新的联合身份验证功能提供了…

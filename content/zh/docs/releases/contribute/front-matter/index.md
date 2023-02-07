---
title: 文章头部
description: 介绍了文档中使用的文章头及其可用字段。
weight: 6
keywords: [metadata, navigation, table-of-contents]
---

文章头部（front matter）是每个文件顶部用三点划线包裹的 YAML 代码，它为我们的内容提供了重要的管理选项。例如：文章头部允许我们确保现有链接对于已经完全移动或删除的页面继续有效。本页说明了 Istio 中文章头部目前可用的功能。

下面是一个文章头部的示例，其中所有必填字段都由占位符填充：

{{< text yaml >}}
---
title: <title>
description: <description>
weight: <weight>
keywords: [<keyword1>,<keyword2>,...]
aliases:
    - <previously-published-at-this-URL>
---
{{< /text >}}

您可以复制上面的示例，并在您的页面中使用相应值替换所有占位符。

## 必填字段{#required-front-matter-fields}

下表列举了所有的 **必填** 字段及其说明：

|字段                | 说明
|-------------------|------------
|`title`            | 该页面的标题。
|`description`      | 对其该页面内容的一个简单描述。
|`weight`           | 该页面相对于当前目录中其他页面的顺序。
|`keywords`         | 页面上的关键字。Hugo 根据此列表在页面末尾生成“相关内容”链接。
|`aliases`          | 页面以前发布过的 URL。有关此字段的详细信息，请参见下面的[重命名、移动或删除页面](#rename-move-or-delete-pages)。

### 重命名、移动或删除页面{#rename-move-or-delete-pages}

当您移动或完全删除页面时，必须确保指向这些页面的现有链接继续有效。文章头部中的 `aliases` 字段可帮助您满足此要求。在移动或删除页面之前，将现有路径添加到 `aliases` 字段中。Hugo 为我们的用户实现了从旧 URL 到新  URL 的自动重定向。

在 _target page_ （您想让用户访问的页面）上，将 _original page_ 的 `<path>` 添加到文章头部中，如下所示：

{{< text plain >}}
aliases:
    - <path>
{{< /text >}}

例如，您可以在以前的 `/zh/help/faq` 下找到我们的 FAQ 页面。为了使用户更方便的找到 FAQ 页面，我们将该页面上移了一个级别至 `/zh/faq/`，并对文章头部做了以下更改：

{{< text plain >}}
---
title: Frequently Asked Questions
description: Questions Asked Frequently.
weight: 13
aliases:
    - /zh/help/faq
---
{{< /text >}}

上面的更改允许所有用户通过 `https://istio.io/zh/faq/` 或者 `https://istio.io/zh/help/faq/` 都能访问到 FAQ 页面。

不仅是一个，该字段支持多个重定向，例如：

{{< text plain >}}
---
title: Frequently Asked Questions
description: Questions Asked Frequently.
weight: 13
aliases:
    - /zh/faq
    - /zh/faq2
    - /zh/faq3
---
{{< /text >}}

## 可选字段{#optional-front-matter-fields}

Hugo 支持非常多的文章头部字段，而此页面仅列举了在 istio.io 中实现的字段。

下表列举了最常用的 **可选** 字段：

|字段                | 描述
|-------------------|------------
|`linktitle`        | 短标题，常用于链接到页面。
|`subtitle`         | 主标题下方显示的副标题。
|`icon`             | 标题旁边显示图标的路径。
|`draft`            | 如果为 true，该页面不会出现在网站中。
|`skip_byline`      | 如果为 true，Hugo 不会在主标题下显示下划线。
|`skip_seealso`     | 如果为 true， Hugo 不会为该页面生成“相关内容”链接。

一些文章头部字段可用于控制自动生成的目录（ToC）。下表列举了这些字段并说明了如何使用：

|字段                 | 描述
|--------------------|------------
|`skip_toc`          | 如果为 true，Hugo 不会为该页面生成目录。
|`force_inline_toc`  | 如果为 true，Hugo 会强制在文本中插入自动生成的目录，而不是右侧的边栏。
|`max_toc_level`     | 设置目录（ToC）中使用的标题级别。值可以从 2 到 6。
|`remove_toc_prefix` | Hugo 从目录中每个条目的前缀中删除此字符串。

某些文章头部字段仅适用于所谓的 _bundle page_ 。您可以辨别 _bundle page_ ，因为它们的文件名都是以下划线 `_` 开头，例如： `_index.md`。在 Istio 中，我们使用 _bundle page_ 作为我们的部分着陆页面。下表列举了与 _bundle page_ 相关的文章头部字段。

|字段                   | 描述
|----------------------|------------
|`skip_list`           | 如果为 true，Hugo 不会自动生成该部分页面的内容块。
|`simple_list`         | 如果为 true，Hugo 使用一个简单列表列出该部分页面的自动生成内容。
|`list_below`          | 如果为 true，Hugo 会将自动生成的内容追加到手动编写的内容后面。
|`list_by_publishdate` | 如果为 true，Hugo 会按照 `publishdate` 而不是 `weight`，对自动生成的内容进行排序。

类似的，某些文章头部字段仅适用于博客文章。下表列举了这些字段：

|字段              | 描述
|-----------------|------------
|`publishdate`    | 博客的原始发布日期
|`last_update`    | 最近一次进行重大修改的日期
|`attribution`    | 可选的，作者的姓名
|`twitter`        | 可选的，作者的 Twitter
|`target_release` | 此博客内容中所使用的 Istio 版本。通常，该值是在创作或更新该博客时，当时最新的主要 Istio 版本。

---
title: 使用 Shortcode 
description: 介绍可用的 shortcode 及其用法。
weight: 8
aliases:
    - /zh/docs/welcome/contribute/writing-a-new-topic.html
    - /zh/docs/reference/contribute/writing-a-new-topic.html
    - /zh/about/contribute/writing-a-new-topic.html
    - /zh/create
keywords: [contribute]
---

Hugo 的 shortcode 是具有特定语法的特殊占位符，您可以将其添加到内容中以创建动态内容体验，例如选项卡、图片、图标、指向另一个页面的链接以及特殊内容布局。

本页面介绍了可用的 shortcode 及其用法。

## 添加图片{#add-images}

将图片文件跟 markdown 文件放在相同的目录。为了增强其可读性，以及方便本地化，首选的图片格式是 SVG。下面的示例展示了添加带有图片的 shortcode ，所需的必填字段：

{{< text html >}}
{{</* image width="75%" ratio="45.34%"
    link="./<image.svg>"
    caption="<图片下方显示的标题>"
    */>}}
{{< /text >}}

`link` 和 `caption` 字段是必填字段，shortcode 还支持可选字段，例如：

{{< text html >}}
{{</* image width="75%" ratio="45.34%"
    link="./<image.svg>"
    alt="<使用屏幕阅读器且图片加载失败时使用的备用文本>"
    title="<鼠标悬停在图片上时显示的文本>"
    caption="<图片下方显示的标题>"
    */>}}
{{< /text >}}

如果你没有填写 `alt` 字段，Hugo 会自动使用 `title` 的文本。如果你没有填写 `title` 字段，Hugo 会自动使用 `caption` 的文本。

`width` 字段设置图像相对于周围文本的大小，默认为 100％。

`Ratio` 字段设置图像相对于其宽度的高度。Hugo 会自动为目录中的图片计算该值。但是，对于外部图片，您必须手动为其计算。将 `ratio` 的值设置为 `([图片高度]/[图片宽度]) * 100`。

## 添加图标{#add-icons}

您可以将通用图标嵌入到具有以下内容的内容中：

{{< text markdown >}}
{{</* warning_icon */>}}
{{</* idea_icon */>}}
{{</* checkmark_icon */>}}
{{</* cancel_icon */>}}
{{</* tip_icon */>}}
{{< /text >}}

图标会呈现在文本中，例如：{{< warning_icon >}}、{{< idea_icon >}}、{{< checkmark_icon >}}、{{< cancel_icon >}} 以及 {{< tip_icon >}}。

## 添加指向其它页面的链接{#add-links-to-other-pages}

根据目标的不同，Istio 文档支持三种类型的链接。每种类型使用不同的语法来表示链接目标。

- **外部链接**。用于指向 Istio 在 GitHub 的仓库，或者其它的站外链接。使用标准的 Markdown 语法表示 URL。当你引用的文件在互联网上时，请尽量使用 HTTPS 协议，例如：

    {{< text markdown >}}
    [链接的描述文本](https://mysite/myfile.html)
    {{< /text >}}

- **相对链接**。用于指向与当前文件位于同一级，或者更深层级的目标。相对链接以点 `.` 开头，例如：

    {{< text markdown >}}
    [链接到同级或子页面](./sub-dir/child-page.html)
    {{< /text >}}

- **绝对链接**。用于指向当前页面之外，但位于 Istio 站点之内页面的目标。绝对路径以斜线 `/` 开头，例如：

    {{< text markdown >}}
    [链接到关于页面](/zh/about/)
    {{< /text >}}

无论使用何种类型，链接都不会指向内容的 `index.md` 文件，而是指向包含 `index.md` 的那个目录。

### 添加指向 GitHub 内容的链接{#add-links-to-content-on-GitHub}

有几种方法可以引用 GitHub 的内容或文件：

- **{{</* github_file */>}}**，用于引用 GitHub 中的单个文件（例如 yaml 文件）。该 shortcode 会渲染为 `https://raw.githubusercontent.com/istio/istio*`，例如：

    {{< text markdown >}}
    [liveness]({{</* github_file */>}}/samples/health-check/liveness-command.yaml)
    {{< /text >}}

- **{{</* github_tree */>}}**，用于引用 GitHub 中的一个目录。该 shortcode 会渲染为 `https://github.com/istio/istio/tree*`，例如：

    {{< text markdown >}}
    [httpbin]({{</* github_tree */>}}/samples/httpbin)
    {{< /text >}}

- **{{</* github_blob */>}}**，用于引用 GitHub 中的单个文件，该 shortcode 会渲染为 `https://github.com/istio/istio/blob*`，例如：

    {{< text markdown >}}
    [RawVM MySQL]({{</* github_blob */>}}/samples/rawvm/README.md)
    {{< /text >}}

上面的 shortcode 会根据文档当前的目标分支，生成指向 GitHub 中对应分支的链接。要查看当前目标分支的名称，可以使用 `{{</* source_branch_name */>}}` shortcode 来获取当前目标分支的名称。

## 版本信息{#version-information}

想要通过从网站检索，在您的内容中显示 Istio 的当前版本，请使用以下 shortcode ：

- `{{</* istio_version */>}}`，渲染结果为：{{< istio_version >}}
- `{{</* istio_full_version */>}}`，渲染结构为：{{< istio_full_version >}}

## 术语表{#glossary-terms}

当您在页面中介绍一个 Istio 术语时，贡献补充条款要求您将该术语包含在 `glossary` 中，并使用 shortcode `{{</* gloss */>}}` 标记它的第一个实例。shortcode 会对其进行特殊渲染，读者点击该术语，可以在弹出的窗口中获取该术语的定义。例如：

{{< text markdown >}}
Mixer 使用 {{</*gloss*/>}}adapters{{</*/gloss*/>}} 与后端进行交互。
{{< /text >}}

渲染结果如下：

Mixer 使用 {{< gloss >}}adapters{{< /gloss >}} 与后端进行交互。

如果你想在您的文本中使用该术语的其它形式，您依然可以使用该 shortcode 。要修改显示文本，只需在 shortcode 中包含对应的术语条目即可。例如：

{{< text markdown >}}
Mixer 使用 {{</*gloss adapters*/>}}适配器{{</*/gloss*/>}} 与后端进行交互。
{{< /text >}}

术语 `适配器` 定义的渲染结果如下：

Mixer 使用 {{< gloss adapters >}}适配器{{</ gloss >}} 与后端进行交互。

## 标注{#callouts}

想要强调部分内容，可以将它们设置为警告，提示，建议或引用。所有标注都使用了非常相似的 shortcode ：

{{< text markdown >}}
{{</* warning */>}}
这是一个重要的警告
{{</* /warning */>}}

{{</* idea */>}}
这是一个好点子
{{</* /idea */>}}

{{</* tip */>}}
这是来自专家的有用建议
{{</* /tip */>}}

{{</* quote */>}}
这是从某处引用的内容
{{</* /quote */>}}
{{< /text >}}

上面的 shortcode 渲染结果如下：

{{< warning >}}
这是一个重要的警告
{{< /warning >}}

{{< idea >}}
这是一个好点子
{{< /idea >}}

{{< tip >}}
这是来自专家的有用建议
{{< /tip >}}

{{< quote >}}
这是从某处引用的内容
{{< /quote >}}

应该谨慎地使用标注。每种类型的标注都有特定的用途，过度使用会适得其反。通常，每个文件最多只能包含一个标注。

## 使用样板文本{#use-boilerplate-text}

要想在保持内容单一来源的情况下重用内容，请使用样板 shortcode 。要将样板文本嵌入任何内容文件中，请使用 `boilerplate` shortcode ，如下所示：

{{< text markdown >}}
{{</* boilerplate example */>}}
{{< /text >}}

下面的 shortcode 包含了 `/content/zh/boilerplates/` 目录下 `example.md` 文件的内容：

{{< boilerplate example >}}

该示例表明，您需要在想要插入样本内容的位置，填写 Markdown 的文件名。您可以在 `/content/zh/boilerplates` 目录中找到现有的全部样板文件。

## 使用选项卡{#use-tabs}

要显示具有多个选项或格式的内容，请使用选项卡和选项卡集。其可用于显示：

- 不同平台的等效命令
- 不同语言的等效代码
- 替代的配置

要添加选项卡式内容，请组合使用 shortcode `tabset` 和 `tabs`，例如：

{{< text markdown >}}
{{</* tabset category-name="platform" */>}}

{{</* tab name="One" category-value="one" */>}}
ONE
{{</* /tab */>}}

{{</* tab name="Two" category-value="two" */>}}
TWO
{{</* /tab */>}}

{{</* tab name="Three" category-value="three" */>}}
THREE
{{</* /tab */>}}

{{</* /tabset */>}}
{{< /text >}}

上面的 shortcode ，渲染效果如下：

{{< tabset category-name="platform" >}}

{{< tab name="One" category-value="one" >}}
ONE
{{< /tab >}}

{{< tab name="Two" category-value="two" >}}
TWO
{{< /tab >}}

{{< tab name="Three" category-value="three" >}}
THREE
{{< /tab >}}

{{< /tabset >}}

每个选项卡的 `name` 属性的值就是该选项卡显示的文本。在每个选项卡内部，支持绝大部分的 Markdown 语法，但是选项卡有一些[限制](#tab-limitations)。

`category-name` 和 `category-value` 属性是可选的，它们让选定的标签可以跨页面存储。例如，访问者选择一个选项卡，并使用给定的名称和值自动保存他们的选择。如果有多个选项卡集使用了相同的 `category-name` 和 `category-value`，则它们的选择将自动跨页面同步。当站点中有许多具有相同类型格式的选项卡集时，此功能特别有用。

例如，有多个选项卡集都提供了 `GCP`、`BlueMix` 和 `AWS` 三个选项。您可以将 `category-name` 属性的值设置为 `environment`，将 `category-value` 属性的值设置为`gcp`，接着是 `bluemix` 和 `aws`。然后，当读者在某一个选项卡集中做出选择时，网站上所有相同的选项卡集都会自动做出相同的选择。

### 选项卡限制{#tab-limitations}

您可以在选项卡中使用几乎所有的 Markdown 语法，但以下情况除外：

- *标题*。选项卡中的标题会出现在目录中，但是单击目录中的链接不会自动跳到选项卡的位置。

- *嵌套选项卡集*。不要嵌套选项卡集。这么做会导致阅读体验很糟糕，并可能导致严重的混乱。

## 使用横幅和标签{#use-banners-and-stickers}

要通告即将发生的事件或发布新消息，您可以按顺序自动地将对时间敏感的横幅和标签（banners and stickers）添加至生成的网站。我们为通告实现了以下 shortcode ：

- **倒计时标签**：它会显示现在距离事件发生还有多少时间，例如：“距 3 月 30 日 ServiceMeshCon 还剩 37 天”。标签在活动开始前会对读者产生视觉影响，应谨慎使用。

- **横幅**：它们向读者展示即将、正在或已经发生的重大事件的重要信息。例如，“Istio 1.5 已发布，请立即下载！”或“ 3 月 30 日加入我们的 ServiceMeshCon”。横幅是活动期间向读者显示的全屏切片。

要创建横幅和标签，您可以在 `events/banners` 或 `events/stickers` 目录中创建 Markdown 文件。每个事件一个 Markdown 文件，并使用专用的 front-matter 字段来控制其行为。下表列举了可用的字段：

<table>
    <thead>
        <tr>
            <th>字段</th>
            <th>描述</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>title</code></td>
            <td>事件名称。不会显示在网站上，仅用于诊断消息。</td>
        </tr>
        <tr>
            <td><code>period_start</code></td>
            <td>以 <code>YYYY-MM-DD</code> 的格式显示事件的开始日期。
            除了日期以外，其值还可以是 <code>latest_release</code>，这会自动使用最新的已知的 Istio 版本的发布日期作为开始日期。
            该功能对于创建 “Istio x.y.z 刚刚发布” 之类的横幅很有用。
            </td>
        </tr>
        <tr>
            <td><code>period_end</code></td>
            <td>以 <code>YYYY-MM-DD</code> 的格式显示项目的结束日期。此值与下面的 <code>period_duration</code> 互斥。
            </td>
        </tr>
        <tr>
            <td><code>period_duration</code></td>
            <td>向用户显示该事件的持续天数（基于开始日期）。此值与上面的 <code>period_end </code>互斥。
            </td>
        </tr>
        <tr>
            <td><code>max_impressions</code></td>
            <td>在事件期间向用户显示内容的次数。值为 3 表示在此期间用户的前三次访问将显示内容，并在随后的页面加载时将隐藏该内容。值为 0 或省略该字段将导致该内容在此期间的所有页面访问中都显示内容。
            </td>
        </tr>
        <tr>
            <td><code>timeout</code></td>
            <td>内容在给定页面上对用户可见的时间。经过指定长度的时间后，该事件将从页面中删除。
            </td>
        </tr>
        <tr>
            <td><code>link</code></td>
            <td>您可以指定一个 URL，它将整个事件变成一个可点击的链接。当用户点击该链接时，该事件将不再显示。这里可以使用特殊值 `latest_release` 让链接指向当前最新版本的公告页面。
            </td>
        </tr>
    </tbody>
</table>

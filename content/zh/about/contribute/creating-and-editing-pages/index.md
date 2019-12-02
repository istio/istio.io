---
title: 创建和编辑页面
description: 介绍创建和维护文档页面的机制。
weight: 10
aliases:
    - /zh/docs/welcome/contribute/writing-a-new-topic.html
    - /zh/docs/reference/contribute/writing-a-new-topic.html
    - /zh/about/contribute/writing-a-new-topic.html
    - /zh/create
keywords: [contribute]
---

此页面介绍了如何创建、测试和维护 Istio 文档主题。

## 开始之前{#before-you-begin}

在开始编写 Istio 文档之前，首先需要创建一个 Istio 文档存储库的分支正如[使用 GitHub 工作](/zh/about/contribute/github/)中所述。

## 选择页面类型{#choosing-a-page-type}

在准备编写一个新主题时，请考虑您的内容最适合以下哪种页面类型：

<table>
  <tr>
    <td>概念</td>
    <td>概念页面解释了 Istio 的一些重要概念。例如，概念页面可能会描述 Mixer 的配置模型并解释其中的一些细微之处。通常，概念页面不包括具体的操作步骤，而是提供指向任务的链接。</td>
  </tr>

  <tr>
    <td>参考</td>
    <td>参考页面提供了诸如 API 参数、命令行选项、配置设置和过程之类的详尽列表。</td>
  </tr>

  <tr>
    <td>示例</td>
    <td>示例页面描述了一个完整工作的独立示例，突出显示了一组特定功能。示例必须具有易于遵循的设置和使用说明，以便用户可以自己快速运行示例并尝试更改示例以探索系统。测试和维护示例以获得技术准确性。</td>
  </tr>

  <tr>
    <td>任务</td>
    <td>任务页面显示如何执行单个操作，通常通过提供一系列简短的步骤。任务页面具有最少的解释，但通常提供指向提供相关背景和知识的概念主题的链接。测试和维护任务以确保技术准确性。</td>
  </tr>

  <tr>
    <td>安装</td>
    <td>安装页面类似于任务页面，但它侧重于安装活动。测试和维护安装页面以确保技术准确性。</td>
  </tr>

  <tr>
    <td>博客文章</td>
    <td>
      博客文章是关于 Istio 或与之相关的产品和技术的文章。通常，博客属于以下 3 个类别之一：
      <ul>
      <li>详细介绍了作者使用和配置 Istio 的经验，特别是能够表达新颖体验或观点的那些博客。</li>
      <li>突出显示了 Istio 功能的博客。</li>
      <li>详细介绍如何使用 Istio 完成任务或实现特定用例的文章。与任务和示例不同，博客文章的技术准确性在发布后不会得到维护和测试。</li>
      </ul>
    </td>
  </tr>

  <tr>
    <td>新闻条目</td>
    <td>
      新闻条目是有关 Istio 及其相关事件的及时文章。新闻条目通常会宣布新版本或即将发生的事件。
    </td>
  </tr>

  <tr>
    <td>FAQ</td>
    <td>
      FAQ 条目用于快速解答常见的客户问题。答案通常不会引入任何新概念，而是仅侧重于一些实用的建议或见解，并提供了供用户了解更多信息的指向主文档的链接。
    </td>
  </tr>

  <tr>
    <td>运维指南</td>
    <td>
      有关解决在实际环境中运行 Istio 时遇到的特定问题的实用解决方案。
    </td>
  </tr>
</table>

## 命名主题{#naming-a-topic}

为您的主题选择一个具有您希望搜索引擎查找的关键字的标题。为你的主题创建一个使用标题中的单词、并用连字符分隔而且所有字母均小写的文件名。

## 设置文档的元数据信息{#updating-front-matter}

每个文档文件都需要从头开始写[元数据信息](https://gohugo.io/content-management/front-matter/)。元数据信息是介于两个 YAML 块之间通过 3 个“-”分割的信息。下面就是你需要填写的元数据信息:

{{< text yaml >}}
---
title: <title>
description: <description>
weight: <weight>
keywords: [keyword1,keyword2,...]
---
{{< /text >}}

在新的 markdown 文件的开头复制上面的内容并更新信息字段。可用的字段如下：

|字段               | 描述
|-------------------|------------
|`title`            | 页面短标题
|`linktitle`        | 页面的备用标题（通常较短），在侧栏中用于引用页面
|`subtitle`         | 可选子标题，显示在主标题下方
|`description`      | 关于页面内容的单行描述
|`icon`             | 图像文件的可选路径，该路径显示在主标题旁边
|`weight`           | 一个整数，用于确定此页面相对于同一目录中其他页面的排序顺序
|`keywords`         | 描述页面的关键字数组，用于创建“另请参见”链接的网络
|`draft`            | 如果为 true，则阻止页面显示在任何导航区域中
|`aliases`          | 有关此项目的详细信息，请参见下面的[重命名，移动或删除页面](#renaming-moving-or-deleting-pages)。
|`skip_byline`      | 将此属性设置为 true 可以防止页面在主标题下带有下划线
|`skip_seealso`     | 将此设置为 true 可以防止页面为其生成“另请参见”部分

一些字段控制大多数页面上自动生成的目录：

|字段                | 描述
|--------------------|------------
|`skip_toc`          | 将其设置为 true 可以防止页面为其生成目录
|`force_inline_toc`  | 将此属性设置为 true 可强制将生成的目录插入到文本中，而不是在边栏中
|`max_toc_level`     | 设置为 2、3、4、5 或 6 表示要在目录中显示的最大标题级别
|`remove_toc_prefix` | 将其设置为一个字符串，该字符串将从目录中每个条目的开头删除（如果存在）

一些针对章节页面的属性字段（例如，用于文章排版的文件 `_index.md`）：

|字段                  | 描述
|----------------------|------------
|`skip_list`           | 将此设置为 true 可以防止在部分页面上自动生成内容
|`simple_list`         | 将此属性设置为 true 可将简单的列表布局而不是图库布局用于节页面的自动生成的内容
|`list_below`          | 将此属性设置为 true 可将自动生成的内容插入到手动编写的内容下方的部分页面中
|`list_by_publishdate` | 将此属性设置为 true 可以按发布日期而不是按页面权重对页面上生成的内容进行排序

还有一些专门用于博客文章的元数据字段：

|字段            | 描述
|----------------|------------
|`publishdate`   | 帖子原始发表日期
|`last_update`   | 上次重大修改的日期
|`attribution`   | 帖子作者的姓名（可选）
|`twitter`       | 帖子作者的 Twitter 账号（可选）
|`target_release`| 发布此博客时要牢记这一点（通常是创作或更新该博客时当前的主要 Istio 版本）

## 添加图片{#adding-images}

将图片文件与 markdown 文件放在同一目录中。首选的图片格式是 SVG。在 markdown 文件中，使用以下代码添加图片：

{{< text html >}}
{{</* image width="75%" ratio="45.34%"
    link="./myfile.svg"
    alt="Alternate text to display when the image can't be loaded"
    title="A tooltip displayed when hovering over the image"
    caption="A caption displayed under the image"
    */>}}
{{< /text >}}

`link` 和 `caption` 是必填项，其他为可选。

如果没有提供 `title` 值，它将默认与 `caption` 的值相同。如果没有提供 `alt` 值，它就会默认为 `title` 或 `caption`（如果 title 没有定义）的值。

`width` 表示图像相对于周围文本使用的空间百分比。如果未指定该值，则默认为100％。

`ratio` 表示图像高度与图像宽度之比。该值是针对任一本地图像内容自动计算的，但是在引用外部图像内容时必须手动计算。在这种情况下，比率应设置为（图像高度/图像宽度）\* 100。

## 添加图标{#adding-icons}

您可以使用以下方法在内容中嵌入一些常用图标：

{{< text markdown >}}
{{</* warning_icon */>}}
{{</* idea_icon */>}}
{{</* checkmark_icon */>}}
{{</* cancel_icon */>}}
{{</* tip_icon */>}}
{{< /text >}}

看起来像 {{< warning_icon >}}、{{< idea_icon >}}、{{< checkmark_icon >}}、{{< cancel_icon >}} 和 {{< tip_icon >}} 这样。

## 链接到其他页面{#linking-to-other-pages}

文档中可以包含三种类型的链接。每种方法都使用不同的方式来指示链接目标：

1. **互联网链接**。您使用经典的 URL 语法（最好与 HTTPS 协议一起使用）来引用 Internet 上的文件：

    {{< text markdown >}}
    [看这里](https://mysite/myfile.html)
    {{< /text >}}

1. **相对链接**。您可以使用以句点开头的相对链接来引用与当前文件处于同一级别或站点层次结构中以下的任何内容：

    {{< text markdown >}}
    [看这里](./adir/anotherfile.html)
    {{< /text >}}

1. **绝对链接**。您可以使用以 `/` 开头的绝对链接来引用当前层次结构之外的内容：

    {{< text markdown >}}
    [看这里](/zh/docs/adir/afile/)
    {{< /text >}}

### GitHub{#GitHub}

有几种方法可以从 GitHub 引用文件：

- **{{</* github_file */>}}** 是您在 GitHub 中引用单个文件（例如 yaml 文件）的方式。这产生了一个链接指向 `https://raw.githubusercontent.com/istio/istio*`

    {{< text markdown >}}
    [liveness]({{</* github_file */>}}/samples/health-check/liveness-command.yaml)
    {{< /text >}}

- **{{</* github_tree */>}}** 是您在 GitHub 中引用目录树的方式。这产生了一个链接指向 `https://github.com/istio/istio/tree*`

    {{< text markdown >}}
    [httpbin]({{</* github_tree */>}}/samples/httpbin)
    {{< /text >}}

- **{{</* github_blob */>}}** 是您在 GitHub 源中引用文件的方式。这产生了一个链接指向 `https://github.com/istio/istio/blob*`

    {{< text markdown >}}
    [RawVM MySQL]({{</* github_blob */>}}/samples/rawvm/README.md)
    {{< /text >}}

相对于文档当前对应的分支，以上注释产生指向 GitHub 中相应分支的链接。如果您需要手动构建 URL，可以使用 `{{</* source_branch_name */>}}` 来获取当前目标分支的名称。

## 版本信息{#version-information}

您可以使用 `{{</* istio_version */>}}` 或 `{{</* istio_full_version */>}}`（分别呈现为 {{< istio_version >}} 和 {{< istio_full_version >}}）获得网站描述的当前 Istio 版本。

`{{</* source_branch_name */>}}` 扩展为网站所对应的 `istio/istio` GitHub 仓库的分支名称，这呈现为 {{< source_branch_name >}}。

## 嵌入预格式化的块{#embedding-preformatted-blocks}

您可以使用 `text` 模块嵌入预格式化的内容块：

{{< text markdown >}}
{{</* text plain */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

上面产生这种输出：

{{< text plain >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

您必须在预格式化的块中指示内容的语法。上方代码块被标记为 `plain`，表示不应对该块应用语法渲染。与上面使用同样的代码块，但现在使用 Go 语言语法进行了注解：

{{< text markdown >}}
{{</* text go */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

渲染效果如下：

{{< text go >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

支持的语法有 `plain`、`markdown`、`yaml`、`json`、`java`、`javascript`、`c`、`cpp`、`csharp`、`go`、`html`、`protobuf`、`perl`、`docker`、和 `bash`。

### 命令行{#command-lines}

显示一个或多个 bash 命令行时，您可以以 $ 作为每行命令的开头 ：

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello"
{{</* /text */>}}
{{< /text >}}

渲染后的效果如下：

{{< text bash >}}
$ echo "Hello"
{{< /text >}}

您可以根据需要设置任意数量的命令行，但是只能识别出一小部分输出。

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{</* /text */>}}
{{< /text >}}

渲染后的效果如下：

{{< text bash >}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{< /text >}}

您还可以在命令行中使用行继续：

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{</* /text */>}}
{{< /text >}}

渲染后的效果如下：

{{< text bash >}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{< /text >}}

默认情况下，使用 `plain` 语法处理输出部分。如果输出使用众所周知的语法，则可以对其进行指定并为其着色。这对于 YAML 或 JSON 输出尤其常见：

{{< text markdown >}}
{{</* text bash json */>}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{</* /text */>}}
{{< /text >}}

渲染后的效果如下：

{{< text bash json >}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{< /text >}}

### 扩展形式{#expanded-form}

要使用以下各节中描述的用于预格式化内容的更高级功能，必须使用 `text` 序列的扩展形式，而不是到目前为止显示的简化形式。扩展形式使用普通的HTML属性：

{{< text markdown >}}
{{</* text syntax="bash" outputis="json" */>}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{</* /text */>}}
{{< /text >}}

可用的属性是：

| 属性         | 描述
|--------------|------------
|`file`        | 在预格式化块中显示的文件的路径。
|`url`         | 在预格式化块中显示的文档的URL。
|`syntax`      | 预格式化块的语法。
|`outputis`    | 当语法为 `bash` 时，它指定命令输出的语法。
|`downloadas`  | 用户[下载预格式化的块](#download-name)时使用的默认文件名。
|`expandlinks` | 是否在预格式化的块中扩展 [GitHub 文件引用](#links-to-GitHub-files)。
|`snippet`     | 从预格式化块中提取的内容[片段](#snippets)的名称。
|`repo`        | 用于 [GitHub 链接](#links-to-GitHub-files)的存储库，嵌入到预格式化的块中。

### 内联与导入内容{#inline-vs-imported-content}

到目前为止，您已经看到了内联预格式化内容的示例，但是也可以从文档存储库中的文件或从互联网上的任意 URL 导入内容。为此，您使用 `text_import` 序列。

您可以将 `text_import` 与 `file` 属性一起使用，以引用文档存储库中的文件：

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

渲染后的效果如下：

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

您可以通过类似的方式动态地从互联网提取内容，但是使用 `url` 属性而不是 `file` 属性。这是相同的文件，但是是动态地从URL检索的，而不是静态地引入 HTML 的：

{{< text markdown >}}
{{</* text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

产生的结果如下：

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" >}}

如果文件来自其他原始站点，则应在该站点上启用 CORS。请注意，此处可以使用 GitHub 原始内容网站（`raw.githubusercontent.com`）。

### 下载名称{#download-name}

您可以使用 `downloadas` 属性控制用户选择下载预格式化内容时浏览器使用的名称。例如：

{{< text markdown >}}
{{</* text syntax="go" downloadas="hello.go" */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

如果您未指定下载名称，则内联内容将根据当前页面的标题自动导出，下载内容的名称将根据文件名称或 URL 自动导出。

### 链接到 GitHub 文件{#links-to-GitHub-files}

如果您预先格式化的内容引用了 Istio 的 GitHub 存储库中的文件，则可以在文件的相对路径名周围加上一对 @ 符号。这些指示路径应呈现为来自 GitHub 当前分支的文件链接。例如：

{{< text markdown >}}
{{</* text bash */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

渲染后的效果如下：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

通常，链接将指向 `istio/istio` 存储库的当前发行版分支。如果您想要一个指向其他 Istio 存储库的链接，则可以使用 `repo` 属性：

{{< text markdown >}}
{{</* text syntax="bash" repo="operator" */>}}
$ cat @README.md@
{{</* /text */>}}
{{< /text >}}

渲染后的效果如下：

{{< text syntax="bash" repo="operator" >}}
$ cat @README.md@
{{< /text >}}

如果您的预格式化内容碰巧将 @ 符号用于其他内容，则可以使用 `expandlinks` 属性关闭链接扩展：

{{< text markdown >}}
{{</* text syntax="bash" expandlinks="false" */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

### 片段{#snippets}

使用导入的内容时，可以使用_命名的片段_（代表文件的各个部分）来控制呈现内容的哪些部分。您可以使用 `$snippets` 批注和成对的 `$endsnippet` 批注在文件中声明代码段。两个注释之间的内容代表代码段。例如，您可能有一个文本文件，如下所示：

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

然后在 markdown 文件中，您可以使用 `snippet` 属性引用特定的代码段，例如：

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

渲染后的效果如下：

{{< text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

在文本文件中，代码段可以指示代码段内容的语法，对于 bash 语法，代码段可以包括输出的语法。例如：

{{< text plain >}}
$snippet MySnippetFile.txt syntax="bash" outputis="json"
{{< /text >}}

## 术语表{#glossary-terms}

在页面中首次引入专用的 Istio 术语时，希望在术语表中对其进行注释。这将产生特殊的渲染，邀请用户单击该术语以获取带有定义的弹出窗口。

{{< text markdown >}}
Mixer 使用{{</*gloss*/>}}适配器{{</*/gloss*/>}}来连接后端。
{{< /text >}}

效果如下：

Mixer 使用{{<gloss>}}适配器{{</gloss>}}来连接后端。

如果页面上显示的术语与词汇表中的条目不完全匹配，则可以指定替代项：

{{< text markdown >}}
Mixer 使用{{</*gloss 适配器*/>}}adapter{{</*/gloss*/>}}来连接后端。
{{< /text >}}

which looks like:

Mixer 使用 {{<gloss 适配器>}}adapter{{</gloss>}} 来连接后端。

因此，即使词汇表条目用于**适配器**，也可以在文本中使用**适配器**的英文形式 **adapter**。

## 标注{#callouts}

您可以通过突出显示警告、提示、技巧和引号来特别关注内容块：

{{< text markdown >}}
{{</* warning */>}}
这是一个重要的警告
{{</* /warning */>}}

{{</* idea */>}}
这是一个好主意
{{</* /idea */>}}

{{</* tip */>}}
这是专家的有用提示
{{</* /tip */>}}

{{</* quote */>}}
这是源自某处的引用
{{</* /quote */>}}
{{< /text >}}

which looks like:

{{< warning >}}
这是一个重要的警告
{{< /warning >}}

{{< idea >}}
这是一个好主意
{{< /idea >}}

{{< tip >}}
这是专家的有用提示
{{< /tip >}}

{{< quote >}}
这是源自某处的引用
{{< /quote >}}

请谨慎使用这些标注。标注旨在向用户提供特别提示，并且在整个站点中过度使用它们可以抵消其特别吸引人的性质。

## 嵌入样板文字{#embedding-boilerplate-text}

您可以使用 `boilerplate` 序列将通用样板文本嵌入到任何 markdown 输出中：

{{< text markdown >}}
{{</* boilerplate example */>}}
{{< /text >}}

效果如下：

{{< boilerplate example >}}

您提供了要在当前位置插入的样板文件的名称。可用的样板位于 `boilerplates` 目录中。样板只是正常的 markdown 文件。

## 使用标签{#using-tabs}

如果您要以多种格式显示某些内容，则使用选项卡集并以不同的选项卡显示每种格式会很方便。要插入选项卡式内容，请结合使用 `tabset` 和 `tabs` 注解：

{{< text markdown >}}
{{</* tabset cookie-name="platform" */>}}

{{</* tab name="One" cookie-value="one" */>}}
一
{{</* /tab */>}}

{{</* tab name="Two" cookie-value="two" */>}}
二
{{</* /tab */>}}

{{</* tab name="Three" cookie-value="three" */>}}
三
{{</* /tab */>}}

{{</* /tabset */>}}
{{< /text >}}

产生如下输出：

{{< tabset cookie-name="platform" >}}

{{< tab name="One" cookie-value="one" >}}
一
{{< /tab >}}

{{< tab name="Two" cookie-value="two" >}}
二
{{< /tab >}}

{{< tab name="Three" cookie-value="three" >}}
三
{{< /tab >}}

{{< /tabset >}}

每个选项卡的 `name` 属性包含要为该选项卡显示的文本。标签的内容几乎可以是任何常见的 markdown 格式。

可选的 `cookie-name` 和 `cookie-value` 属性允许选项卡设置在访问页面时保持粘性。当用户选择一个选项卡时，该 cookie 将自动以给定的名称和值保存。如果多个选项卡集使用相同的 cookie 名称和值，则它们的设置将在页面之间自动同步。当站点中有许多标签集具有相同类型的格式时，此功能特别有用。

例如，如果许多选项卡集用于表示 `GCP`、`BlueMix` 和 `AWS` 之间的选择，则它们都可以使用环境的 cookie 名称以及 `gcp`、`bluemix` 和 `aws` 的值。 当用户在一页中选择一个选项卡时，等效选项卡将自动在任何其他选项卡集中选择。

### 限制{#limitations}

除了以下各项，您几乎可以在标签中使用任何 markdown 语法：

- **没有标题**。选项卡中的标题将出现在目录中，但是单击目录中的条目将不会自动选择选项卡。

- **没有嵌套的标签集**。不要尝试，这太可怕了。

## 重命名、移动或删除页面{#renaming-moving-or-deleting-pages}

如果移动页面或将其完全删除，则应确保用户可能必须与这些页面的现有链接继续起作用。您可以通过添加别名来做到这一点，这将使用户自动从旧 URL 重定向到新 URL。

在作为重定向**目标**的页面（您希望用户登陆的页面）中，您只需在元数据中添加以下内容：

{{< text plain >}}
aliases:
    - <path>
{{< /text >}}

例如

{{< text plain >}}
---
title: 经常问的问题
description: 经常问的问题。
weight: 12
aliases:
    - /zh/help/faq
---
{{< /text >}}

将上述内容保存在 `faq/_index.md` 页面中后，用户将可以通过正常访问 `istio.io/faq/` 以及 `istio.io/help/faq/` 来访问该页面。

您还可以添加许多重定向，如下所示：

{{< text plain >}}
---
title: 经常问的问题
description: 经常问的问题。
weight: 12
aliases:
    - /zh/faq
    - /zh/faq2
    - /zh/faq3
---
{{< /text >}}

## 构建和测试网站{#building-and-testing-the-site}

编辑了某些内容文件后，您将需要构建网站以测试您的更改。我们使用 [Hugo](https://gohugo.io/) 来生成我们的网站。为了在本地构建和测试站点，我们使用了包含 Hugo 的 Docker 镜像。要构建和运行该站点，只需转到根目录并执行以下操作：

{{< text bash >}}
$ make serve
{{< /text >}}

这将构建站点并启动托管该站点的 Web 服务器。然后，您可以通过 `http://localhost:1313` 连接到Web服务器。

要从远程服务器创建站点并为其提供服务，请按如下所示用服务器的 IP 地址或 DNS 域覆盖 `ISTIO_SERVE_DOMAIN`：

{{< text bash >}}
$ make ISTIO_SERVE_DOMAIN=192.168.7.105 serve
{{< /text >}}

这将构建站点并启动托管该站点的 Web 服务器。然后，您可以通过 `http://192.168.7.105:1313` 连接到 Web 服务器。

该网站的所有英文内容都位于 `content/en` 目录以及同级翻译的目录（如 `content/zh`）中。

### Linting

我们使用 [linters](https://en.wikipedia.org/wiki/Lint_(software)) 来确保网站内容的基本质量。在您将更改提交到存储库之前，这些 linter 必须运行时没有报错。linter 检查以下内容：

- HTML 校对，可确保所有链接以及其他检查均有效。

- 拼写检查。

- 样式检查，确保您的 markdown 文件符合我们的通用样式规则。

您可以使用以下命令在本地运行这些 linter 检查：

{{< text bash >}}
$ make lint
{{< /text >}}

如果您遇到拼写错误，则可以通过三种选择来解决：

- 这是一个真正的错别字，修复你的 markdown。

- 这是命令/字段/符号名称，因此请在其周围加上一些`反引号`。

- 这确实是有效的，因此请将该单词添加到存储库根目录的 .spelling 文件中。

如果由于互联网连接状况不佳而导致链接检查器出现问题，则可以为名为 `INTERNAL_ONLY` 的环境变量设置任何值，以防止 linter 检查外部链接：

{{< text bash >}}
$ make INTERNAL_ONLY=True lint
{{< /text >}}

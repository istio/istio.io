---
title: 编写新主题
description: 编写新的文档页面的方法
weight: 30
---

本文说明了如何创建新的 Istio 文档页面。

## 开始之前

首先要 Fork Istio 的文档仓库，这一过程在 [Working with GitHub](/about/contribute/github/) 中有具体讲解。

## 选择页面类型

开始新主题之前，要清楚哪个页面类型适合你的内容：

<table>
  <tr>
    <td>概念</td>
    <td>概念页面解释了Istio的一些重要方面。 例如，概念页面可能会描述 Mixer 的的配置模型并解释其中的一些细微之处。通常，概念页面不包括步骤序列，而是提供到任务的链接。</td>
  </tr>

  <tr>
    <td>参考</td>
    <td>参考页面提供了详尽的API参数列表，命令行选项，配置设置和过程。</td>
  </tr>

  <tr>
    <td>示例</td>
    <td>示例页面描述了一个完整工作的独立示例，突出展示一组特定功能。例子设置和使用说明必须易于遵循，以便用户可以快速运行该示例，并尝试改变例子来对系统进行摸索。
    </td>
  </tr>

  <tr>
    <td>任务</td>
    <td>这种页面用来演示如何通过一系列步骤完成一个目标任务。 任务页面只有少量的必要的解释，但通常提供指提供相关背景知识的链接。</td>
  </tr>

  <tr>
    <td>安装</td>
    <td>安装页面与任务页面类似，只是它着重于安装活动。</td>
  </tr>

  <tr>
    <td>博客</td>
    <td>
      博客文章是关于Istio或与之相关的产品和技术的文章。
    </td>
  </tr>
</table>

## 命名主题

选择一个标题，其中包含您希望搜索引擎查找的关键字。

使用标题中的单词创建一个文件名，用连字符分隔，全部以小写字母表示。

## 更新 Front matter

每个文档头部都是以 [Front matter](https://gohugo.io/content-management/front-matter/) 开始的。
Front matter 是文件顶部的一段 yaml 代码，上下都是用三个连字符作为间隔。下面是一段 Front matter 的示例：

{{< text yaml >}}
---
title: <title>
description: <description>
weight: <weight>
keywords: [keyword1,keyword2,...]
---
{{< /text >}}

在新的 Markdown 文件的开始处复制上述内容并更新信息字段。可用字段包括：

|字段          | 描述
|---------------|------------
|`title`        | 页面的简称
|`description`  | 关于该主题内容的单行描述
|`weight`       | 一个整数，用于确定此页面相对于同一目录中其他页面的排列顺序
|`keywords`     | 描述页面的一系列关键字，用于创建“请参阅”链接
|`draft`        | 如果为 true，页面不会出现在任何导航区域中
|`publishdate`  | 博客的发布日期
|`subtitle`     | 可选，博客的副标题，会显示在标题的下方
|`attribution`  | 可选，博客的作者
|`toc`          | 将其设置为 false，就不会生成目录
|`force_inline_toc` | 将其设置为 true 会强制将生成的目录插入到文本而不是侧边栏中

## 加入图片

将图像文件放在与 Markdown 文件相同的目录中。首选的图像格式是 SVG。

在 Markdown 文件中使用以下形式添加图像：

{{< text html >}}
{{</* image width="75%" ratio="69.52%"
    link="./myfile.svg"
    alt="当图片不可用时显示的文字"
    title="鼠标移到上方时出现的提示文字"
    caption="图片下方显示的文字"
    */>}}
{{< /text >}}

 `width`、`ratio`、`link` 以及 `caption` 都是必要的。如果没有设置 `title` 的值，缺省会跟 `caption` 保持一致。如果没有给 `alt` 赋值，就会使用 `title` 的值，如果 `title` 也没有赋值，也同样会采用 `caption` 的值。

`width` 表示图像宽度相对周围文字的百分比。 `ratio` 必须使用（图像高度/图像宽度）* 100 手动计算。

## 添加图标和 emoji

您可以使用下面的方式在内容中嵌入一些常用图标：

{{< text markdown >}}
{{</* warning_icon */>}}
{{</* idea_icon */>}}
{{< /text >}}

这段代码会显示 {{< warning_icon >}} 和 {{< idea_icon >}}

另外还可以用这种代码在内容中加入 emoji：`:sailboat:`，这样会显示帆船 emoji。

可用的 emoji 列表可以参看：[Cheat sheet of the supported emojis](https://www.webpagefx.com/tools/emoji-cheat-sheet/)。

## 连接到其他页面

文档中可以包含三种类型的链接，分别使用各自的方式来链接到目标内容：

1. **内部链接：**使用经典的 URL 语法（最好使用 HTTPS 协议）来引用 Internet 上 的文件：

    {{< text markdown >}}
    [see here](https://mysite/myfile.html)
    {{< /text >}}

1. **相对链接：**在网站的层次结构内，用以句号开头的相对链接引用与当前文件相同或以下级别的任何内容：

    {{< text markdown >}}
    [see here](./adir/anotherfile.html)
    {{< /text >}}

1. **绝对链接：**用以 `/` 开头的绝对链接来引用当前层次之外的内容：

    {{< text markdown >}}
    [see here](/docs/adir/afile/)
    {{< /text >}}

## 预格式化文本块

您可以使用 `text` 语法嵌入预先格式化的内容块：

{{< text markdown >}}
{{</* text plain */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

上面的代码会生成如下的输出：

{{< text plain >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

您必须在预格式化的块中指明内容的语法。 上面例子中标记的是 `plain`，表示不应该对块应用语法着色。 同样的内容，下面改用 Go 语法进行注释：

{{< text markdown >}}
{{</* text go */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

会渲染成为：

{{< text go >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

可以使用 `plain`、`markdown`、`yaml`、`json`、`java`、`javascript`、`c`、`cpp`、`csharp`、`go`、`html`、`protobuf`、`perl`、`docker` 以及 `bash`。

### 控制台命令及其输出的显示

当显示一个或多个 bash 命令行时，可以使用 `$` 开始：

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello"
{{</* /text */>}}
{{< /text >}}

会渲染成为：

{{< text bash >}}
$ echo "Hello"
{{< /text >}}

同一块中可以显示多个命令：

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{</* /text */>}}
{{< /text >}}

会显示为：

{{< text bash >}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{< /text >}}

还可以使用分行命令：

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

会显示为：

{{< text bash >}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{< /text >}}

默认情况下，输出部分使用 `plain` 语法进行处理。 如果输出使用众所周知的语法，您可以指定它并为其着色。 这对于 yaml 或 json 输出尤为常见：

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

会呈现为:

{{< text bash json >}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{< /text >}}

### 对 Istio GitHub 文件的引用

如果您的代码块引用了 Istio 的 GitHub repo 中的文件，则可以用一对 `@` 包围文件的相对路径名，这样路径就会被渲染为为从当前分支到文件的链接。 例如：

{{< text markdown >}}
{{</* text bash */>}}
$ istioctl create -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

上面代码的渲染结果：

{{< text bash >}}
$ istioctl create -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

## 展示文件片段

这个功能用于显示较大文件的一部分内容。 可以在文件中使用 `$ snippet` 和 `$ endsnippet` 注释来创建片段。例如，您可以使用如下所示的文本文件：

{{< text_file file="examples/snippet_example.txt" syntax="plain" >}}

Markdown 文件中可以这样对片段进行引用：

{{< text markdown >}}
{{</* text_file file="examples/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

`file` 指定了文本文件在文档库中的相对路径；`syntax` 指定了用于着色的语法 (普通文本可以使用 `plain`)； `snippet` 就是片段的名称。如果省略了 `snippet`，就会把整个文件包含进来。

上面代码的输出如下：

{{< text_file file="examples/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

一个常见的事情是就将示例脚本或 yaml 文件从 GitHub 复制到文档仓库中，然后在文件中使用代码片段来生成文档中的示例。 要从 GitHub 中提取带注释的文件，请在文档仓库中脚本 `scripts/grab_reference_docs.sh` 末尾添加所需的条目。

## 展示动态内容

您可以拉入外部文件并将其内容显示为预格式化文本块。 可以很方便的显示配置文件或测试文件。使用如下语句就能完成这一任务：

{{< text markdown >}}
{{</* text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/kube/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" */>}}
{{< /text >}}

会输出这样的内容：

{{< text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/kube/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" >}}

如果文件来自不同的原始站点，则应在该站点上启用 CORS。 请注意 GitHub（raw.githubusercontent.com）原始内容网站是可以使用的。

## 引用 GitHub 文件

从 Istio 的 GitHub 仓库引用文件时，最好引用仓库中的特定分支。要引用文档网站当前定位的特定分支，请使用注解 `{{</* branch_name */>}}`。 例如：

{{< text markdown >}}
See this [source file](https://github.com/istio/istio/blob/{{</* branch_name */>}}/mixer/cmd/mixs/cmd/server.go)/
{{< /text >}}

## 页面的移动或重命名

如果想要移动页面并希望确保现有链接继续有效，可以使用重定向指令来达成目标。

在作为重定向目标的页面（您希望用户登陆的页面）中，您只需将以下内容添加到 Front Matter：

{{< text plain >}}
aliases:
    - <url>
{{< /text >}}

例如：

{{< text plain >}}
---
title: Frequently Asked Questions
description: Questions Asked Frequently
weight: 12
aliases:
    - /faq
---
{{< /text >}}

上面的页面保存为 `_help/faq.md`，用户不管使用 `istio.io/help/faq/` 还是 `istio.io/faq/`，都能到达这一页面。

还可以加入多个重定向指令：

{{< text plain >}}
---
title: Frequently Asked Questions
description: Questions Asked Frequently
weight: 12
aliases:
    - /faq
    - /faq2
    - /faq3
---
{{< /text >}}

## 注意事项

在为 istio.io 写内容时，的确会有一些复杂。 您需要了解这些内容才能让网站基础架构正确处理您的内容：

- 确保代码块总是以4个空格的倍数缩进。 否则，渲染页面中代码块的缩进将关闭，并且代码块中会插入空格，导致剪切和粘贴不能正常工作。
- 确保所有图像具有有效的宽度和宽高比。 否则会根据屏幕进行奇怪的渲染。
- 在代码块中插入链接时候，如果使用 `@@` 进行注解，那么这个链接就不会被检查。 这样就可以把坏链接放进内容之中，并且不会被工具阻止了，建议慎重使用。
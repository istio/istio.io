---
title: 编写新主题
description: 编写新的文档页面的方法。
weight: 30
---

本文说明了如何创建新的 Istio 文档页面。

## 开始之前

首先要 Fork Istio 的文档仓库，这一过程在[使用 GitHub](/zh/about/contribute/github/) 中有具体讲解。

## 选择页面类型

开始新主题之前，要清楚哪个页面类型适合你的内容：

|类型|说明|
|---|---|
|概念|概念页面解释了 Istio 的一些重要方面。例如，概念页面可能会描述 Mixer 的的配置模型并解释其中的一些细微之处。通常，概念页面不包括步骤序列，而是提供到任务的链接。|
|参考|参考页面提供了详尽的 API 参数列表、命令行选项、配置设置和过程。|
|示例|示例页面描述了一个完整工作的独立示例，突出展示一组特定功能。例子设置和使用说明必须易于遵循，以便用户可以快速运行该示例，并尝试改变例子来对系统进行摸索。|
|任务|这种页面用来演示如何通过一系列步骤完成一个目标任务。任务页面只有少量的必要的解释，但通常会提供相关背景知识的链接。|
|安装|安装页面与任务页面类似，只是它着重于安装活动。|
|博客|博客文章是关于 Istio 或与之相关的产品和技术的文章。|

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

| 字段               | 描述
|:-------------------|:---------------------------------------------------
| `title`            | 页面的标题
| `subtitle`         | 可选的副标题，会显示在主标题的下方
| `description`      | 关于该主题内容的单行描述
| `icon`             | 可选字段，指向一个图像文件路径，会显示在主标题旁边
| `weight`           | 一个整数，用于确定此页面相对于同一目录中其他页面的排列顺序
| `keywords`         | 描述页面的一系列关键字，用于创建"请参阅”链接
| `draft`            | 如果为 true，页面不会出现在任何导航区域中
| `aliases`          | 查看[页面的重命名、移动或删除](#页面的重命名-移动或删除)中的详细描述
| `skip_toc`         | 将其设置为 true，就不会生成目录
| `skip_seealso`     | 将其设置为 false，就不会生成 “See also”
| `force_inline_toc` | 将其设置为 true 会强制将生成的目录插入到文本而不是侧边栏中

除上表之外，还有几个特有的字段可以在博客中使用：

| 字段          | 描述
|:--------------|:--------------------------
| `publishdate` | 博客的发布日期
| `attribution` | 可选，博客的作者
| `twitter`     | 可选字段，博客作者的 Twitter

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

`width` 表示图像宽度相对周围文字的百分比。`ratio` 必须使用（图像高度/图像宽度）* 100 手动计算。

## 添加图标和 emoji

您可以使用下面的方式在内容中嵌入一些常用图标：

{{< text markdown >}}
{{</* warning_icon */>}}
{{</* idea_icon */>}}
{{< /text >}}

这段代码会显示 {{< warning_icon >}} 和 {{< idea_icon >}}

另外还可以用这种代码在内容中加入 `emoji` ： `:``sailboat``:` ，这样会显示帆船的 `emoji` ， 就像这样 `:sailboat:`。

可用的 emoji 列表可以参看：[Cheat sheet of the supported emojis](https://www.webpagefx.com/tools/emoji-cheat-sheet/)。

## 连接到其他页面

文档中可以包含三种类型的链接，分别使用各自的方式来链接到目标内容：

1. **内部链接**：使用经典的 URL 语法（最好使用 HTTPS 协议）来引用 Internet 上的文件：

    {{< text markdown >}}
    [see here](https://mysite/myfile.html)
    {{< /text >}}

1. **相对链接**：在网站的层次结构内，用以句号开头的相对链接引用与当前文件相同或以下级别的任何内容：

    {{< text markdown >}}
    [see here](./adir/anotherfile.html)
    {{< /text >}}

1. **绝对链接**：用以 `/` 开头的绝对链接来引用当前层次之外的内容：

    {{< text markdown >}}
    [see here](/zh/docs/adir/afile/)
    {{< /text >}}

### GitHub

有几种引用 GitHub 文件的方法：

- **{{</* github_file */>}}** 可以用来引用单独的 GitHub 文件，例如 yaml，会生成类似 `https://raw.githubusercontent.com/istio/istio/...` 的链接：

    {{< text markdown >}}
    [liveness]({{</* github_file */>}}/samples/health-check/liveness-command.yaml)
    {{< /text >}}

- **{{</* github_tree */>}}** 用于引用 GitHub 中的目录树，会转换成如下链接：`https://github.com/istio/istio/tree/...`

    {{< text markdown >}}
    [httpbin]({{</* github_tree */>}}/samples/httpbin)
    {{< /text >}}

- **{{</* github_blob */>}}** 用来引用 GitHub 资源，生成如下链接：`https://github.com/istio/istio/blob/...`

    {{< text markdown >}}
    [RawVM MySQL]({{</* github_blob */>}}/samples/rawvm/README.md)
    {{< /text >}}

上面的注解生成的链接会指向 GitHub 中当前文档的当前所在分支。如果需要手工创建链接，可以使用 **{{</* branch_name */>}}** 来获取当前分支名称。

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

您必须在预格式化的块中指明内容的语法。上面例子中标记的是 `plain`，表示不应该对块应用语法着色。同样的内容，下面改用 Go 语法进行注释：

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

默认情况下，输出部分使用 `plain` 语法进行处理。如果输出使用众所周知的语法，您可以指定它并为其着色。这对于 yaml 或 json 输出尤为常见：

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

另外还有第三个可选值，用于控制浏览器下载该文件时对文件的命名，例如：

{{< text markdown >}}
{{</* text go plain "hello.go" */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

如果没有指定这个值，下载文件名会自动沿用当前页面的名称。

### 对 Istio GitHub 文件的引用

如果您的代码块引用了 Istio 的 GitHub repo 中的文件，则可以用一对 `@` 包围文件的相对路径名，这样路径就会被渲染为当前分支中该文件的链接。例如：

{{< text markdown >}}
{{</* text bash */>}}
$ istioctl create -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

{{< text markdown >}}
{{</* text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" */>}}
{{< /text >}}

上面代码的渲染结果：

{{< text bash >}}
$ istioctl create -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

## 文件和片段

这个功能用于展示整个或者部分文件。可以使用 `$snippet` 和 `$endsnippet` 对文件进行注解来创建一个具名片段。例如使用如下所示的文本文件：

{{< text_file file="examples/snippet_example.txt" syntax="plain" >}}

Markdown 文件中可以这样对片段进行引用：

{{< text markdown >}}
{{</* text_file file="examples/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

`file` 指定了文本文件在文档库中的相对路径；`syntax` 指定了用于着色的语法 (普通文本可以使用 `plain`)； `snippet` 就是片段的名称。

上面代码的输出如下：

{{< text_file file="examples/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

还可以设置一个可选属性 `download`，浏览器会在下载文件时用这个属性的值进行命名，例如：

{{< text markdown >}}
{{</* text_file file="examples/snippet_example.txt" syntax="plain" downloadas="foo.txt" */>}}
{{< /text >}}

一个常见的事情是就将示例脚本或 yaml 文件从 GitHub 复制到文档仓库中，然后在文件中使用代码片段来生成文档中的示例。要从 GitHub 中提取带注释的文件，请在文档仓库中脚本 `scripts/grab_reference_docs.sh` 末尾添加所需的条目。

## 展示动态内容

您可以拉入外部文件并将其内容显示为预格式化文本块。可以很方便的显示配置文件或测试文件。使用如下语句就能完成这一任务：

{{< text markdown >}}
{{</* text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" */>}}
{{< /text >}}

会输出这样的内容：

{{< text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" >}}

如果文件来自不同的原始站点，则应在该站点上启用 CORS。请注意 GitHub（`raw.githubusercontent.com`）原始内容网站是可以使用的。

如果没有指定 `downloads` 属性，那么下载文件名会来自于 URL 属性。

## 使用标签页

如果待展示内容中包含多个格式，使用标签页的形式，在不同标签页中显示不同格式是很方便的。可以使用 `tabset` 和 `tabs` 注解来实现这一功能：

{{< text markdown >}}
{{</* tabset cookie-name="platform" */>}}

{{%/* tab name="One" cookie-value="one" */%}}
ONE
{{%/* /tab */%}}

{{%/* tab name="Two" cookie-value="two" */%}}
TWO
{{%/* /tab */%}}

{{%/* tab name="Three" cookie-value="three" */%}}
THREE
{{%/* /tab */%}}

{{</* /tabset */>}}
{{< /text >}}

which produces the following output:

{{< tabset cookie-name="platform" >}}

{{% tab name="One" cookie-value="one" %}}
ONE
{{% /tab %}}

{{% tab name="Two" cookie-value="two" %}}
TWO
{{% /tab %}}

{{% tab name="Three" cookie-value="three" %}}
THREE
{{% /tab %}}

{{< /tabset >}}

每个标签页的 `name` 属性会显示在标签页上方。标签页的内容部分几乎可以是任何 Markdown 文本。

`cookie-name` 和 `cookie-value` 是可选项，可以根据访问会话来保存标签选择。当用户选择一个标签的时候，Cookie 会自动使用给定的名称和值进行保存。如果多个标签集用到了同样的 Cookie 名称和值，他们的设置会在不同页面中自动同步。如果在站点中有多个使用了同样格式的标签集，这种做法对阅读过程会非常有帮助。

例如如果多个标签集使用的都是 `GCP`、`BlueMix` 以及 `AWS` 这几个选项，就可以设置所有的 Cookie 名称为 `environment`，取值范围为 `gcp`、`bluemix` 以及 `aws`。当用户在某个页面中选了了标签之后，在其他的标签集中也会自动进行同样的选择。

### 限制

标签中几乎可以使用任何 Markdown 文本，除了以下几个特例：

- **不要使用标题**：标签中的标题会出现在内容大纲中，然而点击对应条目也并不会跳转到该标签。

- **不要嵌套使用标签集**：不要尝试，后果很可怕。

## 页面的重命名、移动或删除

如果要移动或完全删除页面，就要确认链接到待变更页面的内容能够正常工作。可以给页面加入别名，这样指向原有 URL 的链接就会被自动重定向到新的 URL 上。

只要在**目标页面**（也就是希望用户转入的页面）上加入下面的 Front matter：

{{< text plain >}}
aliases:
    - <url>
{{< /text >}}

例如

{{< text plain >}}
---
title: Frequently Asked Questions
description: Questions Asked Frequently.
weight: 12
aliases:
    - /faq
---
{{< /text >}}

上面的页面保存为 `_help/faq.md` 之后，用户访问 `istio.io/help/faq/`（也就是 `/faq`） 的时候，就会转到这一页面。

还可以像这样为页面加入多个别名：

{{< text plain >}}
---
title: Frequently Asked Questions
description: Questions Asked Frequently.
weight: 12
aliases:
    - /faq
    - /faq2
    - /faq3
---
{{< /text >}}

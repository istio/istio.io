---
title: 创建和编辑页面
description: 解释创建和维护文档页面的机制。
weight: 30
keywords: [contribute]
---

此页面显示如何创建，测试和维护 Istio 文档主题。

## 开始之前{#before-you-begin}

在开始编写 Istio 文档之前，首先需要创建一个 Istio 文档存储库的分支，如[与 GitHub 合作](/zh/about/contribute/github/)中所述。

## 选择页面类型{#choosing-a-page-type}

在准备编写新主题时，请考虑您的内容最适合哪一种页面类型：

<table>
  <tr>
    <td>概念</td>
    <td>概念页面解释了 Istio 的一些重要概念。例如，概念页面可能会描述 Mixer 的配置模型并解释其中的一些细微之处。通常，概念页面不包括具体的操作步骤，而是提供指向任务的链接。</td>
  </tr>

  <tr>
    <td>参考</td>
    <td>参考页面提供了诸如 API 参数，命令行选项，配置设置和过程之类的详尽列表。
    </td>
  </tr>

  <tr>
    <td>示例</td>
    <td>示例页面描述了一个完整工作的独立示例，突出显示了一组特定功能。示例必须具有易于遵循的设置和使用说明，以便用户可以自己快速运行示例并尝试更改示例以探索系统。测试和维护示例以获得技术准确性。
    </td>
  </tr>

  <tr>
    <td>任务</td>
    <td>任务页面显示如何执行单个操作，通常通过提供一系列简短的步骤。任务页面具有最少的解释，但通常提供指向提供相关背景和知识的概念主题的链接。测试和维护任务以确保技术准确性。</td>
  </tr>

  <tr>
    <td>安装</td>
    <td>安装页面类似于任务页面，但它侧重于安装活动。测试和维护安装页面以确保技术准确性。
    </td>
  </tr>

  <tr>
    <td>博客文章</td>
    <td>
      博客文章是关于 Istio 或与之相关的产品和技术的及时文章。通常，帖子属于以下四个类别之一：
      <ul>
      <li>帖子详细介绍了作者使用和配置 Istio 的经验，特别是那些能够表达新颖体验或观点的人。</li>
      <li>帖子突出显示或宣布 Istio 功能。</li>
      <li>宣布与 Istio 相关的活动的帖子。</li>
      <li>帖子详细介绍了如何使用 Istio 完成任务或完成特定用例。与任务和示例不同，博客文章的技术准确性在发布后不会得到维护和测试。</li>
      </ul>
    </td>
  </tr>

  <tr>
    <td>FAQ</td>
    <td>
      常见问题解答条目可以快速解答常见的客户问题。答案通常不会引入任何新概念，而是专注于一些实用的建议或见解，并将链接返回主要文档以供用户了解更多信息。
    </td>
  </tr>

  <tr>
    <td>Ops Guide</td>
    <td>
      用于解决在实际环境中运行 Istio 时遇到的特定问题的实用解决方案。
    </td>
  </tr>
</table>

## 命名主题{#naming-a-topic}

为您的主题选择一个标题，其中包含您希望搜索引擎找到的关键字。
为您的主题创建一个文件名，使用标题单词和连字符组成文件名（单词要小写）。

## 设置文章的元数据信息{#updating-front-matter}

每个文档文件都需要从头开始写[元数据信息](https://gohugo.io/content-management/front-matter/)。
元数据信息是介于两个 YAML 块之间的信息（通过三个`-`来分割与文章的具体信息）。
下面就是你需要写的元数据信息：

{{< text yaml >}}
---
title: <title>
description: <description>
weight: <weight>
keywords: [keyword1,keyword2,...]
---
{{< /text >}}

在新的 markdown 文件的开头复制上面的内容并更新信息字段。
可用的字段是：

|字段              | 描述
|-------------------|------------
|`title`            | 页面标题
|`linktitle`        | 页面的另一个（通常是较短的）标题，在侧栏中用于引用页面
|`subtitle`         | 一个可选的副标题，显示在主标题下方
|`description`      | 关于页面内容的单行描述
|`icon`             | 图片文件的可选路径，显示在主标题旁边
|`weight`           | 一个整数，用于确定此页面相对于同一目录中其他页面的排序顺序
|`keywords`         | 描述页面的一组关键字，用于创建“请参阅”链接的Web
|`draft`            | 如果为true，则阻止页面显示在任何导航区域中
|`aliases`          | 有关此项目的详细信息，请参阅下面的[重命名，移动或删除页面](#renaming-moving-or-deleting-pages)
|`skip_toc`         | 将此设置为 true 可防止页面为其生成目录
|`skip_byline`      | 将此设置为 true 可防止页面在主标题下具有副行
|`skip_seealso`     | 将此设置为 true 可防止页面为其生成“另请参阅”部分
|`force_inline_toc` | 将此属性设置为 true 可强制将生成的目录内联插入文本而不是侧边栏中
|`simple_list`      | 将此设置为 true 可强制生成的节页面使用简单的列表布局而不是画廊布局
|`content_above`    | 将此属性设置为 true 可强制将节索引的内容部分呈现在自动生成的内容上方

还有一些专门针对博客文章的字段：

|字段          | 描述
|---------------|------------
|`publishdate`  | 该帖子的原始出版日期
|`last_update`  | 帖子上次重大修订的日期
|`attribution`  | 帖子作者的名称（可选）
|`twitter`      | 帖子作者的 Twitter 账号（可选）

## 添加图片{#adding-images}

将图片文件放在与 markdown 文件相同的目录中。首选的图片格式是 SVG。
在 markdown 内，使用以下格式添加图片：

{{< text html >}}
{{</* image width="75%" ratio="45.34%"
    link="./myfile.svg"
    alt="无法加载图片时显示的备用文本"
    title="将鼠标悬停在图片上时显示的工具提示"
    caption="图片下方显示的标题"
    */>}}
{{< /text >}}

`link` 和 `caption` 值是必需的，所有其他值都是可选的。

如果没有提供 `title` 值，它将默认与 `caption` 相同。如果没有提供 `alt` 值，它就会
默认为 `title` 或者如果 `title` 没有定义，则为 `caption`。

`width` 表示图片相对于周围的文字使用的空间百分比。如果未指定该值，则默认为 100％。

`ratio` 表示图片高度与图片宽度的比率。这个
对于任何本地图片内容自动计算值，但引用外部图片内容时必须手动计算。
在这种情况下，`ratio` 应设置为（图片高度/图片宽度）* 100。

## 添加图标{#adding-icons}

您可以使用以下内容在文章中嵌入一些常用图标：

{{< text markdown >}}
{{</* warning_icon */>}}
{{</* idea_icon */>}}
{{</* checkmark_icon */>}}
{{</* cancel_icon */>}}
{{</* tip_icon */>}}
{{< /text >}}

效果如下:
{{< warning_icon >}}、{{< idea_icon >}}、{{< checkmark_icon >}}、{{< cancel_icon >}}和{{< tip_icon >}}。

## 链接到其他页面{#linking-to-other-pages}

文档中可以包含三种类型的链接。每个使用不同的
指示链接目标的方式：

1. **互联网链接**. 您可以使用经典 URL 语法（最好使用 HTTPS 协议）来引用互联网上的文件：

    {{< text markdown >}}
    [看这里](https://mysite/myfile.html)
    {{< /text >}}

1. **相对链接**. 您使用以句点开头的相对链接
引用与当前文件处于同一级别或以下级别的任何内容
网站的层次结构：

    {{< text markdown >}}
    [看这里](./adir/anotherfile.html)
    {{< /text >}}

1. **绝对链接**. 您使用以 `/` 开头的绝对链接来引用当前层级之外的内容：

    {{< text markdown >}}
    [看这里](/docs/adir/afile/)
    {{< /text >}}

### GitHub

有几种方法可以从 GitHub 引用文件：

- **{{</* github_file */>}}** 是 Istio 在 GitHub 中的单个文件引用，例如 yaml 文件。这将生成一个指向 `https://raw.githubusercontent.com/istio/istio*` 的链接

    {{< text markdown >}}
    [liveness]({{</* github_file */>}}/samples/health-check/liveness-command.yaml)
    {{< /text >}}

- **{{</* github_tree */>}}** 是 Istio 在 GitHub 中的目录树引用。这将产生一个链接 `https://github.com/istio/istio/tree*`

    {{< text markdown >}}
    [httpbin]({{</* github_tree */>}}/samples/httpbin)
    {{< /text >}}

- **{{</* github_blob */>}}** 是 Istio 在 GitHub 中的源文件引用。这将产生一个链接 `https://github.com/istio/istio/blob*`

    {{< text markdown >}}
    [RawVM MySQL]({{</* github_blob */>}}/samples/rawvm/README.md)
    {{< /text >}}

上面的注释将产生到 GitHub 中相应分支的链接，相对于该分支文档目前正在定位。如果需要手动构造 URL，可以使用 `{{</* source_branch_name */>}}` 获取当前目标分支的名称。

## 版本信息{#version-information}

您可以使用 `{{</* istio_version */>}}` 中的任何一个获取网站描述的当前 Istio 版本。
`{{</* istio_full_version */>}}` 分别呈现为 {{< istio_version >}} 和 {{< istio_full_version >}}。

`{{</* source_branch_name */>}}` 扩展为 `istio/istio` 网站所针对的 GitHub 存储库的分支名称
。这将呈现为{{< source_branch_name >}}。

## 嵌入预先格式化的块{#embedding-preformatted-blocks}

您可以使用 `text` 嵌入预格式化内容块：

{{< text markdown >}}
{{</* text plain */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

输出效果如下：

{{< text plain >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

您需要预格式化的块中指明内容的语法。上面的代码块被标记为 `plain` 表示不会对块应用语法高亮。代码块样式都一样，但现在使用 Go 语言语法进行注释：

{{< text markdown >}}
{{</* text go */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

效果如下：

{{< text go >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

你可以使用 `plain`、`markdown`、`yaml`、`json`、`java`、`javascript`、`c`、`cpp`、`csharp`、`go`、`html`、`protobuf` 、`perl`、`docker` 和 `bash`。

### 命令和命令输出{#commands-and-command-output}

显示一个或多个 bash 命令行时，每个命令行用 $ 开头：

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello"
{{</* /text */>}}
{{< /text >}}

效果如下：

{{< text bash >}}
$ echo "Hello"
{{< /text >}}

您可以拥有任意数量的命令行，但只能识别一个输出块。

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{</* /text */>}}
{{< /text >}}

效果如下：

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

效果如下：

{{< text bash >}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{< /text >}}

默认情况下，使用 `plain` 语法处理输出内容。如果输出使用众所周知的
语法，您可以指定它并获得适当的颜色。这对于 YAML 或 JSON 输出尤其常见：

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

效果如下：

{{< text bash json >}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{< /text >}}

您可以指定一个可选的第三个值来控制浏览器在用户选择下载文件时的名称。例如：

{{< text markdown >}}
{{</* text go plain "hello.go" */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

如果未指定第三个值，则会根据当前页面的名称自动生成下载名称。

### 链接到 GitHub 文件

如果你的代码块引用了 Istio 的 GitHub 存储库中的文件，你可以用一对 `@` 符号来包围文件的相对路径名。这些表明路径应该呈现为当前分支中的文件链接。例如：

{{< text markdown >}}
{{</* text bash */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

效果如下

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

### 文件和片段{#files-and-snippets}

显示文件或文件的一部分通常很有用。您可以注释文本文件以在文件中创建命名片段
使用 `$snippet` 和 `$endsnippet` 注释。例如，您可以使用如下所示的文本文件：

{{< text_file file="test/snippet_example.txt" syntax="plain" >}}

然后，在您的 markdown 文件中，您可以使用以下内容引用特定代码段：

{{< text markdown >}}
{{</* text_file file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

其中 `file` 指定文档仓库中文本文件的相对路径，`syntax` 指定
用于语法着色的语法（使用 `plain` 表示通用文本），`snippet` 指定的名称片段。

上面的代码片段产生了这个输出：

{{< text_file file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

如果您未指定代码段名称，则会插入整个文件。

您可以指定可选的 `downloadas` 属性来控制浏览器的名称将在用户选择下载文件时使用。例如：

{{< text markdown >}}
{{</* text_file file="test/snippet_example.txt" syntax="plain" downloadas="foo.txt" */>}}
{{< /text >}}

如果未指定 `downloadas` 属性，则下载名称取自 `file` 属性。

常见的做法是将示例脚本或 yaml 文件从 GitHub 复制到文档中
存储库然后在文件中使用片段来生成文档中的示例。拉
在 GitHub 的注释文件中，在结尾处添加所需的条目
文档存储库中的脚本 `scripts/grab_reference_docs.sh`。

### 动态内容{#dynamic-content}

您可以动态提取外部文件并将其内容显示为预格式化的块。这很方便显示一个
配置文件或测试文件。为此，您使用如下语句：

{{< text markdown >}}
{{</* text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" */>}}
{{< /text >}}

产生以下结果：

{{< text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" >}}

如果文件来自不同的源站点，则应在该站点上启用 CORS。请注意
这里可以使用 GitHub 原始内容站点（`raw.githubusercontent.com`）。

您可以指定可选的 `downloadas` 属性来控制浏览器在用户选择下载文件时使用的名称。例如：

{{< text markdown >}}
{{</* text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" downloadas="foo.yaml" */>}}
{{< /text >}}

如果未指定 `downloadas` 属性，则下载名称取自 `url` 属性。

## 术语表{#glossary-terms}

首次在页面中引入专门的 Istio 术语时，最好将术语注释为词汇表中的术语。这个
将生成特殊渲染，邀请用户单击该术语以获得带有该定义的弹出窗口。

{{< text markdown >}}
Mixer 使用{{</*gloss*/>}}适配器{{</*/gloss*/>}}来连接后端。
{{< /text >}}

效果如下：

Mixer 使用{{<gloss>}}适配器{{</gloss>}}来连接后端。

如果页面上显示的术语与术语表中的条目不完全匹配，则可以指定替换：

{{< text markdown >}}
Mixer 使用 {{</*gloss 适配器*/>}}adapter{{</*/gloss*/>}} 来连接后端。
{{< /text >}}

效果如下：

Mixer 使用 {{<gloss 适配器>}}adapter{{</gloss>}} 来连接后端。

因此即使词汇表条目是 *adapters*，也可以在文本中使用 *adapter* 的单数形式。

## 标注

您可以通过突出显示警告，想法，提示和引号来特别关注内容块：

{{< text markdown >}}
{{</* warning */>}}
这是一个重要的警告
{{</* /warning */>}}

{{</* idea */>}}
这是一个好主意
{{</* /idea */>}}

{{</* tip */>}}
这是专家提供的有用提示
{{</* /tip */>}}

{{</* quote */>}}
这是某个地方的引用
{{</* /quote */>}}
{{< /text >}}

效果如下：

{{< warning >}}
这是一个重要的警告
{{< /warning >}}

{{< idea >}}
这是一个好主意
{{< /idea >}}

{{< tip >}}
这是专家提供的有用提示
{{< /tip >}}

{{< quote >}}
这是某个地方的引用
{{< /quote >}}

## 嵌入样板文本{#embedding-boilerplate-text}

您可以使用 `boilerplate` 将常见的样板文本嵌入到任何 markdown 中：

{{< text markdown >}}
{{</* boilerplate example */>}}
{{< /text >}}

效果如下：

{{< boilerplate example >}}

您提供要在当前位置插入的样板文件的名称。可用的 boilerplates 是
位于 `boilerplates` 目录中。boilerplates 是正常的 markdown 文件。

## 使用标签{#using-tabs}

如果您有一些内容可以以各种格式显示，则可以方便地使用选项卡集并显示每个内容
格式在不同的选项卡中。要插入选项卡式内容，可以使用 `tabset` 和 `tabs` 注释的组合：

{{< text markdown >}}
{{</* tabset cookie-name="platform" */>}}

{{</* tab name="一" cookie-value="one" */>}}
一
{{</* /tab */>}}

{{</* tab name="二" cookie-value="two" */>}}
二
{{</* /tab */>}}

{{</* tab name="三" cookie-value="three" */>}}
三
{{</* /tab */>}}

{{</* /tabset */>}}
{{< /text >}}

产生如下效果：

{{< tabset cookie-name="platform" >}}

{{< tab name="一" cookie-value="one" >}}
一
{{< /tab >}}

{{< tab name="二" cookie-value="two" >}}
二
{{< /tab >}}

{{< tab name="三" cookie-value="three" >}}
三
{{< /tab >}}

{{< /tabset >}}

每个选项卡的 `name` 属性包含要为选项卡显示的文本。选项卡的内容几乎可以是任何正常的 markdown。

可选的 `cookie-name` 和 `cookie-value` 属性允许选项卡设置在访问页面时保持粘性。作为用户
选择一个标签，cookie 将自动保存为给定的名称和值。如果多个选项卡集使用相同的 cookie 名称
和值，他们的设置将自动跨页面同步。当有许多选项卡集时，这尤其有用
在具有相同类型格式的站点中。

例如，如果使用许多选项卡集来表示 `GCP`、`BlueMix` 和 `AWS` 之间的选择，则它们都可以使用 `environment` 的 cookie 名称和值
`gcp`、`bluemix`和`aws`。当用户在一个页面中选择选项卡时，将在任何其他选项卡集中自动选择等效选项卡。

### 限制{#limitations}

您可以在选项卡中使用几乎任何 markdown，但以下情况除外：

- *没有标题*。选项卡中的标题将显示在目录中，然后单击该条目中的条目
  目录不会自动选择选项卡。

- *没有嵌套标签集*。不要尝试，这太可怕了。

## 重命名，移动或删除页面{#renaming-moving-or-deleting-pages}

如果您移动页面或完全删除它们，您应该确保用户可能拥有的现有链接继续工作。
您可以通过添加别名来执行此操作，该别名将导致用户从旧 URL 自动重定向到新URL。

在作为重定向*目标*的页面中（您希望用户登陆），您只需添加
关注前面事项：

{{< text plain >}}
aliases:
    - <path>
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

通过以上保存为 `help/faq.md` 的页面，用户可以通过访问来访问该页面
到 `istio.io/help/faq/` 正常，以及 `istio.io/faq/`。

您还可以添加许多重定向，如下所示：

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

## 构建和测试网站{#building-and-testing-the-site}

编辑完一些内容文件后，您需要构建网站才能进行测试你的变更。我们使用 [Hugo](https://gohugo.io/) 来生成我们的网站。要在本地构建和测试站点，我们使用包含 `hugo` 的 Docker 镜像。如果要构建和运行站点，只需到根目录执行以下操作：

{{< text bash >}}
$ make serve
{{< /text >}}

这将构建站点并启动站点的 Web 服务器。然后，您可以用 `http://localhost:1313` 访问 Web 服务器。

要从远程服务器创建和运行站点，请使用 IP 地址覆盖 `ISTIO_SERVE_DOMAIN`，如下所示
或服务器的 DNS 域如下：

{{< text bash >}}
$ make ISTIO_SERVE_DOMAIN=192.168.7.105 serve
{{< /text >}}

这将构建站点并启动站点的 Web 服务器。然后，您可以用 `http://192.168.7.105:1313` 访问到 Web 服务器。

该网站的所有英文内容都位于 `content` 目录中，所有中文内容在 `content_zh` 目录，其他翻译的内容可能会在其他的 `content_xxx` 目录中，暂时官方只有英文和中文两种内容。

### Linting

我们使用 linters 来确保网站内容的基本质量。在将更改提交到存储库之前，这些链接必须在没有报错的情况下运行linters 检查：

- HTML 校对，确保您的所有链接与其他检查有效。

- 拼写检查。

- 样式检查，确保您的 markdown 文件符合我们的通用样式规则。

您可以使用以下方式在本地运行这些 linters

{{< text bash >}}
$ make lint
{{< /text >}}

如果您遇到拼写错误，您有三种选择来解决问题：

- 这是一个真正的错字，修复你的 markdown。

- 这是一个命令/字段/符号名称，所以在它周围粘贴一些`反引号`。

- 它确实有效，所以请将单词添加到位于 repo 根目录的 `.spelling` 文件中。

如果由于 Internet 连接较差而导致链接检查程序出现问题，则可以将任何值设置为名为的环境变量
`INTERNAL_ONLY` 以防止 linter 检查外部链接：

{{< text bash >}}
$ make INTERNAL_ONLY=True lint
{{< /text >}}

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

此页面介绍了如何创建，测试和维护 Istio 文档主题。

## Before you begin

在开始编写 Istio 文档之前，首先需要创建一个 Istio 文档存储库的分支正如[使用 GitHub 工作](/zh/about/contribute/github/)中所述。

## 选择页面类型

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

## 命名主题

为您的主题选择一个具有您希望搜索引擎查找的关键字的标题。为你的主题创建一个使用标题中的单词、并用连字符分隔而且所有字母均小写的文件名。

## 设置文档的元数据信息

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

|Field               | Description
|--------------------|------------
|`skip_toc`          | Set this to true to prevent the page from having a table of contents generated for it
|`force_inline_toc`  | Set this to true to force the generated table of contents to be inserted inline in the text instead of in a sidebar
|`max_toc_level`     | Set to 2, 3, 4, 5, or 6 to indicate the maximum heading level to show in the table of contents
|`remove_toc_prefix` | Set this to a string that will be removed from the start of every entry in the table of contents if present

A few front-matter fields are specific to section pages (i.e. for files names `_index.md`):

|Field                 | Description
|----------------------|------------
|`skip_list`           | Set this to true to prevent the auto-generated content on a section page
|`simple_list`         | Set this to true to use a simple list layout rather than gallery layout for the auto-generated content of a section page
|`list_below`          | Set this to true to insert the auto-generated content on a section page below the manually-written content
|`list_by_publishdate` | Set this to true to sort the generated content on the page in order in publication date, rather than by page weight

There are a few more front matter fields available specifically for blog posts:

|Field           | Description
|----------------|------------
|`publishdate`   | Date of the post's original publication
|`last_update`   | Date when the post last received a major revision
|`attribution`   | Optional name of the post's author
|`twitter`       | Optional Twitter handle of the post's author
|`target_release`| Release this blog is written with in mind (this is normally the current major Istio release at the time the blog is authored or updated)

## Adding images

Put image files in the same directory as your markdown file. The preferred image format is SVG.
Within markdown, use the following sequence to add the image:

{{< text html >}}
{{</* image width="75%" ratio="45.34%"
    link="./myfile.svg"
    alt="Alternate text to display when the image can't be loaded"
    title="A tooltip displayed when hovering over the image"
    caption="A caption displayed under the image"
    */>}}
{{< /text >}}

The `link` and `caption` values are required, all other values are optional.

If the `title` value isn't supplied, it'll default to the same as `caption`. If the `alt` value is not supplied, it'll
default to `title` or if that's not defined, to `caption`.

`width` represents the percentage of space used by the image
relative to the surrounding text. If the value is not specified, it
defaults to 100%.

`ratio` represents the ratio of the image height compared to the image width. This
value is calculated automatically for any local image content, but must be calculated
manually when referencing external image content.
In that case, `ratio` should be set to (image height / image width) * 100.

## Adding icons

You can embed some common icons in your content using:

{{< text markdown >}}
{{</* warning_icon */>}}
{{</* idea_icon */>}}
{{</* checkmark_icon */>}}
{{</* cancel_icon */>}}
{{</* tip_icon */>}}
{{< /text >}}

which look like {{< warning_icon >}}, {{< idea_icon >}}, {{< checkmark_icon >}}, {{< cancel_icon >}} and {{< tip_icon >}}.

## Linking to other pages

There are three types of links that can be included in documentation. Each uses a different
way to indicate the link target:

1. **Internet Link**. You use classic URL syntax, preferably with the HTTPS protocol, to reference
files on the Internet:

    {{< text markdown >}}
    [see here](https://mysite/myfile.html)
    {{< /text >}}

1. **Relative Link**. You use relative links that start with a period to
reference any content that is at the same level as the current file, or below within
the hierarchy of the site:

    {{< text markdown >}}
    [see here](./adir/anotherfile.html)
    {{< /text >}}

1. **Absolute Link**. You use absolute links that start with a `/` to reference content outside of the
current hierarchy:

    {{< text markdown >}}
    [see here](/docs/adir/afile/)
    {{< /text >}}

### GitHub

There are a few ways to reference files from GitHub:

- **{{</* github_file */>}}** is how you reference individual files in GitHub such as yaml files. This
produces a link to `https://raw.githubusercontent.com/istio/istio*`

    {{< text markdown >}}
    [liveness]({{</* github_file */>}}/samples/health-check/liveness-command.yaml)
    {{< /text >}}

- **{{</* github_tree */>}}** is how you reference a directory tree in GitHub. This produces a link to
`https://github.com/istio/istio/tree*`

    {{< text markdown >}}
    [httpbin]({{</* github_tree */>}}/samples/httpbin)
    {{< /text >}}

- **{{</* github_blob */>}}** is how you reference a file in GitHub sources. This produces a link to
`https://github.com/istio/istio/blob*`

    {{< text markdown >}}
    [RawVM MySQL]({{</* github_blob */>}}/samples/rawvm/README.md)
    {{< /text >}}

The above annotations yield links to the appropriate branch in GitHub, relative to the branch that the
documentation is currently targeting. If you need to manually construct a URL, you can use the sequence `{{</* source_branch_name */>}}`
to get the name of the currently targeted branch.

## Version information

You can obtain the current Istio version described by the web site using either of `{{</* istio_version */>}}` or
`{{</* istio_full_version */>}}` which render as {{< istio_version >}} and {{< istio_full_version >}} respectively.

`{{</* source_branch_name */>}}` gets expanded to the name of the branch of the `istio/istio` GitHub repository that the
web site is targeting. This renders as {{< source_branch_name >}}.

## Embedding preformatted blocks

You can embed blocks of preformatted content using the `text` sequence:

{{< text markdown >}}
{{</* text plain */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

The above produces this kind of output:

{{< text plain >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

You must indicate the syntax of the content in the preformatted block. Above, the block was marked as
being `plain` indicating that no syntax coloring should be applied to the block. Consider the same
block, but now annotated with the Go language syntax:

{{< text markdown >}}
{{</* text go */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

which renders as:

{{< text go >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

Supported syntax are `plain`, `markdown`, `yaml`, `json`, `java`, `javascript`, `c`, `cpp`, `csharp`, `go`, `html`, `protobuf`,
`perl`, `docker`, and `bash`.

### Command-lines

When showing one or more bash command-lines, you start each command-line with a $:

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello"
{{</* /text */>}}
{{< /text >}}

which produces:

{{< text bash >}}
$ echo "Hello"
{{< /text >}}

You can have as many command-lines as you want, but only one chunk of output is recognized.

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{</* /text */>}}
{{< /text >}}

which yields:

{{< text bash >}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{< /text >}}

You can also use line continuation in your command-lines:

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

which looks like:

{{< text bash >}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{< /text >}}

By default, the output section is handled using the `plain` syntax. If the output uses a well-known
syntax, you can specify it and get proper coloring for it. This is particularly common for YAML or JSON output:

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

which gives:

{{< text bash json >}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{< /text >}}

### Expanded form

To use the more advanced features for preformatted content which are described in the following sections, you must use the
extended form of the `text` sequence rather than the simplified form shown so far. The expanded form uses normal HTML attributes:

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

The available attributes are:

| Attribute    | Description
|--------------|------------
|`file`        | The path of a file to show in the preformatted block.
|`url`         | The URL of a document to show in the preformatted block.
|`syntax`      | The syntax of the preformatted block.
|`outputis`    | When the syntax is `bash`, this specifies the command output's syntax.
|`downloadas`  | The default file name used when the user [downloads the preformatted block](#download-name).
|`expandlinks` | Whether or not to expand [GitHub file references](#links-to-github-files) in the preformatted block.
|`snippet`     | The name of the [snippet](#snippets) of content to extract from the preformatted block.
|`repo`        | The repository to use for [GitHub links](#links-to-github-files) embedded in preformatted blocks.

### Inline vs. imported content

So far, you've seen examples of inline preformatted content but it's also possible to import content, either
from a file in the documentation repository or from an arbitrary URL on the Internet. For this, you use the
`text_import` sequence.

You can use `text_import` with the `file` attribute to reference a file within the documentation repository:

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

which renders as:

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

You can dynamically pull in content from the Internet in a similar way, but using the `url` attribute instead of the
`file` attribute. Here's the same file, but retrieved from a URL dynamically rather than being baked into the
HTML statically:

{{< text markdown >}}
{{</* text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

which produces the following result:

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" >}}

If the file is from a different origin site, CORS should be enabled on that site. Note that the
GitHub raw content site (`raw.githubusercontent.com`) may be used here.

### Download name

You can control the name that the browser
uses when the user chooses to download the preformatted content by using the `downloadas` attribute. For example:

{{< text markdown >}}
{{</* text syntax="go" downloadas="hello.go" */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

If you don't specify a download name, then it is derived automatically based on the
title of the current page for inline content, or from the name of the file or URL for imported
content.

### Links to GitHub files

If your preformatted content references a file from Istio's GitHub repository, you can surround the relative path name of the file with a pair
of @ symbols. These indicate that the path should be rendered as a link to the file from the current branch in GitHub. For example:

{{< text markdown >}}
{{</* text bash */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

Which renders as:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

Normally, links will point to the current release branch of the `istio/istio` repository. If you'd like a link
that points to a different Istio repository instead, you can use the `repo` attribute:

{{< text markdown >}}
{{</* text syntax="bash" repo="operator" */>}}
$ cat @README.md@
{{</* /text */>}}
{{< /text >}}

which renders as:

{{< text syntax="bash" repo="operator" >}}
$ cat @README.md@
{{< /text >}}

If your preformatted content happens to use @ symbols for something else, you can turn off link expansion using the
`expandlinks` attribute:

{{< text markdown >}}
{{</* text syntax="bash" expandlinks="false" */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

### Snippets

When using imported content, you can control which parts of the content to render using _named snippets_, which represent portions
of a file. You declare snippets in a file using the `$snippets` annotation with a paired `$endsnippet` annotation. The content
between the two annotations represents the snippet.
For example, you could have a text file that looks like this:

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

and in your markdown file, you can then reference a particular snippet with the `snippet` attribute such as:

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

which renders as:

{{< text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

Within a text file, snippets can indicate the syntax of the snippet content and, for bash syntax, can
include the syntax of the output. For example:

{{< text plain >}}
$snippet MySnippetFile.txt syntax="bash" outputis="json"
{{< /text >}}

## Glossary terms

When first introducing a specialized Istio term in a page, it is desirable to annotate the term as being in the glossary. This
will produce special rendering inviting the user to click on the term in order to get a pop-up with the definition.

{{< text markdown >}}
Mixer uses {{</*gloss*/>}}adapters{{</*/gloss*/>}} to interface to backends.
{{< /text >}}

which looks like:

Mixer uses {{<gloss>}}adapters{{</gloss>}} to interface to backends.

If the term displayed on the page doesn't exactly match the entry in the glossary, you can specify a substitution:

{{< text markdown >}}
Mixer uses an {{</*gloss adapters*/>}}adapter{{</*/gloss*/>}} to interface to a backend.
{{< /text >}}

which looks like:

Mixer uses an {{<gloss adapters>}}adapter{{</gloss>}} to interface to a backend.

So even though the glossary entry is for *adapters*, the singular form of *adapter* can be used in the text.

## Callouts

You can bring special attention to blocks of content by highlighting warnings, ideas, tips, and quotes:

{{< text markdown >}}
{{</* warning */>}}
This is an important warning
{{</* /warning */>}}

{{</* idea */>}}
This is a great idea
{{</* /idea */>}}

{{</* tip */>}}
This is a useful tip from an expert
{{</* /tip */>}}

{{</* quote */>}}
This is a quote from somewhere
{{</* /quote */>}}
{{< /text >}}

which looks like:

{{< warning >}}
This is an important warning
{{< /warning >}}

{{< idea >}}
This is a great idea
{{< /idea >}}

{{< tip >}}
This is a useful tip from an expert
{{< /tip >}}

{{< quote >}}
This is a quote from somewhere
{{< /quote >}}

Please use these callouts sparingly. Callouts are intended for special notes to the user and over-using them
throughout the site neutralizes their special attention-grabbing nature.

## Embedding boilerplate text

You can embed common boilerplate text into any markdown output using the `boilerplate` sequence:

{{< text markdown >}}
{{</* boilerplate example */>}}
{{< /text >}}

which results in:

{{< boilerplate example >}}

You supply the name of a boilerplate file to insert at the current location. Available boilerplates are
located in the `boilerplates` directory. Boilerplates are just
normal markdown files.

## Using tabs

If you have some content to display in a variety of formats, it is convenient to use a tab set and display each
format in a different tab. To insert tabbed content, you use a combination of `tabset` and `tabs` annotations:

{{< text markdown >}}
{{</* tabset cookie-name="platform" */>}}

{{</* tab name="One" cookie-value="one" */>}}
ONE
{{</* /tab */>}}

{{</* tab name="Two" cookie-value="two" */>}}
TWO
{{</* /tab */>}}

{{</* tab name="Three" cookie-value="three" */>}}
THREE
{{</* /tab */>}}

{{</* /tabset */>}}
{{< /text >}}

which produces the following output:

{{< tabset cookie-name="platform" >}}

{{< tab name="One" cookie-value="one" >}}
ONE
{{< /tab >}}

{{< tab name="Two" cookie-value="two" >}}
TWO
{{< /tab >}}

{{< tab name="Three" cookie-value="three" >}}
THREE
{{< /tab >}}

{{< /tabset >}}

The `name` attribute of each tab contains the text to display for the tab. The content of the tab can be almost any normal markdown.

The optional `cookie-name` and `cookie-value` attributes allow the tab setting to be sticky across visits to the page. As the user
selects a tab, the cookie will be automatically saved with the given name and value. If multiple tab sets use the same cookie name
and values, their setting will be automatically synchronized across pages. This is particularly useful when there are many tab sets
in the site that hold the same types of formats.

For example, if many tab sets are used to represent a choice between `GCP`, `BlueMix` and `AWS`, they can all use a cookie name of `environment` and values of
`gcp`, `bluemix`, and `aws`. When a user selects a tab in one page, the equivalent tab will automatically be selected in any other tab set.

### Limitations

You can use almost any markdown in a tab, except for the following:

- *No headers*. Headers in a tab will appear in the table of contents and yet clicking on the entry in the
table of contents will not automatically select the tab.

- *No nested tab sets*. Don't try it, it's horrible.

## Renaming, moving, or deleting pages

If you move pages around or delete them completely, you should make sure existing links users may have to those pages continue to work.
You do this by adding aliases which will cause the user to be redirected automatically from the old URL to a new URL.

In the page that is the *target* of the redirect (where you'd like users to land), you simply add the
following to the front-matter:

{{< text plain >}}
aliases:
    - <path>
{{< /text >}}

For example

{{< text plain >}}
---
title: Frequently Asked Questions
description: Questions Asked Frequently.
weight: 12
aliases:
    - /help/faq
---
{{< /text >}}

With the above in a page saved as `faq/_index.md`, the user will be able to access the page by going
to `istio.io/faq/` as normal, as well as `istio.io/help/faq/`.

You can also add many redirects like so:

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

## Building and testing the site

Once you've edited some content files, you'll want to build the site in order to test
your changes. We use [Hugo](https://gohugo.io/) to generate our sites. To build and test the site locally, we use a Docker
image that contains Hugo. To build and serve the site, simply go to the root of the tree and do:

{{< text bash >}}
$ make serve
{{< /text >}}

This will build the site and start a web server hosting the site. You can then connect to the web server
at `http://localhost:1313`.

To make and serve the site from a remote server, override `ISTIO_SERVE_DOMAIN` as follows with the IP address
or DNS Domain of the server as follows:

{{< text bash >}}
$ make ISTIO_SERVE_DOMAIN=192.168.7.105 serve
{{< /text >}}

This will build the site and start a web server hosting the site. You can then connect to the web server
at `http://192.168.7.105:1313`.

All English content for the site is located in the `content/en` directory, as well as in sibling translated
directories such as `content/zh`.

### Linting

We use linters to ensure some base quality to the site's content. These linters must run without
complaining before you can submit your changes into the repository. The linters check:

- HTML proofing, which ensures all your links are valid along with other checks.

- Spell checking.

- Style checking, which makes sure your markdown files comply with our common style rules.

You can run these linters locally with:

{{< text bash >}}
$ make lint
{{< /text >}}

If you get spelling errors, you have three choices to address each:

- It's a real typo, so fix your markdown.

- It's a command/field/symbol name, so stick some `backticks` around it.

- It's really valid, so go add the word to the `.spelling` file which is at the root of the repository.

If you're having trouble with the link checker due to poor Internet connectivity, you can set any value to an environment variable named
`INTERNAL_ONLY` to prevent the linter from checking external links:

{{< text bash >}}
$ make INTERNAL_ONLY=True lint
{{< /text >}}

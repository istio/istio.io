---
title: 添加代码块
description: 介绍如何在您的文档中添加代码。
weight: 8
keywords: [contribute, documentation, guide, code-block]
---

Istio 文档中的代码块是嵌入式预定义格式的内容块。我们使用 Hugo 构建网站，并使用
`text` 和 `text_import` 短代码将代码添加到页面中。

这样我们可以为读者提供更好的体验。渲染的代码块可以轻松地复制，打印或下载。

所有的贡献内容都必须使用这些短代码。如果您的内容未使用适当的短代码，则它不会被合并，
直到做出适当的修改。该页面包含嵌入式代码块的几个示例以及可用的格式化选项。

代码块的最常见示例是命令行界面（CLI）命令/指令，例如：

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello"
{{</* /text */>}}
{{< /text >}}

短代码要求您的每个 CLI 命令都以 `$` 开头，其渲染结果如下所示：

{{< text bash >}}
$ echo "Hello"
{{< /text >}}

您可以在一个代码块中使用多个命令，但是短代码只能识别单个输出，例如：

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{</* /text */>}}
{{< /text >}}

默认情况下，会给定并设置属性为 `bash`，这些命令将使用 bash 语法高亮显示，
并且输出将显示为纯文本，例如：

{{< text bash >}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{< /text >}}

为了便于阅读，您可以使用 `\` 在新的一行上继续长命令，新行必须缩进，例如：

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

Hugo 可以渲染续行命令：

{{< text bash >}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{< /text >}}

您的 {{<gloss workload>}}workload{{</gloss>}} 可以用各种编程语言编码。
因此，我们实现了多种对代码块中语法高亮显示的支持。

## 添加语法高亮  {#add-syntax-highlighting}

让我们从下面的 “Hello World” 例子开始：

{{< text markdown >}}
{{</* text plain */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

`plain` 属性没有对代码进行语法高亮渲染：

{{< text plain >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

您可以为代码块中的内容指定语言，以实现语法高亮。上面的例子指定了语法为 `plain`，
所有代码块的渲染结果没有任何语法高亮。但是，您可以指定其语法为 `Go`，例如：

{{< text markdown >}}
{{</* text go */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

然后，Hugo 会添加适当的语法高亮：

{{< text go >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

### 支持的语法  {#supported-syntax}

Istio 代码块目前支持下面这些语言的语法高亮：

- `plain`
- `markdown`
- `yaml`
- `json`
- `java`
- `javascript`
- `c`
- `cpp`
- `csharp`
- `go`
- `html`
- `protobuf`
- `perl`
- `docker`
- `bash`

默认情况下，CLI 命名的输出结果会按照 plain 文本进行渲染，即没有语法高亮。
如果您想为输出添加语法高亮，您可以在短代码中指定语法。在 Istio 中，最常见的例子就是
YAML 和 JSON 的输出结果，例如：

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

根据 bash 语法高亮显示命令，并根据 JSON 语法高亮显示结果。

{{< text bash json >}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{< /text >}}

## 将代码动态导入至文档  {#dynamically-import-code-into-your-document}

前面的示例显示了如何格式化文档中的代码。此外，您还可以使用 `text_import`
短代码从文件中导入内容或代码。该文件可以存储在文档存储库中，也可以存储在允许跨域访问（CORS）的外部源中。

### 从 `istio.io` 仓库中的文件导入代码  {#import-code-from-repository}

使用 `file` 属性，从 Istio 文档仓库中的一个文件中导入内容，例如：

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

上面的例子会将文件的内容渲染为存文本：

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

通过设置 `syntax=` 字段的值，指定内容的语言，可以获得语法高亮的渲染。

### 通过 URL 从外部资源导入代码  {#import-code-from-an-external-source-through-a-URL}

类似的，您可以从互联网动态的导入内容。使用 `url` 属性指定资源。
下面的例子导入了同一个文件，但它是通过 URL 导入的：

{{< text markdown >}}
{{</* text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

如您所见，渲染结果跟前面的完全相同：

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" >}}

如果文件来自其它网站，请确保目标网站允许跨域访问（CORS）。注意，这里可以使用
GitHub 原始网站（`raw.githubusercontent.com`）的内容。

### 从较大的文件导入代码片段{#snippets}

有时候，您不需要一个文件的全部内容。此时，您可以使用 **named snippets**
来控制要渲染该文件的哪一部分。用包含 `$snippet SNIPPET_NAME` 和 `$endsnippet`
标签的注释标记代码片段中所需的代码。两个标签之间的内容表示要渲染代码片段。例如，获取以下文件：

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

该文件具有三个单独的代码段：`SNIP1`、`SNIP2` 和 `SNIP3`。约定是使用全大写字母的名称。
要引用文档中的特定代码段，请将短代码中 snippet 属性的值设置为代码段的名称，例如：

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

这样代码块的渲染结果将仅包含 `SNIP1` 代码片段的内容：

{{< text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

您还可以使用 `text_import` 短代码的 `syntax` 属性为代码片段指定语法高亮。
对于包含 CLI 命令的代码片段，您可以使用 `outputis` 属性为输出结果指定语法高亮。

## 链接 GitHub 上的文件{#link-2-files}

有些代码块需要引用 [Istio 的 GitHub 仓库](https://github.com/istio/istio)中的文件。
其中最常见的情况就是引用 YAML 配置文件。无需将 YAML 文件的全部内容复制到您的代码块中，
您可以使用 `@` 符号将文件的相对路径名括起来。此标记会将路径渲染为指向 GitHub
中当前发行版本分支的文件的链接，例如：

{{< text markdown >}}
{{</* text bash */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

该路径会渲染为一个链接，可将您带到相应的文件：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

默认情况下，这些链接指向 `istio/istio` 存储库当前发行版的分支。想要让链接指向另一个
Istio 仓库，可以使用 `repo` 属性，例如：

{{< text markdown >}}
{{</* text syntax="bash" repo="api" */>}}
$ cat @README.md@
{{</* /text */>}}
{{< /text >}}

该路径将渲染为指向 `istio/api` 仓库的 `README.md` 文件的链接：

{{< text syntax="bash" repo="api" >}}
$ cat @README.md@
{{< /text >}}

有时，您的代码块会将 `@` 留作它用。您可以使用 `expandlinks` 属性打开和关闭链接扩展，例如：

{{< text markdown >}}
{{</* text syntax="bash" expandlinks="false" */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

## 高级功能{#advanced-features}

要使用更多下面介绍到的用于预定义格式内容的高级功能，请使用 `text` 序列的扩展形式，
而不是到前面介绍和展示的简化形式。展开的表单会使用标准的 HTML 属性：

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

可用的属性有：

| 属性          | 描述
|--------------|------------
|`file`        | 在代码块中显示的文件的路径。
|`url`         | 在代码块中显示的文档的 URL。
|`syntax`      | 代码块的语法。
|`outputis`    | 当语法为 bash 时，该属性指定命令输出结果的语法。
|`downloadas`  | 当用户[下载该代码块时](#download-name)默认的文件名。
|`expandlinks` | 是否在代码块中为 [GitHub 文件引用](#link-2-files)开启链接扩展。
|`snippet`     | 要从代码块中提取的内容的 [snippet](#snippets) 名称。
|`repo`        | 嵌入代码块中的仓库的 [GitHub 链接](#link-2-files)。

### 下载名  {#download-name}

您可以使用 `downloadas` 属性定义当某人下载代码块时默认的文件名，例如：

{{< text markdown >}}
{{</* text syntax="go" downloadas="hello.go" */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

如果您未指定下载的文件名，则 Hugo 会根据以下可用名称之一自动导出一个：

- 对于内联内容，使用的当前页面的标题
- 导入代码的源文件的名称
- 导入代码的源的 URL

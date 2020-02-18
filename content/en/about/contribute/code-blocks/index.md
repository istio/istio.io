---
title: Add Code Blocks
description: Explains how to include code in your documentation.
weight: 7
keywords: [contribute, documentation, guide, code-block]
---

Code blocks in the Istio documentation are embedded preformatted block of
content. We use Hugo to build our website, and it uses the `text` and
`text_import` shortcodes to add code to a page.

Using this markup allows us to provide our readers with a better experience.
The rendered code blocks can be easily copied, printed, or downloaded.

Use of these shortcodes is required for all content contributions. If your
content doesn't use the appropriate shortcodes, it won't be merged until it
does. This page contains several examples of embedded blocks and the formatting
options available.

The most common example of code blocks are Command Line Interface (CLI)
commands, for example:

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello"
{{</* /text */>}}
{{< /text >}}

The shortcode requires you to start each CLI command with a `$` and it renders the
content as follows:

{{< text bash >}}
$ echo "Hello"
{{< /text >}}

You can have multiple commands in a code block, but the shortcode only
recognizes a single output, for example:

{{< text markdown >}}
{{</* text bash */>}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{</* /text */>}}
{{< /text >}}

By default and given the set `bash` attribute, the commands render using bash
syntax highlighting and the output renders as plain text, for example:

{{< text bash >}}
$ echo "Hello" >file.txt
$ cat file.txt
Hello
{{< /text >}}

For readability, you can use `\` to continue long commands on new lines, for example:

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

Hugo renders the multi-line command without issue:

{{< text bash >}}
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
{{< /text >}}

Your {{<gloss workload>}}workloads{{</gloss>}} can be coded in various
programming languages. Therefore, we have implemented support for multiple
combinations of syntax highlighting in code blocks.

## Add syntax highlighting

Let's start with the following "Hello World" example:

{{< text markdown >}}
{{</* text plain */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

The `plain` attribute renders the code without syntax highlighting:

{{< text plain >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

You can set the language of the code in the block to highlight its syntax. The
previous example set the syntax to `plain`, and the rendered code block doesn't
have any syntax highlighting. However, you can set the syntax to GoLang, for
example:

{{< text markdown >}}
{{</* text go */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

Then, Hugo adds the appropriate highlighting:

{{< text go >}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{< /text >}}

### Supported syntax

Code blocks in Istio support the following languages with syntax highlighting:

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

By default, the output of CLI commands is considered plain text and renders
without syntax highlighting. If you need to add syntax highlighting to the
output, you can specify the language in the shortcode. In Istio, the most
common examples are YAML or JSON outputs, for example:

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

Renders the commands with bash syntax highlighting and the output with the
appropriate JASON syntax highlighting.

{{< text bash json >}}
$ kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio-mixer-type=telemetry -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"
{"level":"warn","ts":"2017-09-21T04:33:31.249Z","instance":"newlog.logentry.istio-system","destination":"details","latency":"6.848ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.291Z","instance":"newlog.logentry.istio-system","destination":"ratings","latency":"6.753ms","responseCode":200,"responseSize":48,"source":"reviews","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.263Z","instance":"newlog.logentry.istio-system","destination":"reviews","latency":"39.848ms","responseCode":200,"responseSize":379,"source":"productpage","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.239Z","instance":"newlog.logentry.istio-system","destination":"productpage","latency":"67.675ms","responseCode":200,"responseSize":5599,"source":"ingress.istio-system.svc.cluster.local","user":"unknown"}
{"level":"warn","ts":"2017-09-21T04:33:31.233Z","instance":"newlog.logentry.istio-system","destination":"ingress.istio-system.svc.cluster.local","latency":"74.47ms","responseCode":200,"responseSize":5599,"source":"unknown","user":"unknown"}
{{< /text >}}

## Dynamically import code into your document

The previous examples show how to format the code in your document.
However, you can use the `text_import` shortcode to import content or
code from a file too. The file can be stored in the documentation repository or
in an external source with Cross-Origin Resource Sharing (CORS) enabled.

### Import code from a file in the `istio.io` repository

Use the `file` attribute to import content from a file in the Istio
documentation repository, for example:

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

The example above renders the content in the file as plain text:

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

Set the language of the content through the `syntax=` field to get the
appropriate syntax highlighting.

### Import code from an external source through a URL

Similarly, you can dynamically import content from the Internet. Use the `url`
attribute to specify the source. The following example imports the same file, but
from a URL:

{{< text markdown >}}
{{</* text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" */>}}
{{< /text >}}

As you can see, the content is rendered in the same way as before:

{{< text_import url="https://raw.githubusercontent.com/istio/istio.io/master/test/snippet_example.txt" syntax="plain" >}}

If the file is from a different origin site, CORS should be enabled on that
site. Note the GitHub raw content site (`raw.githubusercontent.com`) may be used
here.

### Import a code snippet from a larger file {#snippets}

Sometimes, you don't need the contents of the entire file. You can control which
parts of the content to render using _named snippets_. Tag the code you want
in the snippet with comments containing the `$snippet SNIPPET_NAME` and
`$endsnippet` tags. The content between the two tags represents the snippet. For
example, take the following file:

{{< text_import file="test/snippet_example.txt" syntax="plain" >}}

The file has three separate snippets: `SNIP1`, `SNIP2`, and `SNIP3`. The
convention is name snippets using all caps. To reference a specific snippet in
your document, set the value of the `snippet` attribute in the shortcode to the
name of the snippet, for example:

{{< text markdown >}}
{{</* text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

The resulting code block only includes the code of the `SNIP1` snippet:

{{< text_import file="test/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

You can use the `syntax` attribute of the `text_import` shortcode to
specify the syntax of the snippet. For snippets containing CLI commands, you can
use the `outputis` attribute to specify the output's syntax.

## Link to files in GitHub {#link-2-files}

Some code blocks need to reference files from [Istio's GitHub repository](https://github.com/istio/istio).
The most common example is referencing YAML configuration files. Instead of
copying the entire contents of the YAML file into your code block, you can
surround the relative path name of the file with `@` symbols. This markup
renders the path should as a link to the file from the current release branch in
GitHub, for example:

{{< text markdown >}}
{{</* text bash */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

The path renders as a link that takes you to the corresponding file:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

By default, these links point to the current release branch of the `istio/istio`
repository. For the link to point to a different Istio repository
instead, you can use the `repo` attribute, for example:

{{< text markdown >}}
{{</* text syntax="bash" repo="api" */>}}
$ cat @README.md@
{{</* /text */>}}
{{< /text >}}

The path renders as a link to the `README.md` file of the `istio/api` repository:

{{< text syntax="bash" repo="api" >}}
$ cat @README.md@
{{< /text >}}

Sometimes, your code block uses `@` for something else. You can turn the link
expansion on and off with the `expandlinks` attribute, for example:

{{< text markdown >}}
{{</* text syntax="bash" expandlinks="false" */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

## Advanced features

To use the more advanced features for preformatted content which are described
in the following sections, use the extended form of the `text` sequence
rather than the simplified form shown so far. The expanded form uses normal HTML
attributes:

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
|`expandlinks` | Whether or not to expand [GitHub file references](#link-2-files) in the preformatted block.
|`snippet`     | The name of the [snippet](#snippets) of content to extract from the preformatted block.
|`repo`        | The repository to use for [GitHub links](#link-2-files) embedded in preformatted blocks.

### Download name

You can define the name used when someone chooses to download the code block
with the `downloadas` attribute, for example:

{{< text markdown >}}
{{</* text syntax="go" downloadas="hello.go" */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

If you don't specify a download name, Hugo derives one automatically based on
one of the following available possible names:

- The title of the current page for inline content
- The name of the file containing the imported code
- The URL of the source of the imported code

---
title: Creating and Editing Pages
description: Explains the mechanics of creating and maintaining documentation pages.
weight: 30
aliases:
    - /docs/welcome/contribute/writing-a-new-topic.html
    - /docs/reference/contribute/writing-a-new-topic.html
    - /about/contribute/writing-a-new-topic.html
keywords: [contribute]
---

This page shows how to create and maintain Istio documentation topics.

## Before you begin

Before you can work on Istio documentation, you first need to create a fork of the Istio documentation repository as described in
[Working with GitHub](/about/contribute/github/).

## Choosing a page type

As you prepare to write a new topic, think about which of these page types
is the best fit for your content:

<table>
  <tr>
    <td>Concept</td>
    <td>A concept page explains some significant aspect of Istio. For example, a concept page might describe the
    Mixer's configuration model and explain some of its subtleties.
    Typically, concept pages don't include sequences of steps, but instead provide links to
    tasks that do.</td>
  </tr>

  <tr>
    <td>Reference</td>
    <td>A reference page provides exhaustive lists of things like API parameters,
     command-line options, configuration settings, and procedures.
    </td>
  </tr>

  <tr>
    <td>Examples</td>
    <td>An example page describes a fully working stand-alone example highlighting a particular set of features. Examples
    must have easy to follow setup and usage instructions so users can quickly run the sample
    themselves and experiment with changing the example to explore the system. Examples are tested and maintained for technical accuracy.
    </td>
  </tr>

  <tr>
    <td>Task</td>
    <td>A task page shows how to do a single thing, typically by giving a short sequence of steps. Task pages have minimal
    explanation, but often provide links to conceptual topics that provide related background and knowledge. Tasks are tested and maintained for technical accuracy.</td>
  </tr>

  <tr>
    <td>Setup</td>
    <td>A setup page is similar to a task page, except that it is focused on installation
    activities. Setup pages are tested and maintained for technical accuracy.
    </td>
  </tr>

  <tr>
    <td>Blog Post</td>
    <td>
      A blog post is a timely article on Istio or products and technologies related to it. Typically, posts fall in one of the following four categories:
      <ul>
      <li>Posts detailing the author’s experience using and configuring Istio, especially those that articulate a novel experience or perspective.</li>
      <li>Posts highlighting or announcing Istio features.</li>
      <li>Posts announcing an Istio-related event.</li>
      <li>Posts detailing how to accomplish a task or fulfill a specific use case using Istio. Unlike Tasks and Examples, the technical accuracy of blog posts is not maintained and tested after publication.</li>
      </ul>
    </td>
  </tr>

  <tr>
    <td>FAQ</td>
    <td>
      A FAQ entry is for quick answers to common customer questions. An answer doesn't normally introduce any new
      concept and is instead narrowly focused on some practical bit of advice or insight, with links back into the
      main documentation for the user to learn more.
    </td>
  </tr>

  <tr>
    <td>Ops Guide</td>
    <td>
      For practical solutions to address specific problems encountered while running Istio in a real-world setting.
    </td>
  </tr>
</table>

## Naming a topic

Choose a title for your topic that has the keywords you want search engines to find.
Create a filename for your topic that uses the words in your title, separated by hyphens,
all in lower case.

## Updating front matter

Every documentation file needs to start with
[front matter](https://gohugo.io/content-management/front-matter/).
The front matter is a block of YAML that is between
triple-dashed lines at the top of each file. Here's the
chunk of front matter you should start with:

{{< text yaml >}}
---
title: <title>
description: <description>
weight: <weight>
keywords: [keyword1,keyword2,...]
---
{{< /text >}}

Copy the above at the start of your new markdown file and update the information fields.
The available front matter fields are:

|Field              | Description
|-------------------|------------
|`title`            | The short title of the page
|`subtitle`         | An optional subtitle which gets displayed below the main title
|`description`      | A one-line description of what the page is about
|`icon`             | An optional path to an image file which gets displayed next to the main title
|`weight`           | An integer used to determine the sort order of this page relative to other pages in the same directory
|`keywords`         | An array of keywords describing the page, used to create the web of See Also links
|`draft`            | When true, prevents the page from showing up in any navigation area
|`aliases`          | See [Renaming, moving, or deleting pages](#renaming-moving-or-deleting-pages) below for details on this item
|`skip_toc`         | Set this to true to prevent the page from having a table of contents generated for it
|`skip_seealso`     | Set this to true to prevent the page from having a "See also" section generated for it
|`force_inline_toc` | Set this to true to force the generated table of contents to be inserted inline in the text instead of in a sidebar
|`simple_list`      | Set this to true to force a generated section page to use a simple list layout rather that a gallery layout

There are a few more front matter fields available specifically for blog posts:

|Field          | Description
|---------------|------------
|`publishdate`  | Date of the post's original publication
|`last_update`  | Date when the post last received a major revision
|`attribution`  | Optional name of the post's author
|`twitter`      | Optional Twitter handle of the post's author

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

## Adding icons & emojis

You can embed some common icons in your content using:

{{< text markdown >}}
{{</* warning_icon */>}}
{{</* idea_icon */>}}
{{</* checkmark_icon */>}}
{{</* cancel_icon */>}}
{{</* tip_icon */>}}
{{< /text >}}

which look like {{< warning_icon >}}, {{< idea_icon >}}, {{< checkmark_icon >}}, {{< cancel_icon >}} and {{< tip_icon >}}.

In addition, you can embed an emoji in your content using a sequence such as <code>:</code><code>sailboat</code><code>:</code>
which looks like :sailboat:. Here's a handy [cheat sheet of the supported emojis](https://www.webpagefx.com/tools/emoji-cheat-sheet/).

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
produces a link to `https://raw.githubusercontent.com/istio/istio/...`

    {{< text markdown >}}
    [liveness]({{</* github_file */>}}/samples/health-check/liveness-command.yaml)
    {{< /text >}}

- **{{</* github_tree */>}}** is how you reference a directory tree in GitHub. This produces a link to
`https://github.com/istio/istio/tree/...`

    {{< text markdown >}}
    [httpbin]({{</* github_tree */>}}/samples/httpbin)
    {{< /text >}}

- **{{</* github_blob */>}}** is how you reference a file in GitHub sources. This produces a link to
`https://github.com/istio/istio/blob/...`

    {{< text markdown >}}
    [RawVM MySQL]({{</* github_blob */>}}/samples/rawvm/README.md)
    {{< /text >}}

The above annotations yield links to the appropriate branch in GitHub, relative to the branch that the
documentation is currently targeting. If you need to manually construct a URL, you can use the sequence **{{</* source_branch_name */>}}**
to get the name of the currently targeted branch.

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

You can use `plain`, `markdown`, `yaml`, `json`, `java`, `javascript`, `c`, `cpp`, `csharp`, `go`, `html`, `protobuf`,
`perl`, `docker`, and `bash`.

### Commands and command output

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

You can specify an optional third value which controls the name that the browser
will use when the user chooses to download the file. For example:

{{< text markdown >}}
{{</* text go plain "hello.go" */>}}
func HelloWorld() {
  fmt.Println("Hello World")
}
{{</* /text */>}}
{{< /text >}}

If you don't specify a third value, then the download name is derived automatically based on the
name of the current page.

### Links to GitHub files

If your code block references a file from Istio's GitHub repository, you can surround the relative path name of the file with a pair
of @ symbols. These indicate the path should be rendered as a link to the file from the current branch. For example:

{{< text markdown >}}
{{</* text bash */>}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{</* /text */>}}
{{< /text >}}

This will be rendered as:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

### Files and snippets

It is often useful to display a file or a portion of a file. You can annotate a text file to create named snippets within the file by
using the `$snippet` and `$endsnippet` annotations. For example, you could have a text file that looks like this:

{{< text_file file="examples/snippet_example.txt" syntax="plain" >}}

and in your markdown file, you can then reference a particular snippet with:

{{< text markdown >}}
{{</* text_file file="examples/snippet_example.txt" syntax="plain" snippet="SNIP1" */>}}
{{< /text >}}

where `file` specifies the relative path of the text file within the documentation repo, `syntax` specifies
the syntax to use for syntax coloring (use `plain` for generic text), and `snippet` specifies the name of the
snippet.

The above snippet produces this output:

{{< text_file file="examples/snippet_example.txt" syntax="plain" snippet="SNIP1" >}}

If you don't specify a snippet name, then the whole file will be inserted instead.

You can specify an optional `downloadas` attribute to control the name that the browser
will use when the user chooses to download the file. For example:

{{< text markdown >}}
{{</* text_file file="examples/snippet_example.txt" syntax="plain" downloadas="foo.txt" */>}}
{{< /text >}}

If you don't specify the `downloadas` attribute, then the download name is taken from the `file`
attribute instead.

A common thing to do is to copy an example script or yaml file from GitHub into the documentation
repository and then use snippets within the file to produce examples in the documentation. To pull
in annotated files from GitHub, add the needed entries at the end of the
script `scripts/grab_reference_docs.sh` in the documentation repository.

### Dynamic content

You can dynamically pull in an external file and display its content as a preformatted block. This is handy to display a
configuration file or a test file. To do so, you use a statement such as:

{{< text markdown >}}
{{</* text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" */>}}
{{< /text >}}

which produces the following result:

{{< text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" >}}

If the file is from a different origin site, CORS should be enabled on that site. Note that the
GitHub raw content site (`raw.githubusercontent.com`) may be used here.

You can specify an optional `downloadas` attribute to control the name that the browser
will use when the user chooses to download the file. For example:

{{< text markdown >}}
{{</* text_dynamic url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml" syntax="yaml" downloadas="foo.yaml" */>}}
{{< /text >}}

If you don't specify the `downloadas` attribute, then the download name is taken from the `url`
attribute instead.

## Callouts

You can bring special attention to blocks of content by highlighting warnings, ideas, and tips:

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
    - /faq
---
{{< /text >}}

With the above in a page saved as `help/faq.md`, the user will be able to access the page by going
to `istio.io/help/faq/` as normal, as well as `istio.io/faq/`.

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

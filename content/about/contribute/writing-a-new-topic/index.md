---
title: Writing a New Topic
description: Explains the mechanics of creating new documentation pages.
weight: 30
aliases:
    - /docs/welcome/contribute/writing-a-new-topic.html
---

This page shows how to create a new Istio documentation topic.

## Before you begin

You first need to create a fork of the Istio documentation repository as described in
[Creating a Doc Pull Request](/about/contribute/creating-a-pull-request/).

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
    <td>Guides</td>
    <td>A guide page describes a fully working stand-alone example highlighting a particular set of features. Guides
    must have easy to follow setup and usage instructions so users can quickly run the sample
    themselves and experiment with changing the sample to explore the system.
    </td>
  </tr>

  <tr>
    <td>Task</td>
    <td>A task page shows how to do a single thing, typically by giving a short sequence of steps. Task pages have minimal
    explanation, but often provide links to conceptual topics that provide related background and knowledge.</td>
  </tr>

  <tr>
    <td>Setup</td>
    <td>A setup page is similar to a task page, except that it is focused on installation
    activities.
    </td>
  </tr>

  <tr>
    <td>Blog Post</td>
    <td>
      A blog post is a timely article on Istio or products and technologies related to it.
    </td>
  </tr>
</table>

## Naming a topic

Choose a title for your topic that has the keywords you want search engines to find.
Create a filename for your topic that uses the words in your title, separated by hyphens,
all in lower case.

## Updating the front matter

Every documentation file needs to start with
[front matter](https://gohugo.io/content-management/front-matter/).
The front matter is a block of YAML that is between the
triple-dashed lines at the top of each file. Here's the
chunk of front matter you should start with:

```yaml
---
title: <title>
description: <description>
weight: <weight>
keywords: [keyword1,keyword2,...]
---
```

Copy the above at the start of your new markdown file and update the information fields.
The available front matter fields are:

|Field          | Description
|---------------|------------
|`title`        | The short title of the page
|`description`  | A one-line description of what the topic is about
|`weight`       | An integer used to determine the sort order of this page relative to other pages in the same directory
|`keywords`     | An array of keywords describing the page, used to create the web of See Also links
|`draft`        | When true, prevents the page from showing up in any navigation area
|`publishdate`  | For blog posts, indicates the date of publication of the post
|`subtitle`     | For blog posts, supplies an optional subtitle to be displayed below the main title
|`attribution`  | For blog posts, supplies an optional author's name
|`toc`          | Set this to false to prevent the page from having a table of contents generated for it
|`force_inline_toc` | Set this to true to force the generated table of contents from being inserted inline in the text instead of in a sidebar

## Adding images

Put image files in the same directory as your markdown file. The preferred image format is SVG.

Within markdown, use the following sequence to add the image:

```html
{{</* image width="75%" ratio="69.52%"
    link="./myfile.svg"
    alt="Alternate text to display when the image is not available"
    title="A tooltip displayed when hovering over the image"
    caption="A caption displayed under the image"
    */>}}
```

The `width`, `ratio`, `link` and `caption` values are required. If the `title` value isn't
supplied, it'll default to the same as `caption`. If the `alt` value is not supplied, it'll
default to `title` or if that's not defined, to `caption`.

`width` represents the percentage of space used by the image
relative to the surrounding text. `ratio` must be manually calculated using (image height / image width) * 100.

## Adding icons & emojis

You can embed some common icons in your content using:

```markdown
{{</* warning_icon */>}}
{{</* idea_icon */>}}
```

which look like {{< warning_icon >}} and {{< idea_icon >}}

In addition, you can embed an emoji in your content using a sequence such as <code>:</code><code>sailboat</code><code>:</code>
which looks like :sailboat:. Here's a handy [cheat sheet of the supported emojis](https://www.webpagefx.com/tools/emoji-cheat-sheet/).

## Linking to other pages

There are three types of links that can be included in documentation. Each uses a different
way to indicate the link target:

1. **Internet Link**. You use classic URL syntax, preferably with the HTTPS protocol, to reference
files on the Internet:

    ```markdown
    [see here](https://mysite/myfile.html)
    ```

1. **Relative Link**. You use relative links that start with a period to
reference any content that is at the same level as the current file, or below within
the hierarchy of the site:

    ```markdown
    [see here](./adir/anotherfile.html)
    ```

1. **Absolute Link**. You use absolute links that start with a `/` to reference content outside of the
current hierarchy:

    ```markdown
    [see here](/docs/adir/afile/)
    ```

## Embedding preformatted blocks

You can embed blocks of preformatted content using the normal markdown technique:

<pre class="language-markdown"><code>```plain
func HelloWorld() {
  fmt.Println("Hello World")
}
```
</code></pre>

The above produces this kind of output:

```plain
func HelloWorld() {
  fmt.Println("Hello World")
}
```

You must indicate the nature of the content in the preformatted block by appending a name after the initial set of tick
marks:

<pre class="language-markdown"><code>```go
func HelloWorld() {
  fmt.Println("Hello World")
}
```
</code></pre>

The above indicates the content is Go source code, which will lead to appropriate syntax coloring as shown here:

```go
func HelloWorld() {
  fmt.Println("Hello World")
}
```

You can use `markdown`, `yaml`, `json`, `java`, `javascript`, `c`, `cpp`, `csharp`, `go`, `html`, `protobuf`,
`perl`, `docker`, and `bash`, along with `command` and its variants described below.

### Showing commands and command output

If you want to show one or more bash command-lines with some output, you use the `command` indicator:

<pre class="language-markdown"><code>```command
$ echo "Hello"
Hello
```
</code></pre>

which produces:

```command
$ echo "Hello"
Hello
```

You can have as many command-lines as you want, but only one chunk of output is recognized.

<pre class="language-markdown"><code>```command
$ echo "Hello" >file.txt
$ cat file.txt
Hello
```
</code></pre>

which yields:

```command
$ echo "Hello" >file.txt
$ cat file.txt
Hello
```

You can also use line continuation in your command-lines:

```command
$ echo "Hello" \
    >file.txt
$ echo "There" >>file.txt
$ cat file.txt
Hello
There
```

If the output is the command is JSON or YAML, you can use `command-output-as-json` and `command-output-as-yaml`
instead of merely `command` in order to apply syntax coloring to the command's output.

### Showing references to Istio GitHub files

If your code block references a file from Istio's GitHub repo, you can surround the relative path name of the file with a pair
of @ symbols. These indicate the path should be rendered as a link to the file from the current branch. For example:

<pre class="language-markdown"><code>```command
$ istioctl create -f @samples/bookinfo/kube/route-rule-reviews-v3.yaml@
```
</code></pre>

This will be rendered as:

```command
$ istioctl create -f @samples/bookinfo/kube/route-rule-reviews-v3.yaml@
```

## Displaying file snippets

It is often useful to display portions of a larger file. You can annotate a text file to create named snippets within the file by
using the `$snippet` and `$endsnippet` annotations. For example, you could have a text file that looks like this:

{{< file_content file="examples/snippet_example.txt" lang="plain" >}}

and in your markdown file, you can then reference a particular snippet with:

```markdown
{{</* file_content file="examples/snippet_example.txt" lang="plain" snippet="SNIP1" */>}}
```

where `file` specifies the relative path of the text file within the documentation repo, `lang` specifies
the language to use for syntax coloring (use `plain` for generic text), and `snippet` specifies the name of the
snippet. If you omit the `snippet` attribute, then the whole file is inserted verbatim.

The above snippet produces this output:

{{< file_content file="examples/snippet_example.txt" lang="plain" snippet="SNIP1" >}}

A common thing to is to copy an example script or yaml file from GitHub into the documentation
repo and then use snippets within the file to produce examples in the documentation. To pull
in annotated files from GitHub, add the needed entries at the end of the
script `scripts/grab_reference_docs.sh` in the documentation repo.

## Displaying file content

You can pull in an external file and display its content as a preformatted block. This is handy to display a
config file or a test file. To do so, you use a statement such as:

```markdown
{{</* fetch_content url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/kube/mixer-rule-ratings-ratelimit.yaml" lang="yaml" */>}}
```

which produces the following result:

{{< fetch_content url="https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/kube/mixer-rule-ratings-ratelimit.yaml" lang="yaml" >}}

If the file is from a different origin site, CORS should be enabled on that site. Note that the
GitHub raw content site (raw.githubusercontent.com) is may be used here.

## Referencing GitHub files

When referencing files from Istio's GitHub repo, it is best to reference a specific branch in the repo. To reference the specific
branch that the documentation site is currently targeting, you use the annotation {{</* branch_name */>}}. For example:

```maerdown
See this [source file](https://github.com/istio/istio/blob/{{</* branch_name */>}}/mixer/cmd/mixs/cmd/server.go)/
```

## Renaming or moving pages

If you move pages around and would like to ensure existing links continue to work, you can add
redirects to the site very easily.

In the page that is the target of the redirect (where you'd like users to land), you simply add the
following to the front-matter:

```plain
aliases:
    - <url>
```

For example

```plain
---
title: Frequently Asked Questions
description: Questions Asked Frequently
weight: 12
aliases:
    - /faq
---

```

With the above in a page saved as _help/faq.md, the user will be able to access the page by going
to `istio.io/help/faq/` as normal, as well as `istio.io/faq/`.

You can also add many redirects like so:

```plain
---
title: Frequently Asked Questions
description: Questions Asked Frequently
weight: 12
aliases:
    - /faq
    - /faq2
    - /faq3
---

```

## Things to watch for

There are unfortunately a few complications around writing content for istio.io. You need to know about these in order for your
content to be handled correctly by the site infrastructure:

- Many example blocks in Istio start out with a `cat` command. When using `cat`, do not annotate the block as

    <pre><code>```command
    $ cat &lt;&lt;EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: wikipedia-ext
    spec:
    </code></pre>

    Instead use:

    <pre><code>```bash
    cat &lt;&lt;EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: wikipedia-ext
    spec:
    </code></pre>

    This is because the parser that handles `command` blocks will treat the multi-line input to
    the `cat` command as command output, yielding incorrect formatting.

- Example blocks that are indented within a list, contain yaml, and one of the lines of yaml starts with a `-` will confuse the markdown
parser horribly, producing garbage output. To solve this, indent the content by another four characters, relative to the <code>```</code> annotation:

    <pre class="language-markdown"><code>    - This is a bullet item

            ```yaml
                apiVersion: "config.istio.io/v1alpha2"
                kind: stackdriver
                metadata:
                  name: handler
                  namespace: istio-system
                spec:
                  project_id: "<project_id>"
                  logInfo:
                    accesslog.logentry.istio-system:
                      payloadTemplate: '{{or (.sourceIp) "-"}} - {{or (.sourceUser) "-"}} [{{or (.timestamp.Format "02/Jan/2006:15:04:05 -0700") "-"}}] "{{or (.method) "-"}} {{or (.url) "-"}} {{or (.protocol) "-"}}" {{or (.responseCode) "-"}} {{or (.responseSize) "-"}}'
                      httpMapping:
                        url: url
                        status: responseCode
                        requestSize: requestSize
                        responseSize: responseSize
                        latency: latency
                        localIp: sourceIp
                        remoteIp: destinationIp
                        method: method
                        userAgent: userAgent
                        referer: referer
                      labelNames:
                      - sourceIp
                      - destinationIp
                      - sourceService
            ```
    </code></pre>

- Make sure code blocks are always indented by a multiple of 4 spaces. Otherwise, the
indent of the code block in the rendered page will be off, and there will be spaces inserted
in the code block itself, making cut & paste not work right.

- Make sure all images have valid width and aspect ratios. Otherwise, they will render
in odd ways, depending on screen size.

- The special syntax to insert links in code blocks using `@@` annotations produces links
which are unchecked. So you can put bad links in there and tooling won't stop you. So be
careful.

---
title: Writing a New Topic
description: Explains the mechanics of creating new documentation pages.
weight: 30
redirect_from:
    - /docs/welcome/contribute/writing-a-new-topic.html
---
{% include home.html %}

This page shows how to create a new Istio documentation topic.

## Before you begin

You first need to create a fork of the Istio documentation repository as described in
[Creating a Doc Pull Request](./creating-a-pull-request.html).

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

Each page type has a template file located in the corresponding directory which shows
you the basic structure expected for topics of that type. Please start new documents by
copying the template.

## Naming a topic

Choose a title for your topic that has the keywords you want search engines to find.
Create a filename for your topic that uses the words in your title, separated by hyphens,
all in lower case.

## Updating the front matter

Every documentation file needs to start with Jekyll
[front matter](https://jekyllrb.com/docs/frontmatter/).
The front matter is a block of YAML that is between the
triple-dashed lines at the top of each file. Here's the
chunk of front matter you should start with:

```yaml
---
title: <title>
description: <overview>
weight: <order>
---
```

Copy the above at the start of your new markdown file and update
the `<title>`, `<description>` and `<weight>` fields for your particular file. The available front
matter fields are:

|Field          | Description
|---------------|------------
|`title`        | The short title of the page
|`description`  | A one-line description of what the topic is about
|`weight`       | An integer used to determine the sort order of this page relative to other pages in the same directory.
|`layout`       | Indicates which of the Jekyll layouts this page uses
|`draft`        | When true, prevents the page from showing up in any navigation area
|`publishdate` | For blog posts, indicates the date of publication of the post
|`subtitle`     | For blog posts, supplies an optional subtitle to be displayed below the main title
|`attribution`  | For blog posts, supplies an optional author's name
|`toc`          | Set this to false to prevent the page from having a table of contents generated for it
|`force_inline_toc` | Set this to true to force the generated table of contents from being inserted inline in the text instead of in a sidebar

## Choosing a directory

Depending on your page type, put your new file in a subdirectory of one of these:

- _blog/
- _docs/concepts/
- _docs/guides/
- _docs/reference/
- _docs/setup/
- _docs/tasks/

You can put your file in an existing subdirectory, or you can create a new
subdirectory. For blog posts, put the file into a subdirectory for the current
year (2017, 2018, etc)

## Adding images

Put image files in an `img` subdirectory of where you put your markdown file. The preferred image format is SVG.

If you must use a PNG or JPEG file instead, and the file
was generated from an original SVG file, please include the
SVG file in the repository even if it isn't used in the web
site itself. This is so we can update the imagery over time
if needed.

Within markdown, use the following sequence to add the image:

```html
{% raw %}
{% include image.html width="75%" ratio="69.52%"
    link="./img/myfile.svg"
    alt="Alternate text to display when the image is not available"
    title="A tooltip displayed when hovering over the image"
    caption="A caption displayed under the image"
    %}
{% endraw %}
```

The `width`, `ratio`, `link` and `caption` values are required. If the `title` value isn't
supplied, it'll default to the same as `caption`. If the `alt` value is not supplied, it'll
default to `title` or if that's not defined, to `caption`.

`width` represents the percentage of space used by the image
relative to the surrounding text. `ratio` (image height / image width) * 100.

## Linking to other pages

There are three types of links that can be included in documentation. Each uses a different
way to indicate the link target:

-   **Internet Link**. You use classic URL syntax, preferably with the HTTPS protocol, to reference
files on the Internet:

    ```markdown
    [see here](https://mysite/myfile.html)
    ```

-   **Relative Link**. You use relative links that start with a period to
reference any content that is at the same level as the current file, or below within
the hierarchy of the site:

    ```markdown
    [see here](./adir/anotherfile.html)
    ```

-   **Absolute Link**. You use absolute links with the special \{\{home\}\} notation to reference content outside of the
current hierarchy:

    ```markdown
    {% raw %}[see here]({{home}}/docs/adir/afile.html){% endraw %}
    ```

    In order to use \{\{home\}\} in a file,
    you need to make sure that the file contains the following
    line of boilerplate right after the block of front matter:

    ```markdown
    ...
    ---
    {% raw %}{% include home.html %}{% endraw %}
    ```

    Adding this include statement is what defines the `home` variable that is used in the link target.

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

## Displaying file content

You can pull in an external file and display its content as a preformatted block. This is handy to display a
config file or a test file. To do so, you use a Jekyll include statement such as:

```html
{% raw %}{% include file-content.html url='https://raw.githubusercontent.com/istio/istio/master/Makefile' %}{% endraw %}
```

which produces the following result:

{% include file-content.html url='https://raw.githubusercontent.com/istio/istio/master/Makefile' %}

If the file is from a different origin site, CORS should be enabled on that site. Note that the
GitHub raw content site (raw.githubusercontent.com) is CORS
enabled so it may be used here.

Note that unlike normal preformatted blocks, dynamically loaded preformatted blocks unfortunately
do not get syntax colored.

## Renaming or moving pages

If you move pages around and would like to ensure existing links continue to work, you can add
redirects to the site very easily.

In the page that is the target of the redirect (where you'd like users to land), you simply add the
following to the front-matter:

```plain
redirect_from:
    - <url>
```

For example

```plain
---
title: Frequently Asked Questions
description: Questions Asked Frequently
weight: 12
redirect_from:
    - /faq
---

```

With the above in a page saved as _help/faq.md, the user will be able to access the page by going
to istio.io/help/faq as normal, as well as istio.io/faq.

You can also add many redirects like so:

```plain
---
title: Frequently Asked Questions
description: Questions Asked Frequently
weight: 12
redirect_from:
    - /faq
    - /faq2
    - /faq3
---

```

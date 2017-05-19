---
title: Writing a New Topic
overview: Explains the mechanics of creating new documentation pages.
              
order: 30

layout: docs
type: markdown
---

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
    tasks or tutorials that do.</td>
  </tr>

  <tr>
    <td>Reference</td>
    <td>A reference page provides exhaustive lists of things like API parameters,
     command-line options, configuration settings, and procedures.
    </td>
  </tr>

  <tr>
    <td>Sample</td>
    <td>A sample page describes a fully working stand-alone example highlighting a particular set of features. Samples
    must have easy to follow setup and usage instructions so users can quickly run the sample
    themselves and experiment with changing the sample to explore the system.
    </td>
  </tr>

  <tr>
    <td>Task</td>
    <td>A task page shows how to do a single thing, typically by giving a short sequence of steps. Task pages have minimal
    explanation, but often provide links to conceptual topics that provide related background and knowledge.</td>
  </tr>
</table>

Each page type has a template file located in the corresponding directory which shows
you the basic structure expected for topics of that type. Please start new documents by
copying the template.

## Naming a topic

Choose a title for your topic that has the keywords you want search engines to find.
Create a filename for your topic that uses the words in your title, separated by hyphens,
all in lower case.

For example, the topic with title TBD (`[TBD](/docs/tasks/tbd.html)`)
has filename `tbd.md`. You don't need to put
"Istio" in the filename, because "Istio" is already in the
URL for the topic, for example:
```
https://istio.io/docs/tasks/tbd.html
```

## Updating the front matter

Every documentation file needs to start with Jekyll 
[front matter](https://jekyllrb.com/docs/frontmatter/).
The front matter is a block of YAML that is between the
triple-dashed lines at the top of each file. Here's the
chunk of front matter you should start with:

```
---
title: <title>
overview: <overview>

order: <order>

layout: docs
type: markdown
---
```

Copy the above at the start of your new markdown file and update
the `<title>`, `<overview>` and `<order>` fields for your particular file. The available front
matter fields are:

|Field      | Description
|-----------|------------
|`title`    | The short title of the page
|`overview` | a one-line description of what the topic is about
|`order`    | integer used for sort order
|`layout`   | indicates which of the Jekyll layouts this page uses
|`index`    | indicates whether the page should appear in the doc's top nav tabs

## Choosing a directory

Depending on your page type, put your new file in a subdirectory of one of these:

* _docs/concepts/
* _docs/reference/
* _docs/samples/
* _docs/tasks/

You can put your file in an existing subdirectory, or you can create a new
subdirectory.

## Adding images to a topic

Put image files in an `img` subdirectory of where you put your markdown file. The preferred image format is SVG.

If you must use a PNG or JPEG file instead, and the file
was generated from an original SVG file, please include the
SVG file in the repository even if it isn't used in the web
site itself. This is so we can update the imagery over time 
if needed.

Within markdown, use the `figure` element to add the image:

```html
{% raw %}<figure>
<img src="./img/myfile.svg" alt="Some description for accessibility" titla="A title displayed as a tooltip"/>
<figcaption>A caption displayed under the image</figcaption>
</figure>{% endraw %}
```

This will insert the image centered with a width of 75% and the given caption under it. You can
adjust the width using a style element such as:
 
```html
{% raw %}<figure>
<img style="max-width: 32%;" src="./img/myfile.svg" alt="Some description for accessibility" titla="A title displayed as a tooltip"/>
<figcaption>A caption displayed under the image</figcaption>
</figure>{% endraw %}
```

## Linking to other pages

There are three types of links that can be included in documentation. Each uses a different
way to indicate the link target:

- **Internet Link**. You use classic URL syntax, preferably with the HTTPS protocol, to reference
files on the Internet:

  ```markdown
  [see here](https://mysite/myfile.html)
  ```

- **Relative Link**. You use relative links that start with a period to
reference any content that is at the same level as the current file, or below within
the hierarchy of the site:

  ```markdown
  [see here](./adir/anotherfile.html)
  ```

- **Absolute Link**. You use absolute links with the special \{\{home\}\} notation to reference content outside of the
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

<pre class="language-markdown"><code>```
func HelloWorld() {
  fmt.Println("Hello World")
}
```
</code></pre>

The above produces this kind of output:

```
func HelloWorld() {
  fmt.Println("Hello World")
}
```

In general, you should indicate the nature of the content in the preformatted block. You do this
by appending a name after the initial set of tick marks

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

You can use `markdown`, `yaml`, `json`, `java`, `javascript`, `c`, `cpp`, `csharp`, `go`, `html`, `protobuf`, and `bash`.

### Displaying file content

You can pull in an external file and display its content as a preformatted block. This is handy to
display a config file or a test file. To do so, you can use normal markup and instead you need to
use direct HTML. For example:

```
<pre data-src="/repos/istio/BUILD"></pre>
```

which produces the following result:

<pre data-src="/repos/istio/BUILD"></pre>

The `data-src` attribute specifies the path to the file to display. This has to be a file within the
current site, it cannot come from a different site.

### Highlighting lines

You can highlight specific lines in a preformatted block using the `data-line` attribute:

```
<pre data-line="3"><code>This is a test
This is a test
This is a test
This is a test
</code></pre>
```

which produces the following result:

<pre data-line="3"><code>This is a test
This is a test
This is a test
This is a test
</code></pre>

See [here](http://prismjs.com/plugins/line-highlight/) for information on how to highlight multiple
lines and ranges.

### Displaying line numbers

You can display line numbers for all lines in a preformatted block using the `line-numbers` class:

```
<pre class="line-numbers"><code>This is a test
This is a test
This is a test
This is a test
</code></pre>
```

which produces the following result:

<pre class="line-numbers"><code>This is a test
This is a test
This is a test
This is a test
</code></pre>

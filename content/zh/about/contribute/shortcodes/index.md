---
title: Use Shortcodes
description: Explains the shortcodes available and how to use them.
weight: 8
aliases:
    - /docs/welcome/contribute/writing-a-new-topic.html
    - /docs/reference/contribute/writing-a-new-topic.html
    - /about/contribute/writing-a-new-topic.html
    - /create
keywords: [contribute]
---

Hugo shortcodes are special placeholders with a certain syntax that you can add
to your content  to create dynamic content experiences, such as tabs,
images and icons, links to other pages, and special content layouts.

This page explains the available shortcodes and how to use them for your
content.

## Add images

Place image files in the same directory as the markdown file using them. To make
localization easier and enhance accessibility, the preferred image
format is SVG. The following example shows the shortcode with the required
fields needed to add an image:

{{< text html >}}
{{</* image width="75%" ratio="45.34%"
    link="./<image.svg>"
    caption="<The caption displayed under the image>"
    */>}}
{{< /text >}}

The `link` and `caption` fields are required, but the shortcode also supports
optional fields, for example:

{{< text html >}}
{{</* image width="75%" ratio="45.34%"
    link="./<image.svg>"
    alt="<Alternate text used by screen readers and when loading the image fails>"
    title="<Text that appears on mouse-over>"
    caption="<The caption displayed under the image>"
    */>}}
{{< /text >}}

If you don't include the `title` field, Hugo uses the text set in `caption`. If
you don't include the `alt` field, Hugo uses the text in `title` or in `caption`
if `title` is also not defined.

The `width` field sets the size of the image relative to the surrounding text and
has a default of 100%.

The `ratio` field sets the height of the image relative to its width. Hugo
calculates this value automatically for image files in the folder.
However, you must calculate it manually for external images.
Set the value of `ratio` to `([image height]/[image width]) * 100`.

## Add icons

You can embed common icons in your content with the following content:

{{< text markdown >}}
{{</* warning_icon */>}}
{{</* idea_icon */>}}
{{</* checkmark_icon */>}}
{{</* cancel_icon */>}}
{{</* tip_icon */>}}
{{< /text >}}

The icons are rendered within the text. For example: {{< warning_icon >}},
{{< idea_icon >}}, {{< checkmark_icon >}}, {{< cancel_icon >}} and {{< tip_icon >}}.

## Add links to other pages

The Istio documentation supports three types of links depending on their target.
Each type uses a different syntax to express the target.

- **External links**. These are links to pages outside of the Istio
  documentation or the Istio GitHub repositories. Use the standard Markdown
  syntax to include the URL. Use the HTTPS protocol, when you reference files
  on the Internet, for example:

    {{< text markdown >}}
    [Descriptive text for the link](https://mysite/myfile.html)
    {{< /text >}}

- **Relative links**. These links target pages at the same level of the current
  file or further down the hierarchy. Start the path of relative links with a
  period `.`, for example:

    {{< text markdown >}}
    [This links to a sibling or child page](./sub-dir/child-page.html)
    {{< /text >}}

- **Absolute links**. These links target pages outside the hierarchy of the
  current page but within the Istio website. Start the path of absolute links
  with a slash `/`, for example:

    {{< text markdown >}}
    [This links to a page on the about section](/about/page/)
    {{< /text >}}

Regardless of type, links do not point to the `index.md` file with the content,
but to the folder containing it.

### Add links to content on GitHub

There are a few ways to reference content or files on GitHub:

- **{{</* github_file */>}}** is how you reference individual files in GitHub
  such as yaml files. This shortcode produces a link to
  `https://raw.githubusercontent.com/istio/istio*`, for example:

    {{< text markdown >}}
    [liveness]({{</* github_file */>}}/samples/health-check/liveness-command.yaml)
    {{< /text >}}

- **{{</* github_tree */>}}** is how you reference a directory tree in GitHub.
  This shortcode produces a link to `https://github.com/istio/istio/tree*`, for example:

    {{< text markdown >}}
    [httpbin]({{</* github_tree */>}}/samples/httpbin)
    {{< /text >}}

- **{{</* github_blob */>}}** is how you reference a file in GitHub sources.
  This shortcode produces a link to `https://github.com/istio/istio/blob*`, for example:

    {{< text markdown >}}
    [RawVM MySQL]({{</* github_blob */>}}/samples/rawvm/README.md)
    {{< /text >}}

The shortcodes above produce links to the appropriate branch in GitHub, based on
the branch the documentation is currently targeting. To verify which branch
is currently targeted, you can use the `{{</* source_branch_name */>}}`
shortcode to get the name of the currently targeted branch.

## Version information

To display the current Istio version in your content by retrieving the current
version from the web site, use the following shortcodes:

- `{{</* istio_version */>}}`, which renders as {{< istio_version >}}
- `{{</* istio_full_version */>}}`, which renders as {{< istio_full_version >}}

## Glossary terms

When you introduce a specialized Istio term in a page, the supplemental
acceptance criteria for contributions require you include the term in the
glossary and markup its first instance using the `{{</* gloss */>}}` shortcode.
The shortcode produces a special rendering that invites readers to click on the
term to get a pop-up with the definition. For example:

{{< text markdown >}}
Mixer uses {{</*gloss*/>}}adapters{{</*/gloss*/>}} to interface to backends.
{{< /text >}}

Is rendered as follows:

Mixer uses {{< gloss >}}adapters{{< /gloss >}} to interface to backends.

If you use a variant of the term in your text, you can still use this shortcode
to include the pop up with the definition. To specify a substitution, just
include the glossary entry within the shortcode. For example:

{{< text markdown >}}
Mixer uses an {{</*gloss adapters*/>}}adapter{{</*/gloss*/>}} to interface to a backend.
{{< /text >}}

Renders with the pop up for the `adapters` glossary entry as follows:

Mixer uses an {{< gloss adapters >}}adapter{{</ gloss >}} to interface to a backend.

## Callouts

To emphasize blocks of content, you can format them as warnings, ideas, tips, or
quotes. All callouts use very similar shortcodes:

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

The shortcodes above render as follows:

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

Use callouts sparingly. Each type of callout serves a specific purpose and
over-using them negates their intended purposes and their efficacy. Generally,
you should not include more than one callout per content file.

## Use boilerplate text

To reuse content while maintaining a single source for it, use boilerplate shortcodes. To embed
boilerplate text into any content file, use the `boilerplate` shortcode as follows:

{{< text markdown >}}
{{</* boilerplate example */>}}
{{< /text >}}

The shortcode above includes the following content from the `example.md`
Markdown file in the `/content/en/boilerplates/` folder:

{{< boilerplate example >}}

The example shows that you need to include the filename of the Markdown file
with the content you wish to insert at the current location. You can find the existing
boilerplate files are located in the `/content/en/boilerplates` directory.

## Use tabs

To display content that has multiple options or formats, use tab sets
and tabs. For example:

- Equivalent commands for different platforms
- Equivalent code samples in different languages
- Alternative configurations

To insert tabbed content, combine the `tabset` and `tabs` shortcodes,
for example:

{{< text markdown >}}
{{</* tabset category-name="platform" */>}}

{{</* tab name="One" category-value="one" */>}}
ONE
{{</* /tab */>}}

{{</* tab name="Two" category-value="two" */>}}
TWO
{{</* /tab */>}}

{{</* tab name="Three" category-value="three" */>}}
THREE
{{</* /tab */>}}

{{</* /tabset */>}}
{{< /text >}}

The shortcodes above produce the following output:

{{< tabset category-name="platform" >}}

{{< tab name="One" category-value="one" >}}
ONE
{{< /tab >}}

{{< tab name="Two" category-value="two" >}}
TWO
{{< /tab >}}

{{< tab name="Three" category-value="three" >}}
THREE
{{< /tab >}}

{{< /tabset >}}

The value of the `name` attribute of each tab contains the text displayed for
the tab. Within each tab, you can have normal Markdown content, but tabs have [limitations](#tab-limitations).

The `category-name` and `category-value` attributes are optional and make the
selected tab to stick across visits to the page. For example, a visitor selects
a tab and their selection is saved automatically with the given name and value. If
multiple tab sets use the same category name and values, their selection is
automatically synchronized across pages. This is particularly useful when there
are many tab sets in the site that hold the same types of formats.

For example, multiple tab sets could provide options for `GCP`,
`BlueMix` and `AWS`. You can set the value of the `category-name` attribute to `environment` and
the values for the `category-value` attributes to `gcp`, `bluemix`, and `aws`.
Then, when a reader selects a tab in one page, their choice will carry
throughout all tab sets across the website automatically.

### Tab limitations

You can use almost any Markdown in a tab, with the following exceptions:

- *Headers*. Headers in a tab appear in the table of contents but
  clicking on the link in the table of contents won't automatically select
  the tab.

- *Nested tab sets*. Don't nest tab sets. Doing so leads to a terrible reading
  experience and can cause significant confusion.

## Use banners and stickers

To advertise upcoming events, or publicize something
new, you can automatically insert time-sensitive banners and stickers into the
generated site in order. We've implemented the following shortcodes for promotions:

- **Countdown stickers**: They show how much time is left before a big event
  For example: "37 days left until ServiceMeshCon on March 30". Stickers have some visual
  impact for readers prior to the event and should be used sparingly.

- **Banners**: They show a prominent message to readers about a
  significant event that is about to take place, is taking place, or has taken place.
  For example "Istio 1.5 has been released, download it today!" or "Join us at ServiceMeshCon
  on March 30". Banners are full-screen slices displayed to readers during the
  event period.

To create banners and stickers, you create Markdown files in either the
`events/banners` or `events/stickers` folders. Create one Markdown file
per event with dedicated front-matter fields to control their behavior. The
following table explains the available options:

<table>
    <thead>
        <tr>
            <th>Field</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>title</code></td>
            <td>The name of the event. This is not displayed on the web site, it's intended for diagnostic messages.</td>
        </tr>
        <tr>
            <td><code>period_start</code></td>
            <td>The starting date at which to start displaying the item in <code>YYYY-MM-DD</code> format.
            Instead of a date, this can also be the value <code>latest_release</code>, which then uses the latest known
            Istio release as the start date. This is useful when creating a banner saying "Istio x.y.z has just been released".
            </td>
        </tr>
        <tr>
            <td><code>period_end</code></td>
            <td>The last date on which to display the item in <code>YYYY-MM-DD</code> format. This value is mutually
            exclusive with <code>period_duration</code> below.
            </td>
        </tr>
        <tr>
            <td><code>period_duration</code></td>
            <td>How many days to display the item to the user. This value is mutually exclusive with
            <code>period_end</code> above.
            </td>
        </tr>
        <tr>
            <td><code>max_impressions</code></td>
            <td>How many times to show the content to the user during
                the event's period. A value of 3 would mean the first three pages visited by the user during the period will display
                the content, and the content will be hidden on subsequent page loads. A value of 0, or omitting the field completely,
                results in the content being displayed on all page visits during the period.
            </td>
        </tr>
        <tr>
            <td><code>timeout</code></td>
            <td>The amount of time the content is visible to the user on a given page. After that much time passes, the item will be removed from the page.</td>
        </tr>
        <tr>
            <td><code>link</code></td>
            <td>You can specify a URL, which turns the whole item into a clickable target. When the user clicks on the item,
            the item is no longer shown to the user. The special value `latest_release` can be used here to introduce a link
            to the current release's announcement page.
            </td>
        </tr>
    </tbody>
</table>

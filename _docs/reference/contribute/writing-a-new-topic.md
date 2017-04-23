---
category: Reference
title: Writing a New Topic

parent: Contributing to the Docs
order: 30

bodyclass: docs
layout: docs
type: markdown
---

This page shows how to create a new Istio documentation topic.

## Before you begin

You first need to create a fork of the Istio documentation repository as described in
[Creating a Doc Pull Request](/docs/reference/contribute/creating-a-pull-request.html).

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

  <tr>
    <td>Tutorial</td>
    <td>A tutorial page shows how to accomplish a goal that is larger than a single task. Typically a tutorial
    page has several sections, each of which has a sequence of steps. Tutorials can include surface-level explanations,
    but should link to related conceptual topics for deep explanations.</td>
  </tr>
</table>

Each page type has a template file located in the corresponding directory which shows
you the basic structure expected for topics of that type. Please start new documents by
copying the template.

## Naming a topic

Choose a title for your topic that has the keywords you want search engines to find.
Create a filename for your topic that uses the words in your title, separated by hyphens,
all in lower case.

For example, the topic with title [TBD](/docs/tasks/tbd.html)
has filename `tbd.md`. You don't need to put
"Istio" in the filename, because "Istio" is already in the
URL for the topic, for example:
```
http://istio.io/docs/tasks/tbd.html
```

## Updating the front matter

Every documentation file needs to start with Jekyll 
[front matter](https://jekyllrb.com/docs/frontmatter/).
The front matter is a block of YAML that is between the
triple-dashed lines at the top of each file. Here's the
chunk of front matter you should start with:

    ---
    category: CATEGORY_TBD
    title: TITLE_TBD

    parent: PARENT_TBD
    order: ORDER_TBD

    bodyclass: docs
    layout: docs
    type: markdown
    ---

Copy the above at the start of your new markdown file and update
the TBD fields for your particular file. The available front
matter fields are:

|Field      | Description
|-----------|------------
|`category` | this must be there in order for the page to show up
|`index`    | indicates whether the page should appear in the doc's top nav tabs
|`order`    | integer used for sort order
|`marker`   | boolean to indicate a section separator in sidenav but NOT a page with content that is ever shown
|`parent`   | indicates that this page should be shown under another page hierarchically, basically this is a subcategory

## Choosing a directory

Depending on your page type, put your new file in a subdirectory of one of these:

* _docs/concepts/
* _docs/reference/
* _docs/samples/
* _docs/tasks/
* _docs/tutorials/

You can put your file in an existing subdirectory, or you can create a new
subdirectory.

## Adding images to a topic

Put image files in a `img/NAME` subdirectory of where you put your markdown file, where NAME corresponds to the name of your
markdown file. The preferred image format is SVG.

If you must use a PNG or JPEG file instead, and the file
was generated from an original SVG file, please include the
SVG file in the repository even if it isn't used in the web
site itself. This is so we can update the imagery over time 
if needed.

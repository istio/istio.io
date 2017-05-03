---
title: Welcome
overview: Istio documentation home page.
index: true

order: 0

layout: docs
type: markdown
---
{% assign home = "" %}
{% if site.github.environment == "dotcom" %}
{% assign home = site.baseurl %}
{% endif %}

# Welcome

Welcome to Istio's documentation home page. From here you can learn all about Istio by following
the links below:

- [Concepts]({{home}}/docs/concepts/). Concepts explain some significant aspect of Istio. This
is where you can learn about what Istio does and how it does it.

- [Tasks]({{home}}/docs/tasks/). Tasks show you how to do a single directed activity with Istio.

- [Samples]({{home}}/docs/samples/). Samples are fully working stand-alone examples
intended to highlight a particular set of Istio's features.

- [Reference]({{home}}/docs/reference/). Detailed exhaustive lists of
command-line options, configuration options, API definitions, and procedures.

We're always looking for help improving our documentation, so please don't hesitate to
[file an issue](https://github.com/istio/istio.github.io/issues/new) if you see some problem.
Or better yet, submit your own [contributions](/docs/reference/contribute/editing.html) to help
make our docs better.
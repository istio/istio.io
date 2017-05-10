---
title: Glossary
overview: A glossary of common Istio terms.

order: 40

layout: docs
type: markdown
---
{% include home.html %}

Here is a glossary of common Istio words and phrases.

{% assign words = site.glossary | sort: "title" %}
{% for w in words %}
- **{{w.title}}**.
{{w.content}}
{% endfor %}

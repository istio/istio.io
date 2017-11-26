---
title: Glossary
overview: A glossary of common Istio terms.
layout: glossary
type: markdown
---
{% include home.html %}

# Glossary

Common Istio words and phrases. Please [let us know](https://github.com/istio/istio.github.io/issues/new?title=Missing%20Glossary%20Entry) if you came here 
looking for a definition and didn't find it.

{% assign words = site.glossary | sort: "title" %}

<div class="trampolines">
  {% assign previous = "-" %}
  {% for w in words %}
    {% assign first = w.title | slice: 0 | upcase %}
    {% if first != previous %}
      {% if previous != "-" %}|{% endif %}
      <a href="#{{first}}">{{first}}</a>  
      {% assign previous = first %}
    {% endif %}
  {% endfor %}
</div>

<div class="entries">
  {% assign previous = "-" %}
  {% for w in words %}
    {% assign first = w.title | slice: 0 | upcase %}
    {% if first != previous %}
      {% if previous != "-" %}</ul>{% endif %}
      <h4 id="{{first}}">{{first}}</h4>
      <ul>
      {% assign previous = first %}
    {% endif %}

    {% assign name = w.path | downcase | split: '/' | last | remove: ".md" %}
    <li class="word" id="{{name}}">{{w.title}}</li>
    <li class="definition">{{w.content}}</li>
  
  {% endfor %}
  </ul>
</div>

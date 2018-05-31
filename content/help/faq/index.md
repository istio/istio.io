---
title: FAQ
description: Frequently Asked Questions about Istio.
weight: 20
toc: false
redirect_from:
  - /faq.html
  - /faq/index.html
  - /docs/welcome/faq.html
  - /docs/welcome/faq/index.html
  - /help/faq.html
---
{% include home.html %}

You've got questions? We've got answers!

<div class="faq">
    <div class="row">
        {% assign category_dirs = 'general,setup,security,mixer,traffic-management' %}
        {% assign category_names = 'General,Setup,Security,Mixer,Traffic Management' %}
        {% assign category_dirs = category_dirs | split: ',' %}
        {% assign category_names = category_names | split: ',' %}

        {% assign faqs = site.faq | sort: "order" %}

        {% for cat in category_dirs %}
            <div class="col-sm-6">
                <div class="card">
                    <div class="card-header">
                        {{category_names[forloop.index0]}}
                    </div>

                    <div class="card-body">
                        {% for q in faqs %}
                            {% assign comp = q.path | split: '/' %}
                            {% assign qcat = comp[1] %}
                            {% if cat == qcat %}
                                {% assign name = q.path | downcase | split: '/' | last | remove: ".md" %}

                                <a href="{{qcat}}.html#{{name}}">{{q.title}}</a><br/>
                            {% endif %}
                        {% endfor %}
                    </div>
                </div>
            </div>
        {% endfor %}
    </div>
</div>

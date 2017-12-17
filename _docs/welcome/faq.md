---
title: Frequently Asked Questions
overview: Frequently Asked Questions about Istio.

order: 20

layout: faq
type: markdown
redirect_from: /faq
toc: false
---
{% include home.html %}

{% assign faq_category_dirs = "general,setup,security,mixer,traffic-management" | split: ',' %}
{% assign faq_category_names = "General,Setup,Security,Mixer,Traffic Management" | split: ',' %}

Here are some frequently asked questions about Istio.
 
> <img src="{{home}}/img/bulb.svg" alt="Bulb" title="Help" style="width: 32px; display:inline" />
If you don't find what you're looking for here, check out our [help page]({{home}}/help).

<div class="container">
  <div class="col-md-2">
    <ul class="list-group help-group">
      <div class="faq-list list-group nav nav-tabs">
        {% assign cats = faq_category_dirs %}
        {% for cat in cats %}
          {% assign active = "" %}
          {% if forloop.index == 1 %}
            {% assign active = "active" %}
          {% endif %}
          
          <a href="#tab{{forloop.index}}" class="list-group-item {{active}}" role="tab" data-toggle="tab">{{faq_category_names[forloop.index0]}}</a>
        {% endfor %}
      </div>
    </ul>
  </div>

  <div class="col-md-8">
    <div class="tab-content panels-faq">    

      {% assign cats = faq_category_dirs %}
      {% for cat in cats %}
        {% assign catIndex = forloop.index %}
        
        {% assign active = "" %}
        {% if catIndex == 1 %}
          {% assign active = "active" %}
        {% endif %}
 
        <div class="tab-pane {{active}}" id="tab{{catIndex}}">
          <div class="panel-group" id="faq-accordion-{{catIndex}}">
          
            {% assign faqs = site.faq | sort: "order" %}
            {% for q in faqs %}
              {% assign comp = q.path | split: '/' %}
              {% assign qcat = comp[1] %}
              {% if cat == qcat %}
       	        {% assign name = q.path | downcase | split: '/' | last | remove: ".md" %}

                <div id="{{name}}" class="panel panel-default">
                  <a class="panel-title" data-toggle="collapse" data-parent="#faq-accordion-{{catIndex}}" href="#collapse{{forloop.index}}">
                    <div class="panel-heading">
                      <h4>{{q.title}}</h4>
                    </div>
                  </a>
                
                  <div id="collapse{{forloop.index}}" class="panel-collapse collapse">
                    <div class="panel-body">
                      {{q.content}}
                    </div>
                  </div>
                </div>
              {% endif %}
            {% endfor %}
          </div>
        </div>
      {% endfor %}
    </div>
  </div>
</div>

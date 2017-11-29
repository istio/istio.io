---
title: Consul - How do I unset the context changed by istioctl at the end?
order: 50
type: markdown
---
{% include home.html %}

Your ```kubectl``` is switched to use the istio context at the end of the `istio context-create` command.  You can use ```kubectl config get-contexts``` to obtain the list of contexts and ```kubectl config use-context {desired-context}``` to switch to use your desired context.

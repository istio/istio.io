---
title: FAQ
overview: Common issues, known limitations and work arounds, and other frequently asked questions on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

* _How can I view the current rules I have configured with Istio?_

  Rules can be viewed using `istioctl get routerules -o yaml` or `kubectl get routerules -o yaml`.

* _I created a weighted Route Rule to split traffic between two versions of a service but I am not seeing
  the expected behavior._
  
  For the current Envoy sidecar implementation, up to 100 requests may be required for the desired
  distribution to be observed.
  
* _How come some of my services are unreachable after creating Route Rules?_
 
  This is an known issue with the current Envoy sidecar implementation.  After two seconds of creating the 
  rule, services should become available.

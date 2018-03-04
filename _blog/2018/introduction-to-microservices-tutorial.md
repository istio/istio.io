---
title: "Introduction to Microservices with Kubernetes and Istio"
overview: Step-by-step introductory tutorial to microservices based on the Istio Bookinfo sample.
publish_date: March 1, 2018
subtitle: Step-by-step tutorial based on Istio Bookinfo
attribution: Vadim Eisenberg

order: 90

layout: blog
type: markdown
redirect_from: "/blog/introduction-to-micrioservices-tutorial.html"
---
{% include home.html %}

This tutoral demonstrates a single microservice as a web app, node.js, Docker. Then it proceeds to a whole application (Bookinfo), composed of multiple microservices, managed by Kubernetes with Istio. The learning modules show evolution of the application: development of a single microservice, creating a container, deploying the application to Kubernetes, adding Istio to the Kubernetes cluster, deploying new microservice versions, routing traffic to a new version, and finally, monitoring, logging, distributed tracing, fault injection and security policies. The Istio features are presented as part of the developing story. The focus is on why the presented Istio features are required and what can be achieved using Istio. While presenting Istio features, various microservices concepts are briefly described. In the summary module, links to further Istio documents are provided.

The ideas and scenarios were taken from the [Production-Ready Microservices](http://shop.oreilly.com/product/0636920053675.do) book of Susan Fowler and from [istio.io guides and tasks](https://istio.io).

The tutorial can be used either for self-learning microservices with Istio, or for teaching microservices with Istio. Alternatively, the tutorial can be used for quick demonstration of the most of the basic Istio features. Demonstration of the tutorial modules can take approximately two hours.

The tutorial: [istio.io/docs/tutorial]({{home}}/docs/tutorial).

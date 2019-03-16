---
title: Introduction
weight: 1
---

Step-by-step introductory tutorial to microservices based on the
[Istio Bookinfo sample](/docs/guides/bookinfo).

This tutorial demonstrates a single microservice as a web app; Node.js and Docker. Then it proceeds to a whole
application (Bookinfo), composed of multiple microservices, managed by Kubernetes with Istio. The learning modules show
evolution of the application: development of a single microservice, creating a container, deploying the application to
Kubernetes, adding Istio to the Kubernetes cluster, deploying new microservice versions, routing traffic to a new
version, and finally, monitoring, logging, distributed tracing, fault injection and security policies. The Istio
features are presented as part of the developing story. The focus is on why the presented Istio features are required
and what can be achieved using Istio. While presenting Istio features, various microservices concepts are briefly
described. In the summary module, links to further Istio documents are provided.

The tutorial can be used for self-learning, for Istio demonstration or for teaching in class by an instructor. The
tutorial supports working in separate namespaces by multiple participants simultaneously.

The ideas and scenarios were taken from the
[Production-Ready Microservices](http://shop.oreilly.com/product/0636920053675.do) book of Susan Fowler and from the
[istio.io](/) [guides](/docs/guides), [tasks](/docs/tasks) and [the istio.io blog](/blog). Some ideas were taken from
the [Istio around everything else](https://rinormaloku.com/series/istio-around-everything-else/) tutorial of Rinor
Maloku.

If you are not yet familiar with the microservices concept,
[the article by James Lewis and Martin Fowler](https://martinfowler.com/articles/microservices.html) is a good place to
start.

Proceed with the following learning modules by their order. Each module builds on the previous one.

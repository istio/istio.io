---
title: Introduction and setup
overview: This module introduces the tutorial and provides the required setup steps

order: 00

layout: docs
type: markdown
---
{% include home.html %}

# Introduction to microservices with Bookinfo sample application, Kubernetes and Istio

1. Make yourself familiar with the microservices concept. [The article of James Lewis and Martin Fowler](https://martinfowler.com/articles/microservices.html) is a good place to start.

1. Install [node.js](https://nodejs.org/en/download/), [docker](https://docs.docker.com/install/) and get access to a [Kubernetes](https://kubernetes.io) cluster. For example, you can try the [IBM Cloud Container Service](https://console.bluemix.net/docs/containers/container_index.html#container_index).

1. Download Istio and Bookinfo source:
   ```bash
   make setup
   ```
1. Alias `istioctl`:
   ```bash
   alias istioctl=$(pwd)/istio-*/bin/istioctl
   ```
2. Go over `modules`, by their prefix number, issuing `cd` to each modules's directory.

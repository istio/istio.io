---
title: Setup
overview: The required setup instructions for the tutorial.

order: 00

layout: docs
type: markdown
---
{% include home.html %}

1. Install [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git), [curl](https://curl.haxx.se/download.html), [node.js](https://nodejs.org/en/download/), [Docker](https://docs.docker.com/install/)
and get access to a [Kubernetes](https://kubernetes.io) cluster.
For example, you can try the [IBM Cloud Container Service](https://console.bluemix.net/docs/containers/container_index.html#container_index).

1. Follow the [Prerequisites of the Kubernetes Quick Start instructions]({{home}}/docs/setup/kubernetes/quick-start.html#prerequisites).

1. Follow the steps 1-4 of the [Installation Steps of the Kubernetes Quick Start instructions]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps).

1. This tutorial assumes that you perform the commands of the steps in the Istio directory that you downloaded and extracted in the steps 1 and 2 of the [Installation Steps of the Kubernetes Quick Start instructions]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps).

1. Download Istio sources into the Istio directory. **Note** that Istio source code is under [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) license.
   ```bash
   git clone https://github.com/istio/istio.git istio-sources
   ```

{% include what-is-next-footer.md %}

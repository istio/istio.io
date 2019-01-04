---
title: Setup
overview: The required setup instructions for the tutorial.

weight: 00

---

1. Install [curl](https://curl.haxx.se/download.html), [node.js](https://nodejs.org/en/download/), [Docker](https://docs.docker.com/install/)
and get access to a [Kubernetes](https://kubernetes.io) cluster.
For example, you can try the [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) or [IBM Cloud Container Service](https://console.bluemix.net/docs/containers/container_index.html#container_index).

1. Follow the [Prerequisites of the Kubernetes Quick Start instructions]({{home}}/docs/setup/kubernetes/quick-start.html#prerequisites).

1. Follow the steps 1-4 of the [Installation Steps of the Kubernetes Quick Start instructions]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps).

1. This tutorial assumes that you perform the commands of the learning modules in the Istio directory that you downloaded and extracted in the steps 1 and 2 of the [Installation Steps of the Kubernetes Quick Start instructions]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps).

1. Download Istio sources matching your Istio release version from [https://github.com/istio/istio/releases](https://github.com/istio/istio/releases). Uncompress the sources into `istio_sources` directory inside the Istio directory (see the previous list item).

1. Check the directory structure.
   1. Verify the current directory:
      ```bash
      basename $(pwd)
      ```
      If your downloaded Istio version is {{ site.data.istio.version }}, the output should be:
      ```bash
      istio-{{ site.data.istio.version }}
      ```
   2. Verify that `istio-sources` is in the current directory:
      ```bash
      ls -m
      ```
      ```bash
      LICENSE, README.md, bin, install, istio.VERSION, istio_sources, samples, tools
      ```

## What's next
Next module:     [{{page.next.title}}]({{home}}{{page.next.url}})

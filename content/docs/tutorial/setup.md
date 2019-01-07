---
title: Setup
weight: 2
---

1.  Install [curl](https://curl.haxx.se/download.html), [node.js](https://nodejs.org/en/download/), [Docker](https://docs.docker.com/install/)
and get access to a [Kubernetes](https://kubernetes.io) cluster.
For example, you can try [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) or [IBM Cloud Container Service](https://console.bluemix.net/docs/containers/container_index.html#container_index).

2.  Create a namespace for the tutorial, e.g.:

    {{< text bash >}}
    kubectl create namespace tutorial
    {{< /text >}}

3.  Create a shell variable to store the name of the namespace. All the commands in this tutorial will use this variable.

    {{< text bash >}}
    export TUTORIAL_NAMESPACE=tutorial
    {{< /text >}}

---
title: KubeSphere Container Platform
description: Instructions to setup a KubeSphere Container Platform for Istio.
weight: 18
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/kubesphere/
    - /docs/setup/kubernetes/platform-setup/kubesphere/
keywords: [platform-setup,kubesphere,kubernetes]
---

Follow these instructions to prepare an open source [KubeSphere Container Platform](https://github.com/kubesphere/kubesphere) for Istio. You can download KubeSphere to easily install a Kubernetes cluster to your Linux machines.

{{< tip >}}
KubeSphere provides [All-in-One](https://kubesphere.io/docs/v2.1/en/installation/all-in-one/) and [Multi-Node](https://kubesphere.io/docs/v2.1/en/installation/multi-node/) installation option, enables you to quickly set up and manage Kubernetes and Istio in a unified web console. This tutorial will only walk you through the All-in-One installation, see [Multi-node Installation](https://kubesphere.io/docs/v2.1/en/installation/multi-node/) for further information.
{{< /tip >}}

## Prerequisites

A new Linux machine (64 bit), supports VM or BM, at least 2 CPUs and 4 GB of memory, currently it supports following OS:


- CentOS 7.4 ~ 7.7
- Ubuntu 16.04/18.04 LTS
- RHEL 7.4
- Debian Stretch 9.5


{{< tip >}}
We suggest you to disable and stop the firewall, instead, if your network configuration uses an firewall, you must ensure it meets the [port requirements](https://kubesphere.io/docs/v2.1/en/installation/port-firewall/).
{{< /tip >}}

## Provisioning Kubernetes Cluster

1. Download KubeSphere to your Linux machine, it can help you to create a standard Kubernetes cluster (v1.15 by default, it also supports v1.13 and v1.14).

    {{< text bash >}}
    $ curl -L https://kubesphere.io/download/stable/v2.1.0 > installer.tar.gz \
    && tar -zxf installer.tar.gz && cd kubesphere-all-v2.1.0/scripts
    $ ./install.sh
    {{< /text >}}

1. Run the following script and choose **"1) All-in-one"** to start.

    {{< text bash >}}
    $ ./install.sh
    {{< /text >}}

1. Please wait for a cup of coffee until all Pods are running, then you'll be able to access the console with the default account as following. At the same time, Kubernetes 1.15 has been installed into your environment.

    {{< text plain >}}
    #####################################################
    ###              Welcome to KubeSphere!           ###
    #####################################################
    Console: http://192.168.0.8:30880
    Account: admin
    Password: P@88w0rd
    {{< /text >}}

    ![KubeSphere Console](images/kubesphere-console.png)


## Enable installing Istio on Kubernetes

BTW, KubeSphere can also help you to install Istio to Kubernetes, see [Enable Service Mesh Installation](https://kubesphere.io/docs/v2.1/en/installation/install-servicemesh/) for further information.

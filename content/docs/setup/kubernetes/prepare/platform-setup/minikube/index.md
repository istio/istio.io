---
title: Minikube
description: Instructions to setup Minikube for use with Istio.
weight: 21
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/platform-setup/minikube/
keywords: [platform-setup,kubernetes,minikube]
---

Follow these instructions to prepare Minikube for Istio installation with sufficient
resources to run Istio and some basic applications.

1. To run Istio locally, install the latest version of
   [Minikube](https://kubernetes.io/docs/setup/minikube/), version **0.28.1 or
   later**.

1. Select a [Minikube VM driver](https://kubernetes.io/docs/setup/minikube/#quickstart)
   and install it using the driver installation techniques.  Finally export the
   driver to the environment.  An example using kvm2 driver is:

    {{< text bash >}}
    $ export MINIKUBE_VM_DIVER=kvm2
    {{< /text >}}

    {{< idea >}}
    You may additionally choose to add the `MINIKUBE_VM_DRIVER` export to your `.profile` shell.  By
    adding this environment variable to your shell, the variable will not need to be set each time
    you start minikube.
    {{< /idea >}}

1. Start Minikube with 8192 `MB` of memory and 4 `CPUs`.  This example uses Kuberenetes
   vesion 1.13.0, however, you may alter the version to Kubernetes versions of Istio that are
   supported:

    {{< text bash >}}
    $ minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.13.0 \
        --vm-driver=$MINIKUBE_VM_DRIVER
    {{< /text >}}

1. (Optional) If you want a Load balancer in Minikube, you can use the
   [Minikube Tunnel](https://github.com/kubernetes/minikube/blob/master/docs/tunnel.md).

    {{< text bash >}}
    $ minikube tunnel
    {{< /text >}}

    {{< tip >}}
    Running the minikube tunnel feature will block your shell and output diagonstic information.  Be
    prepared to run this optional command in a different shell.
    {{< /tip >}}

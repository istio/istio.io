---
title: Platform setup for Minikube
description: Instructions to setup Minikube for use with Istio
weight: 10
keywords: [kubernetes,minikube]
---

To setup the Kubernetes cluster for Istio with Minikube, follow these instructions:

1. To run Istio locally, install the latest version of
   [Minikube](https://kubernetes.io/docs/setup/minikube/), version **0.28.0 or
   later**.

1. Select a
   [VM driver](https://kubernetes.io/docs/setup/minikube/#quickstart)
   and substitute `your_vm_driver_choice` below with the installed virtual
   machine (VM) driver.

    On Kubernetes **1.9**:

    {{< text bash >}}
    $ minikube start --memory=4096 --kubernetes-version=v1.9.4 --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

    On Kubernetes **1.10**:

    {{< text bash >}}
    $ minikube start --memory=4096 --kubernetes-version=v1.10.0 --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

---
title: Minikube
description: Instructions to setup Minikube for use with Istio.
weight: 21
skip_seealso: true
keywords: [platform-setup,kubernetes,minikube]
---

Follow these instructions to prepare Minikube for Istio.

1. To run Istio locally, install the latest version of
   [Minikube](https://kubernetes.io/docs/setup/minikube/), version **0.28.1 or
   later**.

1. Select a
   [VM driver](https://kubernetes.io/docs/setup/minikube/#quickstart)
   and substitute `your_vm_driver_choice` below with the installed virtual
   machine (VM) driver. To install Istio control plane components and addons,
   as well as other applications,
   we recommend starting Minikube with 8192 `MB` of memory and 4 `CPUs`:

    On Kubernetes **1.9**:

    {{< text bash >}}
    $ minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.9.4 \
        --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota" \
        --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

    On Kubernetes **1.10**:

    {{< text bash >}}
    $ minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.10.0 \
        --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

---
title: Minikube
description: Instructions to setup minikube for use with Istio.
weight: 21
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/minikube/
keywords: [platform-setup,kubernetes,minikube]
---

Follow these instructions to prepare minikube for Istio installation with sufficient
resources to run Istio and some basic applications.

{{< warning >}}
Administrative privileges are required to run minikube.
{{< /warning >}}

1.  Install the latest version of
    [minikube](https://kubernetes.io/docs/setup/minikube/), version **1.1.1 or
    later**, and a
    [minikube hypervisor driver](https://kubernetes.io/docs/tasks/tools/install-minikube/#install-a-hypervisor).

1.  If you're not using the default driver, set your minikube hypervisor driver.

    For example, if you installed the KVM hypervisor, set the `vm-driver`
    within the minikube configuration using the following command:

    {{< text bash >}}
    $ minikube config set vm-driver kvm2
    {{< /text >}}

1.  Start minikube with 16384 `MB` of memory and 4 `CPUs`. This example uses Kubernetes version **1.14.2**.
    You can change the version to any Kubernetes version supported by Istio by altering the
    `--kubernetes-version` value:

    {{< text bash >}}
    $ minikube start --memory=16384 --cpus=4 --kubernetes-version=v1.14.2
    {{< /text >}}

    Depending on the hypervisor you use and the platform on which the hypervisor
    is run, minimum memory requirements vary. 16384 `MB` is sufficent to run
    Istio and bookinfo.

    {{< tip >}}
    If you don't have enough ram allocated to the minikube
    virtual machine, the following errors could occur:

    - image pull failures
    - healthcheck timeout failures
    - kubectl failures on the host
    - general network instability of the virtual machine and the host
    - complete lock-up of the virtual machine
    - host NMI watchdog reboots

    One effective way to monitor memory usage in minikube:

    {{< text bash >}}
    $ minikube ssh
    $ top
    GiB Mem : 12.4/15.7
    {{< /text >}}

    This shows 12.4GiB used of an available 15.7 GiB RAM within the virtual
    machine.  This data was generated with the VMWare Fusion hypervisor on a
    Macbook Pro 13" with 16GiB RAM running Istio 1.2 with bookinfo installed.
    {{< /tip >}}

1.  (Optional, recommended) If you want minikube to provide a load balancer for use
    by Istio, you can use the
    [minikube tunnel](https://github.com/kubernetes/minikube/blob/master/docs/tunnel.md) feature.
    Run this command in a different terminal, because the minikube tunnel feature will block your
    terminal to output diagnostic information about the network:

    {{< text bash >}}
    $ sudo minikube tunnel
    {{< /text >}}

    {{< warning >}}
    Sometimes minikube does not clean up the tunnel network properly. To force a proper
    cleanup:

    {{< text bash >}}
    $ sudo minikube tunnel --cleanup
    {{< /text >}}

    {{< /warning >}}

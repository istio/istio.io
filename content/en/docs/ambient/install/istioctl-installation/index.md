---
title: Install with Istio CLI
description: Install Istio in ambient mode with istio CLI.
weight: 4
owner: istio/wg-environments-maintainers
aliases:
  - /docs/ops/ambient/install/istioctl-installation
  - /latest/docs/ops/ambient/install/istioctl-installation
test: yes
---

This guide shows you how to install Istio in ambient mode with `istioctl`.
Aside from following the demo in [Getting Started with Ambient Mode](/docs/ambient/getting-started/), we encourage the use of Helm to [install Istio for use in ambient mode](/docs/ambient/install/helm-installation). Helm helps you manage components separately, and you can easily upgrade the components to the latest version.

## Prerequisites

1. Check the [Platform-Specific Prerequisites](/docs/ambient/install/platform-prerequisites).

1. Download the [latest version of Istio](/docs/setup/getting-started/#download).

## Install

{{< text syntax=bash snip_id=install_istio >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

After running the above command, you’ll get the following output that indicates
four components (including {{< gloss "ztunnel" >}}ztunnel{{< /gloss >}}) have been installed successfully!

{{< text syntax=plain snip_id=check_installed >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

## Verify the installation

### Verify the components status

Verify the installed components using the following commands:

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-d9rdt      1/1     Running   0          2m15s
istiod-56d848857c-pwsd6   1/1     Running   0          2m23s
ztunnel-wp7hk             1/1     Running   0          2m9s
{{< /text >}}

{{< text syntax=bash snip_id=check_daemonsets >}}
$ kubectl get daemonset -n istio-system
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m16s
ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
{{< /text >}}

### Verify with the sample application

After installing ambient mode with istio CLI, you can follow the [Deploy the sample application](/docs/ambient/getting-started/#bookinfo) guide to deploy the sample application and ingress gateways, and then you can
[add your application to the ambient mesh](/docs/ambient/getting-started/#addtoambient).

## Uninstall

You can uninstall Istio and its components using the following commands.

1. Remove waypoint proxies, installed policies, and uninstall Istio:

    {{< text syntax=bash snip_id=uninstall_istio >}}
    $ istioctl uninstall -y --purge
    {{< /text >}}

1. Delete the `istio-system` namespace:

    {{< text syntax=bash snip_id=delete_istio_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

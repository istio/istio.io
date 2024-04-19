---
title: Install with Istioctl
description: Install Istio in ambient mode with istioctl.
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

1. Install the [latest version of Istio](/docs/setup/getting-started/#download).

1. Install the Kubernetes Gateway API CRDs, which don’t come installed by default on most Kubernetes clusters:

    {{< text bash >}}
    $ kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
    {{< /text >}}

    {{< tip >}}
    {{< boilerplate gateway-api-future >}}
    {{< boilerplate gateway-api-choose >}}
    {{< /tip >}}

## Install

{{< text bash >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

After running the above command, you’ll get the following output that indicates
four components (including {{< gloss "ztunnel" >}}ztunnel{{< /gloss >}}) have been installed successfully!

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

## Verify the installation

### Verify the components status

Verify the installed components using the following commands:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-d9rdt      1/1     Running   0          2m15s
istiod-56d848857c-pwsd6   1/1     Running   0          2m23s
ztunnel-wp7hk             1/1     Running   0          2m9s
{{< /text >}}

{{< text bash >}}
$ kubectl get daemonset -n istio-system
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m16s
ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
{{< /text >}}

### Verify with the sample application

After installing ambient mode with `istioctl`, you can follow the [Deploy the sample application](/docs/ambient/getting-started/#bookinfo) guide to deploy the sample application and ingress gateways, and then you can
[add your application to the ambient mesh](/docs/ambient/getting-started/#addtoambient).

## Uninstall

You can uninstall Istio and its components using the following commands.

1. Remove the Bookinfo sample application and its configuration, see [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup).

1. Remove the label (Optional)

    The label to instruct Istio to automatically include applications in the `default` namespace to an ambient mesh is not removed by default. If no longer needed, use the following command to remove it:

    {{< text bash >}}
    $ kubectl label namespace default istio.io/dataplane-mode-
    {{< /text >}}

    With the label removed, we can check the logs once again to verify the proxy removal:

    {{< text bash >}}
    $ kubectl logs ds/ztunnel -n istio-system  | grep inpod
    Found 3 pods, using pod/ztunnel-jrxln
    inpod_enabled: true
    inpod_uds: /var/run/ztunnel/ztunnel.sock
    inpod_port_reuse: true
    inpod_mark: 1337
    2024-03-26T00:02:06.161802Z  INFO ztunnel::inpod::workloadmanager: handling new stream
    2024-03-26T00:02:06.162099Z  INFO ztunnel::inpod::statemanager: pod received snapshot sent
    2024-03-26T00:41:05.518194Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("7ef61e18-725a-4726-84fa-05fc2a440879") received netns, starting proxy
    2024-03-26T00:50:14.856284Z  INFO ztunnel::inpod::statemanager: pod delete request, draining proxy
    {{< /text >}}

1. Remove waypoint proxies, installed policies, and uninstall Istio:

    {{< text bash >}}
    $ istioctl x waypoint delete --all
    $ istioctl uninstall -y --purge
    $ kubectl delete namespace istio-system
    {{< /text >}}

1. Remove the Gateway API CRDs (optional)

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}

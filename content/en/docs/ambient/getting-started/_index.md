---
title: Getting Started
description: How to deploy and install Istio in ambient mode.
weight: 2
aliases:
  - /docs/ops/ambient/getting-started
  - /latest/docs/ops/ambient/getting-started
owner: istio/wg-networking-maintainers
skip_list: true
test: yes
---

This guide lets you quickly evaluate Istio's {{< gloss "ambient" >}}ambient mode{{< /gloss >}}. You'll need a Kubernetes cluster to proceed. If you don't have a cluster, you can use [kind](/docs/setup/platform-setup/kind) or any other [supported Kubernetes platform](/docs/setup/platform-setup).

These steps require you to have a {{< gloss >}}cluster{{< /gloss >}} running a
[supported version](/docs/releases/supported-releases#support-status-of-istio-releases) of Kubernetes ({{< supported_kubernetes_versions >}}).

## Download the Istio CLI

Istio is configured using a command line tool called `istioctl`.  Download it, and the Istio sample applications:

{{< text syntax=bash snip_id=none >}}
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-{{< istio_full_version >}}
$ export PATH=$PWD/bin:$PATH
{{< /text >}}

Check that you are able to run `istioctl` by printing the version of the command. At this point, Istio is not installed in your cluster, so you will see that there are no pods ready.

{{< text syntax=bash snip_id=none >}}
$ istioctl version
no ready Istio pods in "istio-system"
{{< istio_full_version >}}
{{< /text >}}

## Install Istio on to your cluster

`istioctl` supports a number of [configuration profiles](/docs/setup/additional-setup/config-profiles/) that include different default options, and can be customized for your production needs. Support for ambient mode is included in the `ambient` profile. Install Istio with the following command:

{{< text syntax=bash snip_id=install_ambient >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

It might take a minute for the Istio components to be installed. Once the installation completes, you’ll get the following output that indicates all components have been installed successfully.

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

{{< tip >}}
You can verify the installed components using the command `istioctl verify-install`.
{{< /tip >}}

## Install the Kubernetes Gateway API CRDs

You need to install the Kubernetes Gateway API CRDs, which don’t come installed by default on most Kubernetes clusters:

{{< text syntax=bash snip_id=install_k8s_gateway_api >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.1.0" | kubectl apply -f -; }
{{< /text >}}

You will use the Kubernetes Gateway API to configure traffic routing.

## Next steps

Congratulations! You've successfully installed Istio with support for ambient mode. Continue to the next step to [install the demo application and add it to the ambient mesh](/docs/ambient/getting-started/deploy-sample-app/).

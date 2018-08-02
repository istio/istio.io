---
title: Quick Start with AliCloud Kubernetes Container Service
description: Quick Start instructions to setup the Istio service using AliCloud Kubernetes Container Service
weight: 12
keywords: [kubernetes,alicloud,aliyun]
---

Quick Start instructions to install and run Istio in [AliCloud Kubernetes Container Service](https://cs.console.aliyun.com/) using Application Catalog.

This Quick Start installs the current release version of Istio and then deploys the [Bookinfo](/docs/examples/bookinfo/) sample
application.  It uses Application Catalog to automate the steps detailed in the [Istio on Kubernetes setup guide](/docs/setup/kubernetes/quick-start/) for Kubernetes Engine.

## Prerequisites

- This sample assumes that you already have an avaiable AliCloud Kubernetes cluster. Otherwise, you can create a Kubernetes cluster quickly and easily in the Container Service console.

- Make sure that `kubectl` can work fine for your Kubernetes cluster.

- Create a namespace to deploy Istio components, e.g. `istio-system`:

{{< text bash >}}
    $ kubectl create namespace istio-system
{{< /text >}}

- If a service account has not already been installed for Tiller, install one:

{{< text bash >}}
    $ kubectl create -f install/kubernetes/helm/helm-service-account.yaml
{{< /text >}}

- Install Tiller on your cluster with the service account:

{{< text bash >}}
    $ helm init --service-account tiller
{{< /text >}}

## Setup

### Deploy Istio through Application Catalog

-  Log on to the AliCloud Container Service console, and click `Application Catalog` in the left navigation pane, then select `ack-istio` in the right panel.

{{< image width="100%" ratio="67.17%"
    link="./app-catalog-istio.png"
    caption="Istio"
    >}}

-  Customization with Parameters

The Helm chart ships with reasonable default configuration options which are explained in the following table:

| Parameter                            | Description                                                  | Default                                    |
| ------------------------------------ | ------------------------------------------------------------ | ------------------------------------------ |
| `global.hub` | Specifies the HUB for most images used by Istio | registry.cn-hangzhou.aliyuncs.com/aliacs-app-catalog |
| `global.tag`                     | Specifies the TAG for most images used by Istio |    0.8       |
| `global.proxy.image`             | Specifies the proxy image name         | istio-proxyv2         |
| `global.imagePullPolicy`       | Specifies the image pull policy          | `IfNotPresent`        |
| `global.controlPlaneSecurityEnabled` | Specifies whether control plane mTLS is enabled | `false` |
| `global.mtls.enabled`        | Specifies whether mTLS is enabled by default between services| `false`  |
| `global.mtls.mtlsExcludedServices`  | List of FQDNs to exclude from mTLS | -"kubernetes.default.svc.cluster.local" |
| `global.rbacEnabled` | Specifies whether to create Istio RBAC rules or not | `true` |
| `global.refreshInterval` | Specifies the mesh discovery refresh interval | `10s` |
| `global.arch.amd64` | Specifies the scheduling policy for amd64 architectures | `2` |
| `global.arch.s390x` | Specifies the scheduling policy for s390x architectures | `2` |
| `global.arch.ppc64le` | Specifies the scheduling policy for ppc64le architectures| `2` |
| `galley.enabled` | Specifies whether Galley should be installed for server-side config validation. Requires k8s >= 1.9 | `false` |

The Helm chart also offers significant customization options per individual service. Customize these per-service options at your own risk. The per-service options are exposed via the Parameters tab.

Wait until Istio is fully deployed. Note that this can take up to several minutes.

## What's next

You can further explore the Istio functionality by following any of the tutorials in the [Guides](/docs/guides/) section. However, to do this you need to install `istioctl` to interact with Istio.

The articles in this [series](https://yq.aliyun.com/articles/599874) provide detailed instructions about how to use Istio on AliCloud Kubernetes Container Service.

## Uninstalling

1. Navigate to the Release section of the AliCloud Container Service console at [https://cs.console.aliyun.com/#/k8s/release/list](https://cs.console.aliyun.com/#/k8s/release/list)

1. Select the Release and click **Delete**. This will remove all the deployed Istio artifacts.
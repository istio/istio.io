---
title: Quick Start with Alibaba Cloud Kubernetes Container Service
description: Quick Start instructions to setup the Istio service using Alibaba Cloud Kubernetes Container Service.
weight: 12
keywords: [kubernetes,alicloud,aliyun]
---

Follow these instructions to install and run Istio in the
[Alibaba Cloud Kubernetes Container Service](https://www.alibabacloud.com/product/kubernetes)
using the `Application Catalog` module.

This guide installs the current release version of Istio and deploys the
[Bookinfo](/docs/examples/bookinfo/) sample application.

## Prerequisites

- You have an available Alibaba Cloud Kubernetes cluster. Otherwise, create a
Kubernetes cluster quickly and easily in the `Container Service console`.

- Ensure `kubectl` works fine for your Kubernetes cluster.

- You can create a namespace to deploy Istio components. The following example
 creates the `istio-system` namespace:

{{< text bash >}}
$ kubectl create namespace istio-system
{{< /text >}}

- You installed a service account for Tiller. To install one if you haven't,
run the following command:

{{< text bash >}}
$ kubectl create -f install/kubernetes/helm/helm-service-account.yaml
{{< /text >}}

- You installed Tiller on your cluster. To install Tiller with the service
account if you haven't, run the following command:

{{< text bash >}}
$ helm init --service-account tiller
{{< /text >}}

## Deploy Istio via the Application Catalog

- Log on to the **Alibaba Cloud Container Service** console.
- Click **Application Catalog** in the left navigation pane.
- Select the **ack-istio** in the right panel.

{{< image width="100%" ratio="67.17%"
    link="./app-catalog-istio-1.0.0.png"
    caption="Istio"
    >}}

### Customize the installation with parameters

The following table explains the default configuration options shipped with Helm chart:

| Parameter                            | Description                                                  | Default                                    |
| ------------------------------------ | ------------------------------------------------------------ | ------------------------------------------ |
| `global.hub` | Specifies the images hub for Istio | `registry.cn-hangzhou.aliyuncs.com/aliacs-app-catalog` |
| `global.tag`                     | Specifies the TAG for most images used by Istio |    0.8       |
| `global.proxy.image`             | Specifies the proxy image name         | `proxyv2`        |
| `global.imagePullPolicy`       | Specifies the image pull policy          | `IfNotPresent`        |
| `global.controlPlaneSecurityEnabled` | Specifies whether control plane `mTLS` is enabled | `false` |
| `global.mtls.enabled`        | Specifies whether `mTLS` is enabled by default between services| `false`  |
| `global.mtls.mtlsExcludedServices`  | List of `FQDNs` to exclude from `mTLS` | -`kubernetes.default.svc.cluster.local` |
| `global.rbacEnabled` | Specifies whether to create Istio RBAC rules or not | `true` |
| `global.refreshInterval` | Specifies the mesh discovery refresh interval | `10s` |
| `global.arch.amd64` | Specifies the scheduling policy for `amd64` architectures | `2` |
| `global.arch.s390x` | Specifies the scheduling policy for `s390x` architectures | `2` |
| `global.arch.ppc64le` | Specifies the scheduling policy for `ppc64le` architectures| `2` |

The Parameters tab exposes the per-service options.

{{< idea_icon >}} Before moving on, wait until Istio is fully deployed.
Deployment can take up to several minutes.

## What's next

To further explore the Istio functionality, follow any of the tutorials in the
[Guides](/docs/guides/) section. Before you do, install `istioctl` to interact
with Istio.

Next, you can follow the detailed instructions on
[how to use Istio on Alibaba Cloud Kubernetes Container Service](https://yq.aliyun.com/articles/599874).

## Uninstalling

1. Visit [the Release section of the Alibaba Cloud Container Service console](https://www.alibabacloud.com/product/kubernetes).

1. Select the release where you wish to uninstall Istio.

1. Click the **Delete** button to remove all the deployed Istio artifacts.

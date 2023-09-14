---
title: Installing Ambient Mesh with Helm
description: How to install Ambient Mesh with Helm.
weight: 4
owner: istio/wg-environments-maintainers
test: n/a
---

This guide shows you how to install Ambient Mesh with Helm.
Besides the demo in [Getting Started with Ambient Mesh](/docs/ops/ambient/getting-started/),
we **encourage** you to follow this guide to install Ambient Mesh.
Helm helps you manage components separately, and you can easily upgrade the components to the latest version.

## Setup Repo Info

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}

*See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation.*

## Installing the Components

### Installing Base Component

The **Base** chart contains the basic CRDs and cluster roles required to set up Istio.
This should be installed prior to any other Istio component.

{{< text bash >}}
$ helm install istio-base istio/base
{{< /text >}}

### Installing CNI Component

The **CNI** chart installs the Istio CNI Plugin. There are some main roles of Istio CNI Plugin:
- Eliminates the need for the `istio-init` container that sets up traffic routing for sidecar proxies.
- In Ambient, it is responsible for detecting the pods that belong to the ambient mesh, and configuring 
  the traffic redirection between the ztunnels - which will be installed later.

{{< text bash >}}
$ helm install istio-cni istio/cni -n kube-system \
    --set cni.ambient.enabled=true \
    --set cni.logLevel=info \
    --set cni.privileged=true \
    --set 'cni.excludeNamespaces={kube-system}'
{{< /text >}}

### Installing Istiod Component

The **Istiod** chart installs a revision of Istiod. Istiod is the control plane component that manages and 
configures the proxies to route traffic within the mesh.

{{< text bash >}}
$ kubectl create namespace istio-system
$ helm install istiod istio/istiod --namespace istio-system \
    --set defaultRevision="" \
    --set meshConfig.defaultConfig.proxyMetadata.ISTIO_META_ENABLE_HBONE=true \
    --set 'meshConfig.defaultProviders.metrics[0]=prometheus' \
    --set 'meshConfig.extensionProviders[0].name=prometheus' \
    --set 'meshConfig.extensionProviders[0].prometheus={}' \
    --set 'pilot.env.VERIFY_CERTIFICATE_AT_CLIENT=true' \
    --set 'pilot.env.ENABLE_AUTO_SNI=true' \
    --set 'pilot.env.PILOT_ENABLE_HBONE=true' \
    --set 'pilot.env.PILOT_ENABLE_AMBIENT_CONTROLLERS=true' \
    --set 'pilot.env.CA_TRUSTED_NODE_ACCOUNTS=istio-system/ztunnel\,kube-system/ztunnel' \
    --set istio_cni.enabled=true \
    --set telemetry.enabled=false \
    --set telemetry.v2.enabled=false
{{< /text >}}

### Installing Ztunnel Component

The **Ztunnel** chart installs a ztunnel, which is the node-proxy component in Ambient.

{{< text bash >}}
$ helm install ztunnel istio/ztunnel -n istio-system
{{< /text >}}

## Verifying the Installation

After installing all the components, you can check the helm deployment status:

{{< text bash >}}
$ helm list -n istio-system
{{< /text >}}

You can check the status of the pods deployed:

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}

## Configuration

To view support configuration options and documentation, run:

{{< text bash >}}
$ helm show values istio/istiod
{{< /text >}}

---
title: Installation Configuration Profiles
description: Describes the built-in Istio installation configuration profiles.
weight: 35
aliases:
    - /docs/setup/kubernetes/additional-setup/config-profiles/
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

This page describes the built-in configuration profiles that can be used when
[installing Istio](/es/docs/setup/install).

Configuration profiles are simply named groups of Helm chart value overrides that are built into the charts,
and can be used when installing via either `helm` or `istioctl`.

The profiles provide high-level customization of the Istio control plane and data plane for common deployment topologies and target platforms.

{{< tip >}}
Configuration profiles compose with other values overrides or flags, so any individual value a configuration profile sets can be manually overridden by specifying a `--set` flag after it in the command.
{{< /tip >}}

There are 2 kinds of configuration profiles: _deployment_ profiles and _platform_ profiles, and using both is recommended.

- _deployment_ profiles are intended to provide good defaults for a given deployment topology (`default`, `remote`, `ambient`, etc).
- _platform_ profiles are intended to provide necessary platform-specific defaults, for a given target platform (`eks`, `gke`, `openshift`, etc).

For example, if you are installing `default` sidecar data plane on GKE, we recommend using the following deployment and platform profiles to get started:

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

    For Helm, supply the same `profile` and `platform` for every chart you install, for example `istiod`:

    {{< text syntax=bash snip_id=install_istiod_helm_platform >}}
    $ helm install istiod istio/istiod -n istio-system --set profile=default --set global.platform=gke --wait
    {{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

    For `istioctl`, supply the same `profile` and `platform` as arguments:

    {{< text syntax=bash snip_id=install_istiod_istioctl_platform >}}
    $ istioctl install --set profile=default --set values.global.platform=gke
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< warning >}}
Note that a key difference between `helm` and `istioctl` install mechanisms is that `istioctl` configuration profiles also include a list of Istio components that will be installed automatically by `istioctl`.

With `helm`, this is not the case - users are expected to install each required Istio component individually via `helm install`, and supply the desired configuration profile flags for each component manually.

You can think of this as `istioctl` and `helm` sharing exactly the same configuration profiles with the same names, but when you use `istioctl`, it will additionally choose what components to install for you based on the configuration profile you select, so only one command is needed to achieve the same result.
{{< /warning >}}

## Deployment Profiles

The following built-in deployment profiles are currently available for both `istioctl` and `helm` install mechanisms. Note that as these are just sets of Helm values overrides, using them is not strictly required to install Istio, but they do provide a convenient baseline and are recommended for new installs. Additionally, you may [customize the configuration](/es/docs/setup/additional-setup/customize-installation/)
beyond what the deployment profile includes, for your specific needs. The following built-in deployment profiles are currently available:

1. **default**: enables components according to the default settings of the
    [`IstioOperator` API](/es/docs/reference/config/istio.operator.v1alpha1/).
    This profile is recommended for production deployments and for
    {{< gloss "primary cluster" >}}primary clusters{{< /gloss >}} in a
    [multicluster mesh](/es/docs/ops/deployment/deployment-models/#multiple-clusters).

1. **demo**: configuration designed to showcase Istio functionality with modest resource requirements.
    It is suitable to run the [Bookinfo](/es/docs/examples/bookinfo/) application and associated tasks.
    This is the configuration that is installed with the [quick start](/es/docs/setup/getting-started/) instructions.

    {{< warning >}}
    This profile enables high levels of tracing and access logging so it is not suitable for performance tests.
    {{< /warning >}}

1. **minimal**: same as the default profile, but only the control plane components are installed.
    This allows you to configure the control plane and data plane components (e.g., gateways) using [separate profiles](/es/docs/setup/additional-setup/gateway/#deploying-a-gateway).

1. **remote**: used for configuring a {{< gloss >}}remote cluster{{< /gloss >}} that is managed by an
    {{< gloss >}}external control plane{{< /gloss >}} or by a control plane in a {{< gloss >}}primary cluster{{< /gloss >}}
    of a [multicluster mesh](/es/docs/ops/deployment/deployment-models/#multiple-clusters).

1. **ambient**: the ambient profile is designed to help you get started with [ambient mode](/es/docs/ambient).

1. **empty**: deploys nothing. This can be useful as a base profile for custom configuration.

1. **preview**: the preview profile contains features that are experimental. This is intended to explore new features
                coming to Istio. Stability, security, and performance are not guaranteed - use at your own risk.

Istio's [deployment profile value sets are defined here]({{< github_tree >}}/manifests/helm-profiles), for both `istioctl` and `helm`.

For `istioctl` only, specifying configuration profiles additionally automatically selects certain Istio components for installation, as marked with &#x2714; below:

|     | default | demo | minimal | remote | empty | preview | ambient |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Core components | | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | &#x2714; | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | &#x2714; | &#x2714; | | | | &#x2714; | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istiod` | &#x2714; | &#x2714; | &#x2714; | | | &#x2714; | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`CNI` | | | | | | | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`Ztunnel` | | | | | | | &#x2714; |

{{< tip >}}
To further customize Istio, a number of addon components can also be installed.
Refer to [integrations](/es/docs/ops/integrations) for more details.
{{< /tip >}}

## Platform Profiles

The following built-in platform profiles are currently available for both `istioctl` and `helm` install mechanisms. Note that as these are just sets of Helm values overrides, using them is not strictly required to install Istio in these environments, but they do provide a convenient baseline and are recommended for new installs:

1. **gke**: Sets chart options required or recommended for installing Istio in Google Kubernetes Engine (GKE) environments.

1. **eks**: Sets chart options required or recommended for installing Istio in Amazon's Elastic Kubernetes Service (EKS) environments.

1. **openshift**: Sets chart options required or recommended for installing Istio in OpenShift environments.

1. **k3d**: Sets chart options required or recommended for installing Istio in [k3d](https://k3d.io/) environments.

1. **k3s**: Sets chart options required or recommended for installing Istio in [K3s](https://k3s.io/) environments.

1. **microk8s**: Sets chart options required or recommended for installing Istio in [MicroK8s](https://microk8s.io/) environments.

1. **minikube**: Sets chart options required or recommended for installing Istio in [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) environments.

Istio's [platform profiles are defined here]({{< github_tree >}}/manifests/helm-profiles), for both `istioctl` and `helm`.

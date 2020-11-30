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
[installing Istio](/docs/setup/install/istioctl/).
The profiles provide customization of the Istio control plane and of the sidecars for the Istio data plane.

You can start with one of Istio’s built-in configuration profiles and then further
[customize the configuration](/docs/setup/install/istioctl/#customizing-the-configuration)
for your specific needs. The following built-in configuration profiles are currently available:

1. **default**: enables components according to the default settings of the
    [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/).
    This profile is recommended for production deployments and for
    {{< gloss "primary cluster" >}}primary clusters{{< /gloss >}} in a
    [multicluster mesh](/docs/ops/deployment/deployment-models/#multiple-clusters).
    You can display the default setting by running the command `istioctl profile dump`.

1. **demo**: configuration designed to showcase Istio functionality with modest resource requirements.
    It is suitable to run the [Bookinfo](/docs/examples/bookinfo/) application and associated tasks.
    This is the configuration that is installed with the [quick start](/docs/setup/getting-started/) instructions.

    {{< warning >}}
    This profile enables high levels of tracing and access logging so it is not suitable for performance tests.
    {{< /warning >}}

1. **minimal**: the minimal set of components necessary to use Istio's [traffic management](/docs/tasks/traffic-management/) features.

1. **remote**: used for configuring {{< gloss "remote cluster" >}}remote clusters{{< /gloss >}} of a
    [multicluster mesh](/docs/ops/deployment/deployment-models/#multiple-clusters).

1. **empty**: deploys nothing. This can be useful as a base profile for custom configuration.

1. **preview**: the preview profile contains features that are experimental. This is intended to explore new features
                coming to Istio. Stability, security, and performance are not guaranteed - use at your own risk.

1. **openshift**: the openshift profile is provided as a starting point of installing Istio on an OpenShift platform.

{{< tip >}}
Some additional vendor-specific configuration profiles are also available.
For more information, refer to the [setup instructions](/docs/setup/platform-setup) for your platform.
{{< /tip >}}

The components marked as **X** are installed within each profile:

|     | default | demo | minimal | remote | empty | preview | openshift |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Core components | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | X | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | X | X | | | | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istiod` | X | X | X | | | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`cni` | | | | | | | X |

To further customize Istio, a number of addon components can also be installed.
Refer to [integrations](/docs/ops/integrations) for more details.

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
[customize the configuration](/docs/setup/additional-setup/customize-installation/)
for your specific needs. The following built-in configuration profiles are currently available:

1. **default**: enables components according to the default settings of the
    [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/).
    This profile is recommended for production deployments and for
    {{< gloss "primary cluster" >}}primary clusters{{< /gloss >}} in a
    [multicluster mesh](/docs/ops/deployment/deployment-models/#multiple-clusters).
    You can display the default settings by running the `istioctl profile dump` command.

1. **demo**: configuration designed to showcase Istio functionality with modest resource requirements.
    It is suitable to run the [Bookinfo](/docs/examples/bookinfo/) application and associated tasks.
    This is the configuration that is installed with the [quick start](/docs/setup/getting-started/) instructions.

    {{< warning >}}
    This profile enables high levels of tracing and access logging so it is not suitable for performance tests.
    {{< /warning >}}

1. **minimal**: same as the default profile, but only the control plane components are installed.
    This allows you to configure the control plane and data plane components (e.g., gateways) using [separate profiles](/docs/setup/additional-setup/gateway/#deploying-a-gateway).

1. **remote**: used for configuring a {{< gloss >}}remote cluster{{< /gloss >}} that is managed by an
    {{< gloss >}}external control plane{{< /gloss >}} or by a control plane in a {{< gloss >}}primary cluster{{< /gloss >}}
    of a [multicluster mesh](/docs/ops/deployment/deployment-models/#multiple-clusters).

1. **empty**: deploys nothing. This can be useful as a base profile for custom configuration.

1. **preview**: the preview profile contains features that are experimental. This is intended to explore new features
                coming to Istio. Stability, security, and performance are not guaranteed - use at your own risk.

1. **ambient**: the ambient profile is designed to help you get started with [ambient mesh](/docs/ops/ambient).

    {{< boilerplate ambient-alpha-warning >}}

{{< tip >}}
Some additional vendor-specific configuration profiles are also available.
For more information, refer to the [setup instructions](/docs/setup/platform-setup) for your platform.
{{< /tip >}}

The components marked as &#x2714; are installed within each profile:

|     | default | demo | minimal | remote | empty | preview | ambient |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Core components | | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | &#x2714; | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | &#x2714; | &#x2714; | | | | &#x2714; | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istiod` | &#x2714; | &#x2714; | &#x2714; | | | &#x2714; | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`CNI` | | | | | | | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`Ztunnel` | | | | | | | &#x2714; |

To further customize Istio, a number of addon components can also be installed.
Refer to [integrations](/docs/ops/integrations) for more details.

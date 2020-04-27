---
title: Installation Configuration Profiles
description: Describes the built-in Istio installation configuration profiles.
weight: 35
aliases:
    - /docs/setup/kubernetes/additional-setup/config-profiles/
keywords: [profiles,install,helm]
---

This page describes the built-in configuration profiles that can be used when
[installing Istio](/docs/setup/install/istioctl/).
The profiles provide customization of the Istio control plane and of the sidecars for the Istio data plane.
You can start with one of Istio’s built-in configuration profiles and then further customize the configuration for
your specific needs. The following built-in configuration profiles are currently available:

1. **default**: enables components according to the default settings of the
    [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/)
    (recommend for production deployments).
    You can display the default setting by running the command `istioctl profile dump`.

1. **demo**: configuration designed to showcase Istio functionality with modest resource requirements.
    It is suitable to run the [Bookinfo](/docs/examples/bookinfo/) application and associated tasks.
    This is the configuration that is installed with the [quick start](/docs/setup/getting-started/) instructions,
    but you can later [customize the configuration](/docs/setup/install/istioctl/#customizing-the-configuration)
    to enable additional features if you wish to explore more advanced tasks.

    {{< warning >}}
    This profile enables high levels of tracing and access logging so it is not suitable for performance tests.
    {{< /warning >}}

1. **minimal**: the minimal set of components necessary to use Istio's [traffic management](/docs/tasks/traffic-management/) features.

1. **remote**: used for configuring remote clusters of a
    [multicluster mesh](/docs/ops/deployment/deployment-models/#multiple-clusters) with a
    [shared control plane](/docs/setup/install/multicluster/shared/) configuration.

1. **empty**: deploys nothing. This can be useful as a base profile for custom configuration.

1. **separate**: deploys Istio following the legacy micro-services model. This profile is not recommended because it won't be supported in future releases.

The components marked as **X** are installed within each profile:

|     | default | demo | minimal | remote |
| --- | --- | --- | --- | --- |
| Core components | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | X | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-pilot` | X | X | X | |
| Addons | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`grafana` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-tracing` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`kiali` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`prometheus` | X | X | | X |

To further customize Istio and install addons, you can add one or more `--set <key>=<value>` options in the
`istioctl manifest` command that you use when installing Istio.
Refer to [customizing the configuration](/docs/setup/install/istioctl/#customizing-the-configuration) for details.

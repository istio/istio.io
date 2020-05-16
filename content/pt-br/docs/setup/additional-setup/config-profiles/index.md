---
title: Installation Configuration Profiles
description: Describes the built-in Istio installation configuration profiles.
weight: 35
aliases:
    - /docs/setup/kubernetes/additional-setup/config-profiles/
keywords: [profiles,install,helm]
---

This page describes the built-in configuration profiles that can be used when
[installing Istio](/pt-br/docs/setup/install/istioctl/).
The profiles provide customization of the Istio control plane and of the sidecars for the Istio data plane.
You can start with one of Istio’s built-in configuration profiles and then further customize the configuration for
your specific needs. The following built-in configuration profiles are currently available:

1. **default**: enables components according to the default settings of the
    [`IstioControlPlane` API](/pt-br/docs/reference/config/istio.operator.v1alpha12.pb/)
    (recommend for production deployments).
    You can display the default setting by running the command `istioctl profile dump`.

1. **demo**: configuration designed to showcase Istio functionality with modest resource requirements.
    It is suitable to run the [Bookinfo](/pt-br/docs/examples/bookinfo/) application and associated tasks.
    This is the configuration that is installed with the [quick start](/pt-br/docs/setup/getting-started/) instructions,
    but you can later [customize the configuration](/pt-br/docs/setup/install/istioctl/#customizing-the-configuration)
    to enable additional features if you wish to explore more advanced tasks.

    {{< warning >}}
    This profile enables high levels of tracing and access logging so it is not suitable for performance tests.
    {{< /warning >}}

1. **minimal**: the minimal set of components necessary to use Istio's [traffic management](/pt-br/docs/tasks/traffic-management/) features.

1. **sds**: similar to the **default** profile, but also enables Istio's [SDS (secret discovery service)](/pt-br/docs/tasks/security/citadel-config/auth-sds).
    This profile comes with additional authentication features enabled by default (Strict Mutual TLS).

1. **remote**: used for configuring remote clusters of a
    [multicluster mesh](/pt-br/docs/ops/deployment/deployment-models/#multiple-clusters) with a
    [shared control plane](/pt-br/docs/setup/install/multicluster/shared-vpn/) configuration.

The components marked as **X** are installed within each profile:

|     | default | demo | minimal | sds | remote
| --- | --- | --- | --- | --- | --- |
| Core components | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-citadel` | X | X | | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-galley` | X | X | | X | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | X | X | | X | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-nodeagent` | | | | X | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-pilot` | X | X | X | X | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-policy` | X | X | | X | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-sidecar-injector` | X | X | | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-telemetry` | X | X | | X | |
| Addons | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`grafana` | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-tracing` | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`kiali` | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`prometheus` | X | X | | X | |

To further customize Istio and install addons, you can add one or more `--set <key>=<value>` options in the
`istioctl manifest` command that you use when installing Istio.
Refer to [customizing the configuration](/pt-br/docs/setup/install/istioctl/#customizing-the-configuration) for details.

---
title: Installation Configuration Profiles
description: Describes the built-in Istio installation configuration profiles.
weight: 35
aliases:
    - /docs/setup/kubernetes/additional-setup/config-profiles/
keywords: [profiles,install,helm]
---

This page describes the built-in configuration profiles that can be used when
[installing Istio using helm](/docs/setup/install/helm/).
The profiles provide customization of the Istio control plane and of the sidecars for the Istio data plane.
You can start with one of Istio’s built-in configuration profiles and then further customize the configuration for
your specific needs. The following built-in configuration profiles are currently available:

1. **default**: enables components according to the default [Installation Options](/docs/reference/config/installation-options/)
    (recommend for production deployments).

1. **demo**: configuration designed to showcase Istio functionality with modest resource requirements.
    It is suitable to run the [Bookinfo](/docs/examples/bookinfo/) application and associated tasks.
    This is the same configuration that is installed with the [Quick Start](/docs/setup/install/kubernetes/) instructions, only using helm has the advantage
    that you can more easily enable additional features if you later wish to explore more advanced tasks.
    This profile comes in two variants, either with or without authentication enabled.

    {{< warning >}}
    This profile enables high levels of tracing and access logging so it is not suitable for performance tests.
    {{< /warning >}}

1. **minimal**: the minimal set of components necessary to use Istio's [traffic management](/docs/tasks/traffic-management/) features.

1. **sds-auth**: similar to the **default** profile, but also enables Istio's [SDS (secret discovery service)](/docs/tasks/security/auth-sds).
    This profile comes with additional authentication features enabled by default.

The components marked as **X** are installed within each profile:

|     | default | demo | minimal | sds |
| --- | --- | --- | --- | --- |
| Profile filename | `values.yaml` | `values-istio-demo.yaml` | `values-istio-minimal.yaml` | `values-istio-sds-auth.yaml` |
| Core components | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-citadel` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-galley` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-nodeagent` | | | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-pilot` | X | X | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-policy` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-sidecar-injector` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-telemetry` | X | X | | X |
| Addons | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`grafana` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-tracing` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`kiali` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`prometheus` | X | X | | X |

Some profiles have an authentication variant, with `-auth` appended to the name, which adds the following
security features to the profile:

{{< tip >}}
Control plane security with SDS is planned for an upcoming release.
{{< /tip >}}

| Security feature | demo-auth | sds-auth |
| --- | --- | --- |
| Control Plane Security | X | |
| Strict Mutual TLS | X | X |
| SDS | | X |

To further customize Istio and install addons, you can add one or more `--set <key>=<value>` options in the `helm template` or `helm install` command that you use when installing Istio. The [Installation Options](/docs/reference/config/installation-options/) lists the complete set of supported installation key and value pairs.

## Multicluster profiles

Istio provides two additional built-in configuration profiles that are used exclusively for configuring a
[multicluster deployment](/docs/concepts/deployment-models/#multiple-clusters):

1. **remote**: used for configuring remote clusters of a
    multicluster mesh with a shared [control plane](/docs/concepts/deployment-models/#control-plane-models).

1. **multicluster-gateways**: used for configuring clusters of a
    multicluster mesh with replicated [control planes](/docs/concepts/deployment-models/#control-plane-models).

The **remote** profile is configured using the values file `values-istio-remote.yaml`. This profile installs only two
Istio core components:

1. `istio-citadel`

1. `istio-sidecar-injector`

The **multicluster-gateways** profile is configured using the values file `values-istio-multicluster-gateways.yaml`.
This profile installs the same components as the Istio **default** configuration profile plus two additional components:

1. The `istio-egressgateway` core component.

1. The `coredns` addon.

Refer to the [multicluster installation instructions](/docs/setup/install/multicluster/) for more details.

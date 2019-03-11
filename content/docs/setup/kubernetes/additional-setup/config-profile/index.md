---
title: Installation Configuration Profiles
description: Describes the built-in Istio installation configuration profiles.
weight: 35
keywords: [profiles,install,helm]
---

This page describes the built-in configuration profiles that can be used when
[installing Istio using helm](/docs/setup/kubernetes/install/helm/).
The profiles provide customization of the Istio control plane and of the sidecars for the Istio data plane.
You can start with one of Istio’s built-in configuration profiles and then further customize the configuration for
your specific needs. The following built-in configuration profiles are currently available:

1. **default**: enables components according to the default [Installation Options](/docs/reference/config/installation-options/)
    (recommend for production deployments).

1. **demo**: configuration suitable to run the [Bookinfo](/docs/examples/bookinfo/) application and associated tasks.
    This is the same configuration that is installed with the [Quick Start](/docs/setup/kubernetes/install/kubernetes/) instructions, only using helm has the advantage
    that you can more easily enable additional features if you wish to explore more advanced tasks. This profile comes in two flavors, either with or without authentication enabled.

1. **minimal**: the minimal set of components necessary to use Istio's [traffic management](/docs/tasks/traffic-management/) features.

1. **remote**: creates a service account with minimal access for use by Istio Pilot discovery used in [configuring a multicluster mesh](/docs/examples/multicluster/split-horizon-eds/).

1. **sds**:  used to enable [SDS (secret discovery service) for Istio](/docs/tasks/security/auth-sds). This profile comes only with authentication enabled.

The components marked as **X** are installed within each profile:

| | default | demo | minimal | remote | sds |
| --- | :---: | :---: | :---: | :---: | :---: |
|Profile filename | `values.yaml` | `values-istio-demo.yaml` | `values-istio-minimal.yaml` | `values-istio-remote.yaml` | `values-istio-sds-auth.yaml` |
| Core components | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-citadel` | X | X | | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-galley` | X | X | | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | X | X | | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-nodeagent` | | | | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-pilot` | X | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-policy` | X | X | | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-sidecar-injector` | X | X | | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-telemetry` | X | X | | | X |
| Addons | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`grafana` | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-tracing` | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`kiali` | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`prometheus` | X | X | | | X |
| | | | | | |
| The authentication version, adding `-auth`, adds | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Control Plane Security | | X | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Strict mTLS | | X | | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SDS | | | | | X |

To further customize Istio and install addons, you can add one or more `--set <key>=<value>` options in the `helm template` or `helm install` command that you use when installing Istio. The [Installation Options](/docs/reference/config/installation-options/) lists the complete set of supported installation key and value pairs.

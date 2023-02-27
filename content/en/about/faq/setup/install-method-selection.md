---
title: Which Istio installation method should I use?
weight: 10
---

In addition to the simple [getting started](/docs/setup/getting-started) evaluation install, there are several different
methods you can use to install Istio. Which one you should use depends on your production requirements.
The following lists some of the pros and cons of each of the available methods:

1. [istioctl install](/docs/setup/install/istioctl/)

    The simplest and most qualified installation and management path with high security.
    This is the community recommended method for most use cases.

    Pros:

    - Thorough configuration validation and health verification.
    - Uses the `IstioOperator` API which provides extensive configuration/customization options.
    - No in-cluster privileged pods needed. Changes are actuated by running the `istioctl` command.

    Cons:

    - Multiple binaries must be managed, one per Istio minor version.
    - The `istioctl` command can set values like `JWT_POLICY` based on your running environment,
      thereby producing varying installations in different Kubernetes environments.

1. [istioctl manifest generate](/docs/setup/install/istioctl/#generate-a-manifest-before-installation)

    Generate the Kubernetes manifest and then apply with `kubectl apply --prune`.
    This method is suitable where strict auditing or augmentation of output manifests is needed.

    Pros:

    - Resources are generated from the same `IstioOperator` API as used in `istioctl install` and Operator.
    - Uses the `IstioOperator` API which provides extensive configuration/customization options.

    Cons:

    - Some checks performed in `istioctl install` and Operator are not done.
    - UX is less streamlined compared to `istioctl install`.
    - Error reporting is not as robust as `istioctl install` for the apply step.

1. [Install using Helm](/docs/setup/install/helm/)

    Using Helm charts allows easy integration with Helm based workflows and automated resource pruning during upgrades.

    Pros:

    - Familiar approach using industry standard tooling.
    - Helm native release and upgrade management.

    Cons:

    - Fewer checks and validations compared to `istioctl install` and Operator.
    - Some administrative tasks require more steps and have higher complexity.

1. [Istio Operator](/docs/setup/install/operator/)

    {{< warning >}}
    Using the operator is not recommended for new installations. While the operator will continue to be supported,
    new feature requests will not be prioritized.
    {{< /warning >}}

    The Istio operator provides an installation path without needing the `istioctl` binary.
    This can be used for simplified upgrade workflows where running an in-cluster privileged controller is not a concern.
    This method is suitable where strict auditing or augmentation of output manifests is not needed.

    Pros:

    - Same API as `istioctl install` but actuation is through a controller pod in the cluster with a fully declarative operation.
    - Uses the `IstioOperator` API which provides extensive configuration/customization options.
    - No need to manage multiple `istioctl` binaries.

    Cons:

    - High privilege controller running in the cluster poses security risks.

Installation instructions for all of these methods are available on the [Istio install page](/docs/setup/install).

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

    Cons:

    - Multiple binaries must be managed, one per Istio minor version.
    - The `istioctl` command can set values automatically based on your running environment,
      thereby producing varying installations in different Kubernetes environments.

1. [istioctl manifest generate](/docs/setup/install/istioctl/#generate-a-manifest-before-installation)

    Generate the Kubernetes manifest and then apply with `kubectl apply --prune`.
    This method is suitable where strict auditing or augmentation of output manifests is needed.

    Pros:

    - Resources are generated from the same `IstioOperator` API as used in `istioctl install`.
    - Uses the `IstioOperator` API which provides extensive configuration/customization options.

    Cons:

    - Some checks performed in `istioctl install` are not done.
    - UX is less streamlined compared to `istioctl install`.
    - Error reporting is not as robust as `istioctl install` for the apply step.

1. [Install using Helm](/docs/setup/install/helm/)

    Using Helm charts allows easy integration with Helm based workflows and automated resource pruning during upgrades.

    Pros:

    - Familiar approach using industry standard tooling.
    - Helm native release and upgrade management.

    Cons:

    - Fewer checks and validations compared to `istioctl install`.
    - Some administrative tasks require more steps and have higher complexity.

Installation instructions for all of these methods are available on the [Istio install page](/docs/setup/install).

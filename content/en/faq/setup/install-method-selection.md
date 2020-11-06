---
title: Which Istio installation method should I use?
weight: 10
---

In addition to the simple [getting started](/docs/setup/getting-started) evaluation install, there are several different
methods you can use to install Istio. Which one you should use depends on your production requirements.
The following lists some of the pros and cons of each of the available methods:

1. [istioctl install](/docs/setup/install/istioctl/)

    The simplest and most validated installation/management path with high security.
    This is generally considered the recommended method, in most cases.
    
    Pros:

    - Thorough configuration validation and health verification. 
    - Uses `IstioOperator` API which has extensive configuration/customization options.
    - No in-cluster pods needed. Changes are actuated by running the `istioctl` command.

    Cons:

    - Multiple binaries must be managed, one per Istio minor version.
    - Some configurations may not be fully declarative and safe to use in CI pipelines (e.g., enabling third-party JWT).

1. [Istio Operator](/docs/setup/install/operator/)

    Simple installation path without `istioctl` binaries. This is also a highly recommended approach unless
    security issues cannot be addressed in the deployment environment.

    Pros:

    - Same API as `istioctl install` but actuation is through a controller pod in the cluster with a fully declarative operation.
    - Uses the `IstioOperator` API which has extensive configuration/customization options.
    - No need to manage multiple `istioctl` binaries.

    Cons:

    - High privilege pod running in the cluster has security implications.

1. [istioctl manifest generate](/docs/setup/install/istioctl/#generate-a-manifest-before-installation)

    Generate the Kubernetes manifest and then appy with `kubectl apply --prune`.
    This methiod is suitable where strict auditing or control of output manifests is needed.

    Pros:
    
    - Charts are generated from same `IstioOperator` API as used in `istioctl install` and Operator.
    - Uses `IstioOperator` API which has extensive configuration/customization options.

    Cons:
    
    - Some checks performed in `istioctl install` and Operator are not done.
    - UX less streamlined compared to `istioctl install`. 
    - Error reporting not as robust as `istioctl install` for apply step.

1. [install using Helm](/docs/setup/install/helm/)

    Using Helm charts allows easy integration with Helm based installation and automation pipelines.

    Pros:

    - Familiar approach using industry standard charts.
    - Fully declarative and can be safely used in CI pipelines.

    Cons:

    - Fewer checks and validations compared to `istioctl install` and Operator.
    - Some administrative tasks require more steps and have higher complexity.
    - Complex configuration may require [kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/) or editing templates.

Installation instructions for all of these methods are available on the [Istio install page](/docs/setup/install).

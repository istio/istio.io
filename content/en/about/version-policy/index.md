---
title: Versioning Policy
description: Supported versions of various components and dependencies of Istio.
weight: 15
icon: cadence
---

## Istio Versioning

Istio versions are expressed as **x**.**y**.**z**, where **x** is the major version, **y** is the minor version, and **z** is the patch version.

Istio provides support for each minor release for 3 months after the next minor release. For example, Istio 1.0 support will be dropped 3 months after Istio 1.2 is released. See [Build & Release Cadence](/about/release-cadence/) for more details.

## Component Version Skew

Various components of Istio that interact with each other must be kept within supported version ranges. Below describes the required version skews. Where possible, we always recommend using the same version between all components.

### Istioctl

We currently recommend using `istioctl` within the same minor version as both the control plane and data plane.

For example, `istioctl` version **1.0.1** could be used with control plane version **1.0.0** and data plane version **1.0.6**.

### Control/Data Plane

The data plane (both sidecars and gateways) must be either the same version as the control plane, or at most 1 minor version older.

For example, the data plane version **1.0.0** could be used with control plane version **1.0.0** or **1.1.0**.

This implies that the control plane must be upgraded first. For more information, see the [Upgrade](/docs/setup/upgrade/) documentation.

## Kubernetes versions

The following table indicates the versions of Kubernetes that are supported for various Istio versions. While Istio may work on versions outside of those listed below, we do not test the stability or safety of these versions. Sticking within the supported version range is highly recommended.

|Istio Version       | Kubernetes Version
|--------------------|-----------------------
|1.6                 | 1.15, 1.16, 1.17, 1.18
|1.5                 | 1.14, 1.15, 1.16
|1.4                 | 1.13, 1.14, 1.15
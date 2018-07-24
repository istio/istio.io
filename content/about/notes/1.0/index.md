---
title: Istio 1.0
weight: 92
---

This is a major release of 1.0. This version is a hardened version of 0.8 with a few new features in addition
to usual pile of bug fixes and performance improvements.

## Networking

## Security

## Telemetry

## Setup

## Mixer adapters

## Known issues with 1.0

- Amazon's EKS service does not implement automatic sidecar injection.  Istio can be used in Amazon's
  EKS by using [manual injection](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection) for
  sidecars and turning off galley using the [Helm parameter](/docs/setup/kubernetes/helm-install)
  `--set galley.enabled=false`.

- In a [multicluster deployment](/docs/setup/kubernetes/multicluster-install) the mixer-telemetry
  and mixer-policy components do not connect to the Kubernetes API endpoints of any of the remote
  clusters.  This results in a loss of telemetry fidelity as some of the metadata associated
  with workloads on remote clusters is incomplete.

- There are Kubernetes manifests available for using Citadel standalone or with Citadel health checking enabled.
  There is not a Helm implementation of these modes.  See [Issue 6922](https://github.com/istio/istio/issues/6922)
  for more details.

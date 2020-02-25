---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.5.
weight: 20
---

This page describes changes you need to be aware of when upgrading from
Istio 1.4.x to 1.5.x.  Here, we detail cases where we intentionally broke backwards
compatibility.  We also mention cases where backwards compatibility was
preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.4.

# Control Plane Restructuring

In Istio 1.5, we have moved towards a new deployment model for the control plane, with many components consolidated. The following describes where various functionality has been moved to.

## Istiod

In Istio 1.5, there will be a new deployment, `istiod`. This component is the core of the control plane, and will handle config and certificate distribution, sidecar injection, and more.

## Sidecar Injection

Previously, sidecar injection was handled by a mutating webhook that was processed by a deployment named `istio-sidecar-injector`. In Istio 1.5, the same mutating webhook remains, but it will now point to the `istiod` deployment. All injection logic remains the same.

## Galley

* Config Validation - this functionality remains the same, but is now handled by the `istiod` deployment.
* MCP Server - the MCP server has been disabled by default. For most users, this is an implementation detail. If you do explicitly depend on this functionality, you will need to run the `istio-galley` deployment.
* Experimental features (such as config analysis) - These features will require the `istio-galley` deployment.

## Citadel

Previously, Citadel served two functionalities: writing certificates to secrets in each namespace, and serving secrets to the `nodeagent` over `gRPC` when SDS is used. In Istio 1.5, secrets are no longer written to each namespace. Instead, they are only served over gRPC. This functionality has been moved to the `istiod` deployment.

## SDS Node Agent

The `nodeagent` deployment has been removed. This functionality now exists in the Sidecar

## Sidecar

Previously, the sidecar was able to access certificates in two ways: through secrets mounted as files, or over SDS (through the `nodeagent` deployment). In Istio 1.5, this has been simplified. All secrets will be served over a locally run SDS server. For most users, these secrets will be fetched from the `istiod` deployment. For users with a custom CA, file mounted secrets can still be used, however, these will still be served by the local SDS server. This means that certificate rotations will no longer require Envoy to restart.

## CNI

There have been no changes to the deployment of `istio-cni`.

## Pilot

The `istio-pilot` deployment has been removed in favor of the `istiod` deployment, which contains all functionality that Pilot once had. For backwards compatbility, there are still some references to Pilot.

# Control Plane Security

As part of the Istiod effort, we have changed how proxies securely communicate with the control plane. In previous versions, proxies would connect to the control plane securely when the setting `values.global.controlPlaneSecurityEnabled=true` was configured, which was the default for Istio 1.4. Each control plane component ran a sidecar with Citadel certificates, and proxies connected to Pilot over port 15011.

In Istio 1.5, this is no longer the recommended or default way to connect the proxies with the control plane; instead, DNS certificates, which can be signed by Kubernetes or istiod, will be used without a sidecar. Proxies connect to pilot over port 15012.

Note: despite the naming, in Istio 1.5 when `controlPlaneSecurityEnabled` is set to `false`, communication between the control plane will be secure by default.

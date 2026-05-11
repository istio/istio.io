---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.30.0.
weight: 20
---

When you upgrade from Istio 1.29.0 to Istio 1.30.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.29.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.29.x.

## CNI config file permissions changed to 0600

The default file permissions for CNI config files written by Istio have changed from 0644 to 0600.
This aligns with the CIS Kubernetes benchmark `v1.12` requirement. Since the CNI config is only read
by the container runtime running as root, this should have no functional impact. If you have tooling
that needs to read CNI config files as a non-root group member, you can set permissions to 0640 by
setting `values.cni.env.CNI_CONF_GROUP_READ=true` environment variable on the
`istio-cni-node` `DaemonSet`.

## CNI Agent respects excludeNamespaces configuration

Previously, only the CNI Plugin respected the `excludeNamespaces` config by skipping the processing of excluded namespace's pods,
while the CNI Agent would still reconcile and add ambient-labeled Pods in an excluded namespace to the mesh.
Now, the CNI Agent respects excluded namespaces, which means existing, enrolled pods in an excluded namespace will be un-enrolled, and
new, ambient-labeled pods in an excluded namespace will not be enrolled.

## Untaint controller

If you enabled untaint controller using `taint.enabled` Helm value when deploying `istiod` chart, you previously also had to set the `PILOT_ENABLE_NODE_UNTAINT_CONTROLLERS` environment variable in the `istiod` deployment to `true`. This is no longer required, as the variable is now set automatically when the untaint controller is enabled.

## Sidecar proxy service namespace selection changed

When configuring sidecar proxies if a hostname exists in multiple namespaces, Istio now prefers Kubernetes
services and falls back to the oldest non-Kubernetes service by creation time. Previously, the first visible
namespace alphabetically was chosen.

This may cause traffic to route to a different service instance if you have the same hostname across multiple
namespaces with mixed service types (e.g. a Kubernetes service and a `ServiceEntry`).

If this is not desired, set the `PILOT_SIDECAR_PICK_BEST_SERVICE_NAMESPACE` environment variable to `false`
in Istiod, or use `compatibilityVersion` 1.28 or earlier to restore the previous behavior.

## XDS debug endpoints now require authentication

XDS debug endpoints (`syncz`, `config_dump`) on port 15010 now require authentication.
This affects `istioctl` commands using `--plaintext` flag and custom tooling using plaintext XDS.
To restore previous behavior, set `ENABLE_DEBUG_ENDPOINT_AUTH=false`.

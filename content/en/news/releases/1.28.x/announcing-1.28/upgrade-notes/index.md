---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.28.0.
weight: 20
---

{{< warning >}}
This is an automatically generated rough draft of the release notes and has not yet been reviewed.
{{< /warning >}}

When you upgrade from Istio 1.27.x to Istio 1.28.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.27.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.27.x.

## Enabling seccompProfile for Sidecar Containers
To enable the `RuntimeDefault` seccomp profile for `istio-validation` and `istio-proxy` containers, set the following in your Istio configuration:
```yaml
global:
  proxy:
    seccompProfile:
      type: RuntimeDefault
```
This change allows for better security practices by using the default seccomp profile provided by the container runtime.

## InferencePool
The InferencePool API v1.0.0-rc.2 has been replaced with v1.0.0. No API changes exist
between rc2 and v1.0.0.

## InferencePool
The InferencePool API v1.0.0-rc.1 has been replaced with v1.0.0-rc.2. In this version, `inferencePool.spec.endpointPickerRef.portNumber`
field has been replaced with `inferencePool.spec.endpointPickerRef.port.number`. The `inferencePool.spec.endpointPickerRef.port` field
is a non-pointer and required when `inferencePool.spec.endpointPickerRef.kind` is unset or "Service". The port number 9002 is no longer
inferred. Update your configurations to use the new API version.

## InferencePool
The v1alpha2 InferencePool API type has been removed. Please use the v1 InferencePool API type instead.
Update your configurations to use the new API version.

## Ambient data plane behavior changes for ServiceEntries with resolution set to `NONE`
During an upgrade from a previous version to one supporting "PASSTHROUGH" services, old ztunnel images will report a NACK in XDS because they do not support this new service type. This is expected and should not be overly problematic, however it may represent a data plane behavior change when you see the NACK. During the upgrade, a NACK could result in:

  1. The data plane configuration was not updated because it could not handle the new service type. This is effectively a noop update.
  2. The service is new and configuration was not accepted by the data plane. This will result in behavior where the data plane behaves as if the ServiceEntry doesn't exist. This results in passthrough behavior where ztunnel does not recognize the service and can not determine if a waypoint is required.

In both cases, the NACK behavior will resolve once ztunnel is updated to a version that supports the new service type.
## `BackendTLSPolicy` alpha removal
The support for the `v1alpha3 version of `BackendTLSPolicy` has been removed. Only `v1` `BackendTLSPolicy` is supported.

Please note that, prior to this release, `BackendTLSPolicy` was ignored by Istio unless the `PILOT_ENABLE_ALPHA_GATEWAY_API=true` option
was explicitly enabled. As the policy is now `v1`, this setting is no longer required.

## Migrate to the new metric eviction mechanism
The Pilot environment flags `METRIC_ROTATION_INTERVAL` and `METRIC_GRACEFUL_DELETION_INTERVAL` have been removed.
Use the pod annotation `sidecar.istio.io/statsEvictionInterval` with the new stats eviction API instead.

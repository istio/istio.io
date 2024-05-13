---
title: Istio 1.22 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.22.x.
weight: 20
publishdate: 2024-05-13
---

When you upgrade from Istio 1.21.x to Istio 1.22.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.21.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.21.x.

## Delta xDS on by default

In previous versions, Istio used the "State of the world" xDS protocol to configure Envoy.
In this release, the ["Delta"](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds) xDS protocol is enabled by default.

This should be an internal implementation detail, but because this controls the core configuration protocol in Istio,
an upgrade notice is present in an abundance of caution.

The expected impacts of this change is improved performance of configuration distribution.
This may result in reduced CPU and memory utilization in Istiod and proxies, as well as less network traffic between the two.
Note that while this release changes the *protocol* to be incremental, Istio does not yet send perfect minimal incremental updates.
However, there are already optimizations in place for a variety of critical code paths, and this change enables us to continue optimizations.

If you experience unexpected impacts of this change, please set the `ISTIO_DELTA_XDS=false` environment variable in proxies
and file a GitHub issue.

## Default tracing to `zipkin.istio-system.svc` removed

In previous versions of Istio, tracing was automatically configured to send traces to `zipkin.istio-system.svc`.
This default setting has been removed; users will need to explicitly configure where to send traces moving forward.

`istioctl x precheck --from-version=1.21` can automatically detect if you may be impacted by this change.

If you previously had tracing enabled implicitly, you can enable it by doing one of:
* Installing with `--set compatibilityVersion=1.21`.
* Following [Configure tracing with Telemetry API](/docs/tasks/observability/distributed-tracing/telemetry-api/).

## Default value of the feature flag `ENHANCED_RESOURCE_SCOPING` to true

`ENHANCED_RESOURCE_SCOPING` is enabled by default. This means that the pilot will processes only the Istio Custom Resource configurations that are in
scope of what is specified from `meshConfig.discoverySelectors`. Root-ca certificate distribution is also affected.

If this is not desired, use the new `compatibilityVersion` feature to fallback to old behavior.

## `ServiceEntry` with `resolution: NONE` now respects `targetPort`

`ServiceEntry` with `resolution: NONE` previously ignored any `targetPort` specifier.
In this release, the `targetPort` is now respected.
If undesired set `--compatibilityVersion=1.21` to revert to the old behavior, or remove the `targetPort` specification.

## New ambient mode waypoint attachment method

Waypoints in Istio's ambient mode no longer use the original service account or namespace attachment semantics. If you were using a namespace-scope waypoint previously migration should be fairly straight forward. Label your namespace with the appropriate waypoint and it should function in a similar way. Please check the [doc](/docs/ambient/usage/l7-features/#targeting-policies-or-routing-rules).
If you were using service account attachment there will be more to understand.

Under the old waypoint logic all types of traffic, both addressed to a service as well as addressed to a workload, were treated similarly because there wasn't a good way to properly associate a waypoint to a service. With the new attachment this limitation has been resolved. This includes adding a distinction between service addressed and workload addressed traffic. Annotating a service, or service-like kind, will redirect traffic which is service addressed to your waypoint. Likewise annotating a workload will redirect workload addressed traffic. It is therefore important to understand how consumers address your providers and select a waypoint attachment method which corresponds to this method of access.

---
title: Istio 1.20 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.20.
weight: 20
publishdate: 2023-11-14
---

When you upgrade from Istio 1.19.x to Istio 1.20.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio `1.19.x`.
The notes also mention changes that preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio `1.19.x`.

## Upcoming `ExternalName` support changes

The following information describes *upcoming* changes to `ExternalName`.

In this release, there are no behavioral changes by default.
However, you can explicitly opt in to the new behavior early if desired, and prepare your environments for the upcoming
change.

Kubernetes `ExternalName` `Service`s allow users to create new DNS entries. For example, you can create an `example`
service
that points to `example.com`. This is implemented by a DNS `CNAME` redirect.

In Istio, the implementation of `ExternalName`, historically, was substantially different. Each `ExternalName`
represented its own
service, and traffic matching the service was sent to the configured DNS name.

This caused a few issues:

* Ports are required in Istio, but not in Kubernetes. This can result in broken traffic if ports are not configured as
  Istio expects, despite them working without Istio.
* Ports not declared as `HTTP` would match *all* traffic on that port, making it easy to accidentally send all traffic
  on a port to the wrong place.
* Because the destination DNS name is treated as opaque, we cannot apply Istio policies to it as expected. For example,
  if an external name points to another in-cluster Service (for example, `example.default.svc.cluster.local`), mTLS
  would not be.

`ExternalName` support has been revamped to fix these problems. `ExternalName`s are now simply treated as aliases.
Wherever we would match `Host: <concrete service>` we will additionally match `Host: <external name service>`.
Note that the primary implementation of `ExternalName` DNS is handled outside of Istio in the Kubernetes DNS
implementation, and remains unchanged.

If you are using `ExternalName` with Istio, please be advised of the following behavioral changes:

* The `ports` field is no longer needed, matching Kubernetes behavior. If it is set, it will have no impact.
* `VirtualServices` that match on an `ExternalName` service will generally no longer match. Instead, the match should be
  rewritten to the referenced service.
* `DestinationRule` can no longer apply to `ExternalName` services. Instead, create rules where the `host` references
  the service.

These changes are off-by-default in this release, but will be on-by-default in the near future.
To opt in early, the `ENABLE_EXTERNAL_NAME_ALIAS=true` environment variable can be set.

## Envoy filter ordering

This change impacts internal implementation of how Envoy filters are ordered. These filters run in order to implement
various functionality.

The ordering is now consistent across inbound, outbound, and gateway proxy modes, as well as HTTP and TCP protocols:

* Metadata Exchange
* CUSTOM Authz
* WASM Authn
* Authn
* WASM Authz
* Authz
* WASM Stats
* Stats
* WASM unspecified

This changes the following areas:

* Inbound TCP filters now place Metadata Exchange before Authn.
* Gateway TCP filters now place stats after Authz, and CUSTOM Authz before Authn.

## `startupProbe` added to sidecar by default

The sidecar container now comes with a `startupProbe` enabled by default.
Startup probes run only at the start of the pod. Once the startup probe completes, readiness probes will continue.

By using a startup probe, we can poll for the sidecar to start more aggressively, without polling as aggressively
throughout the entire pod's lifecycle.
On average, this improves pod startup time by roughly one second.

If the startup probe does not pass after 10 minutes, the pod will be terminated.
Previously, the pod would never be terminated even if it was unable to start indefinitely.

If you do not want this feature, it can be disabled. However, you will want to tune the readiness probe accordingly.

The recommended values with the startup probe enabled (the new defaults):

{{< text yaml >}}
readinessInitialDelaySeconds: 0
readinessPeriodSeconds: 15
readinessFailureThreshold: 4
startupProbe:
enabled: true
failureThreshold: 600
{{< /text >}}

The recommended values to disable the startup probe (reverting the behavior to match older Istio versions):

{{< text yaml >}}
readinessInitialDelaySeconds: 1
readinessPeriodSeconds: 2
readinessFailureThreshold: 30
startupProbe:
enabled: false
{{< /text >}}

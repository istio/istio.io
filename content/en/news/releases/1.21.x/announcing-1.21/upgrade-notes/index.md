---
title: Istio 1.21 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.21.x.
weight: 20
publishdate: 2024-02-28
---

When you upgrade from Istio 1.20.x to Istio 1.21.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.20.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.20.x.

## Default value of the feature flag `ENABLE_AUTO_SNI` to true

[auto-sni](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/protocol.proto#envoy-v3-api-field-config-core-v3-upstreamhttpprotocoloptions-auto-sni)
is enabled by default. This means SNI will be set automatically based on the downstream HTTP host/authority header if `DestinationRule` does not explicitly set the same.

If this is not desired, use the new `compatibilityVersion` feature to fallback to old behavior.

## Default value of the feature flag `VERIFY_CERT_AT_CLIENT` is set to true

This means server certificates will be automatically verified using the OS CA certificates when not using a DestinationRule `caCertificates` field.
If this is not desired, use the new `compatibilityVersion` feature to fallback to old behavior, or use the `insecureSkipVerify`
field in DestinationRule to skip the verification.

## `ExternalName` support changes

Kubernetes `ExternalName` `Service`s allow users to create new DNS entries. For example, you can create an `example` service
that points to `example.com`. This is implemented by a DNS `CNAME` redirect.

In Istio, the implementation of `ExternalName`, historically, was substantially different. Each `ExternalName` represented its own
service, and traffic matching the service was sent to the configured DNS name.

This caused a few issues:
* Ports are required in Istio, but not in Kubernetes. This can result in broken traffic if ports are not configured as Istio expects, despite them working without Istio.
* Ports not declared as `HTTP` would match *all* traffic on that port, making it easy to accidentally send all traffic on a port to the wrong place.
* Because the destination DNS name is treated as opaque, we cannot apply Istio policies to it as expected. For example, if I point
  an external name at another in-cluster Service (for example, `example.default.svc.cluster.local`), mTLS would not be used.

`ExternalName` support has been revamped to fix these problems. `ExternalName`s are now simply treated as aliases.
Wherever we would match `Host: <concrete service>` we additionally will match `Host: <external name service>`.
Note that the primary implementation of `ExternalName` -- DNS -- is handled outside of Istio in the Kubernetes DNS implementation, and remains unchanged.

If you are using `ExternalName` with Istio, please be advised of the following behavioral changes:
* The `ports` field is no longer needed, matching Kubernetes behavior. If it is set, it will have no impact.
* `VirtualServices` that route to an `ExternalName` service will no longer work unless the referenced service exists (as a Service or ServiceEntry).
* `DestinationRule` can no longer apply to `ExternalName` services. Instead, create rules where the `host` references service.

To opt-out, the `ENABLE_EXTERNAL_NAME_ALIAS=false` environment variable can be set.

Note: the same change was introduced in the previous release, but off by default. This release turns the flag on by default.

## Gateway Name label modified

If you are using the [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1.Gateway)
to manage your Istio gateways, the label key used to identify the
gateway name is changing from `istio.io/gateway-name` to
`gateway.networking.k8s.io/gateway-name`.
The old label will continue to be appended to the relevant label sets
for backwards compatibility, but it will be removed in a future
release.
Furthermore, istiod's gateway controller will automatically detect
and continue to use the old label for label selectors belonging
to existing `Deployment` and `Service` resources.

Therefore, once you've completed your Istio upgrade, you can change the label selector in `Deployment` and `Service` resources whenever you are ready to use the new label.

Additionally, please upgrade any other policies, resources, or scripts that rely on the old label.

---
title: Istio 1.8 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.8.
weight: 20
release: 1.8
subtitle: Minor Release
linktitle: 1.8 Upgrade Notes
publishdate: 2020-11-19
---

When you upgrade from Istio 1.7.x to Istio 1.8.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.7.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.7.x.

## Multicluster `.global` Stub Domain Deprecation

As part of this release, Istio has switched to a new configuration for
multi-primary (formerly "replicated control planes"). The new
configuration is simpler, has fewer limitations, and has been thoroughly
tested in a variety of environments. As a result, the `.global` stub
domain is now deprecated and no longer guaranteed to work going forward.

## Mixer is no longer supported in Istio

If you are using the `istio-policy` or `istio-telemetry` services, or any
related Mixer configuration, you will not be able to upgrade without taking
action to either (a) convert your existing configuration and code to the new
extension model for Istio or (b) use the gRPC shim developed to bridge
transition to the new model. For more details, please refer to the [developer wiki](https://github.com/istio/istio/wiki/Enabling-Envoy-Authorization-Service-and-gRPC-Access-Log-Service-With-Mixer).

## The semantics of revision for gateways in `IstioOperator` has changed from 1.7 to 1.8

In 1.7, `revision` means you are creating a new gateway with a different revision so it would
not conflict with the default gateway. In 1.8, it means the revision of istiod the gateway
is configuring with. If you are using revision for gateways in `IstioOperator` in 1.7,
before moving to 1.8, you must upgrade it to the revision of the Istiod (or delete
the revision if you don’t use revision). See [Issue #28849](https://github.com/istio/istio/issues/28849).

## Istio CoreDNS Plugin Deprecation

The Istio sidecar now provides native support for DNS resolution with `ServiceEntries` using
`meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_CAPTURE="true"`. Previously, this support
was provided by the third party [Istio CoreDNS plugin](https://github.com/istio-ecosystem/istio-coredns-plugin).
As a result, the `istio-coredns-plugin` is now deprecated and will be removed in a future release.

## Use the new filter names for `EnvoyFilter`

If you are using `EnvoyFilter` API, it is recommended to change to the new filter names as described in Envoy's [deprecation notice](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.14.0#deprecated)
The deprecated filter names will be supported in this release for backward compatibility but will be removed in future releases.

## Inbound Cluster Name Format

The format of inbound Envoy cluster names has changed. Previously, they included the Service hostname
and port name, such as `inbound|80|http|httpbin.default.svc.cluster.local`. This lead to issues when multiple
Services select the same pod. As a result, we have removed the port name and hostname - the new format will
instead resemble `inbound|80||`.

For most users, this is an implementation detail, and will only impact debugging or tooling that directly
interacts with Envoy configuration.

## Avoid use of mesh expansion installation flags

To ease setup for multicluster and virtual machines while giving more control to users, the `meshExpansion` and `meshExpansionPorts` installation flags have been deprecated, and port 15012 has been added to the default list of ports for the `istio-ingressgateway` Service.

For users with `values.global.meshExpansion.enabled=true`, perform the following steps before upgrading Istio:

1. Apply the code sample for exposing Istiod through ingress.

{{< text bash >}}
$ kubectl apply -f @samples/multicluster/expose-istiod.yaml@
{{< /text >}}

   This removes `operator.istio.io/managed` labels from the associated Istio networking resources so that the Istio installer won't delete them. After this step, you can modify these resources freely.

1. If `components.ingressGateways[name=istio-ingressgateway].k8s.service.ports` is overridden, add port 15012 to the list of ports:

{{< text yaml >}}
    - port: 15012
        targetPort: 15012
        name: tcp-istiod
{{< /text >}}

1. If `values.gateways.istio-ingressgateway.meshExpansionPorts` is set, move all ports to `components.ingressGateways[name=istio-ingressgateway].k8s.service.ports` if they're not already present. Then, unset this value.

1. Unset `values.global.meshExpansion.enabled`.

## Protocol Detection Timeout Changes

In order to support permissive mTLS traffic as well as [automatic protocol detection](/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection),
the proxy will sniff the first few bytes of traffic to determine the protocol used. For certain "server first" protocols, such
as the protocol used by `MySQL`, there will be no initial bytes to sniff. To mitigate this issue in the past, Istio introduced
a detection timeout. However, we found this caused frequent telemetry and traffic failures during slow connections, while increasing latency
for misconfigured server first protocols rather than failing fast.

This timeout has been disabled by default. This has the following impacts:

- Non "server first" protocols will no longer have a risk of telemetry or traffic failures during slow connections
- Properly configured "server first" protocols will no longer have an extra 5 seconds latency on each connection
- Improperly configured "server first" protocols will experience connection timeouts. Please ensure you follow the steps listed in [Server First Protocols](/docs/ops/configuration/traffic-management/protocol-selection/#server-first-protocols)
  to ensure you do not run into traffic issues.

## Update AuthorizationPolicy resources to use `remoteIpBlocks`/`notRemoteIpBlocks` instead of `ipBlocks`/`notIpBlocks` if using the Proxy Protocol

{{< warning >}}
A critical [bug](https://groups.google.com/g/envoy-security-announce/c/aqtBt5VUor0) has been identified in Envoy that the proxy protocol downstream address is restored incorrectly for non-HTTP connections.

Please DO NOT USE the `remoteIpBlocks` field and `remote_ip` attribute with proxy protocol on non-HTTP connections until a newer version of Istio is released with a proper fix.

Note that Istio doesn't support the proxy protocol and it can be enabled only with the `EnvoyFilter` API and should be used at your own risk.
{{< /warning >}}

If using the Proxy Protocol on a load balancer in front an ingress gateway in conjunction with `ipBlocks`/`notIpBlocks` on an AuthorizationPolicy to perform IP-based access control, then please update the AuthorizationPolicy to use `remoteIpBlocks`/`notRemoteIpBlocks` instead after upgrading. The `ipBlocks`/`notIpBlocks` fields now strictly refer to the source IP address of the packet that arrives at the sidecar.

## `AUTO_PASSTHROUGH` Gateway mode

Previously, gateways were configured with multiple Envoy `cluster` configurations for each Service in the cluster, even those
not referenced by any `Gateway` or `VirtualService`. This was added to support the `AUTO_PASSTHROUGH` mode on Gateway, generally used for exposing Services across networks.

However, this came at an increased CPU and memory cost in the gateway and Istiod. As a result, we have disabled these by default
on the `istio-ingressgateway` and `istio-egressgateway`.

If you are relying on this feature for multi-network support, please ensure you apply one of the following changes:

1. Follow our new [Multicluster Installation](/docs/setup/install/multicluster/) documentation.

   This documentation will guide you through running a dedicate gateway deployment for this type of traffic (generally referred to as the `eastwest-gateway`).
   This `eastwest-gateway` will automatically be configured to support `AUTO_PASSTHROUGH`.

1. Modify your installation of the gateway deployment to include this configuration. This is controlled by the `ISTIO_META_ROUTER_MODE` environment variable. Setting this to `sni-dnat` enables these clusters, while `standard` (the new default) disables them.

{{< text yaml >}}
ingressGateways:
- name: istio-ingressgateway
    enabled: true
    k8s:
    env:
        - name: ISTIO_META_ROUTER_MODE
          value: "sni-dnat"
{{< /text >}}

## Connectivity issues among your proxies when updating from 1.7.x (where x < 5)

When upgrading your Istio data plane from 1.7.x (where x < 5) to 1.8, you may observe connectivity issues between your gateway and your sidecars or among your sidecars with 503 errors in the log. This happens when 1.7.5+ proxies send HTTP 1xx or 204 response codes with headers that 1.7.x proxies reject. To fix this, upgrade all your proxies (gateways and sidecars) to 1.7.5+ as soon as possible. ([Issue 29427](https://github.com/istio/istio/issues/29427), [More information](https://github.com/istio/istio/pull/28450))

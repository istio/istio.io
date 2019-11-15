---
title: Announcing Istio 1.1.8
subtitle: Patch Release
description: Istio 1.1.8 patch release.
publishdate: 2019-06-06
release: 1.1.8
aliases:
    - /about/notes/1.1.8
    - /blog/2019/announcing-1.1.8
    - /news/announcing-1.1.8
---

We're pleased to announce the availability of Istio 1.1.8. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix `PASSTHROUGH` `DestinationRules` for CDS clusters ([Issue 13744](https://github.com/istio/istio/issues/13744)).
- Make the `appVersion` and `version` fields in the Helm charts display the correct Istio version ([Issue 14290](https://github.com/istio/istio/issues/14290)).
- Fix Mixer crash affecting both policy and telemetry servers ([Issue 14235](https://github.com/istio/istio/issues/14235)).
- Fix multicluster issue where two pods in different clusters could not share the same IP address ([Issue 14066](https://github.com/istio/istio/issues/14066)).
- Fix issue where Citadel could generate a new root CA if it cannot contact the Kubernetes API server, causing mutual TLS verification to incorrectly fail ([Issue 14512](https://github.com/istio/istio/issues/14512)).
- Improve Pilot validation to reject different `VirtualServices` with the same domain since Envoy will not accept them ([Issue 13267](https://github.com/istio/istio/issues/13267)).
- Fix locality load balancing issue where only one replica in a locality would receive traffic ([13994](https://github.com/istio/istio/issues/13994)).
- Fix issue where Pilot Agent might not notice a TLS certificate rotation ([Issue 14539](https://github.com/istio/istio/issues/14539)).
- Fix a `LuaJIT` panic in Envoy ([Envoy Issue 6994](https://github.com/envoyproxy/envoy/pull/6994)).
- Fix a race condition where Envoy might reuse a HTTP/1.1 connection after the downstream peer had already closed the TCP connection, causing 503 errors and retries ([Issue 14037](https://github.com/istio/istio/issues/14037)).
- Fix a tracing issue in Mixer's Zipkin adapter causing missing spans ([Issue 13391](https://github.com/istio/istio/issues/13391)).

## Small enhancements

- Reduce Pilot log spam by logging the `the endpoints within network ... will be ignored for no network configured` message at `DEBUG`.
- Make it easier to rollback by making pilot-agent ignore unknown flags.
- Update Citadel's default root CA certificate TTL from 1 year to 10 years.

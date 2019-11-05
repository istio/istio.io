---
title: Announcing Istio 1.1.7
description: Istio 1.1.7 patch release.
publishdate: 2019-05-17
attribution: The Istio Team
release: 1.1.7
aliases:
    - /about/notes/1.1.7
    - /blog/2019/announcing-1.1.7
    - /news/announcing-1.1.7
---

We're pleased to announce the availability of Istio 1.1.7. Please see below for what's changed.

{{< relnote >}}

## Security update

This release fixes [CVE 2019-12243](/news/2019/cve-2019-12243).

## Bug fixes

- Fix issue where two gateways with overlapping hosts, created at the same second, can cause Pilot to fail to generate routes correctly and lead to Envoy listeners stuck indefinitely at startup in a warming state.
- Improve the robustness of the SDS node agent: if Envoy sends a SDS request with an empty `ResourceNames`, ignore it and wait for the next request instead of closing the connection ([Issue 13853](https://github.com/istio/istio/issues/13853)).
- In prior releases Pilot automatically injected the experimental `envoy.filters.network.mysql_proxy` filter into the outbound filter chain if the service port name is `mysql`.  This was surprising and caused issues for some operators, so Pilot will now automatically inject the `envoy.filters.network.mysql_proxy` filter only if the `PILOT_ENABLE_MYSQL_FILTER` environment variable is set to `1` ([Issue 13998](https://github.com/istio/istio/issues/13998)).
- Fix issue where Mixer policy checks were incorrectly disabled for TCP ([Issue 13868](https://github.com/istio/istio/issues/13868)).

## Small enhancements

- Add `--applicationPorts` option to the `ingressgateway` Helm charts.  When set to a comma-delimited list of ports, readiness checks will fail until all the ports become active.  When configured, traffic will not be sent to Envoys stuck in the warming state.
- Increase memory limit in the `ingressgateway` Helm chart to 1GB and add resource `request` and `limits` to the SDS node agent container to support HPA autoscaling.

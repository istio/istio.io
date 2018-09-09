---
title: Istio 0.3
weight: 98
aliases:
    - /docs/welcome/notes/0.3.html
icon: /img/notes.svg
---

## General

Starting with 0.3, Istio is switching to a monthly release cadence. We hope this will help accelerate our ability
to deliver timely improvements. See [here](/about/feature-stages/) for information on the state of individual features
for this release.

This is a fairly modest release in terms of new features as the team put emphasis on internal
infrastructure work to improve our velocity. Many bugs and smaller issues have been addressed and
overall performance has been improved in a number of areas.

## Security

- **Secure Control Plane Communication**. Mixer and Pilot are now secured with mutual TLS, just like all services in a mesh.

- **Selective Authentication**. You can now control authentication on a per-service basis via service annotations,
which helps with incremental migration to Istio.

## Networking

- **Egress rules for TCP**. You can now specify egress rules that affect TCP-level traffic.

## Policy enforcement and telemetry

- **Improved Caching**. Caching between Envoy and Mixer has gotten substantially better, resulting in a
significant drop in average latency for authorization checks.

- **Improved list Adapter**. The Mixer 'list' adapter now supports regular expression matching. See the adapter's
[configuration options](/docs/reference/config/policy-and-telemetry/adapters/list/) for details.

- **Configuration Validation**. Mixer does more extensive validation of configuration state in order to catch problems earlier.
We expect to invest more in this area in coming releases.

If you're into the nitty-gritty details, you can see our more detailed low-level
release notes [here](https://github.com/istio/istio/wiki/v0.3.0).

{{< relnote_links >}}

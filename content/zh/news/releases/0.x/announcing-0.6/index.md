---
title: Announcing Istio 0.6
linktitle: 0.6
subtitle: Major Update
description: Istio 0.6 announcement.
publishdate: 2018-03-08
release: 0.6.0
aliases:
    - /zh/about/notes/older/0.6
    - /zh/about/notes/0.6/index.html
    - /zh/news/2018/announcing-0.6
    - /zh/news/announcing-0.6
---

In addition to the usual pile of bug fixes and performance improvements, this release includes the new or
updated features detailed below.

{{< relnote >}}

## Networking

- **Custom Envoy Configuration**. Pilot now supports ferrying custom Envoy configuration to the
proxy. [Learn more](https://github.com/mandarjog/istioluawebhook)

## Mixer adapters

- **SolarWinds**. Mixer can now interface to AppOptics and Papertrail.
[Learn more](/zh/docs/reference/config/policy-and-telemetry/adapters/solarwinds/)

- **Redis Quota**. Mixer now supports a Redis-based adapter for rate limit tracking.
[Learn more](/zh/docs/reference/config/policy-and-telemetry/adapters/redisquota/)

- **Datadog**. Mixer now provides an adapter to deliver metric data to a Datadog agent.
[Learn more](/zh/docs/reference/config/policy-and-telemetry/adapters/datadog/)

## Other

- **Separate Check & Report Clusters**. When configuring Envoy, it's now possible to use different clusters
for Mixer instances that are used for Mixer's Check functionality from those used for Mixer's Report
functionality. This may be useful in large deployments for better scaling of Mixer instances.

- **Monitoring Dashboards**. There are now preliminary Mixer & Pilot monitoring dashboard in Grafana.

- **Liveness and Readiness Probes**. Istio components now provide canonical liveness and readiness
probe support to help ensure mesh infrastructure health. [Learn more](/zh/docs/tasks/security/citadel-config/health-check/)

- **Egress Policy and Telemetry**. Istio can monitor traffic to external services defined by `EgressRule` or External Service. Istio can also apply
Mixer policies on this traffic.

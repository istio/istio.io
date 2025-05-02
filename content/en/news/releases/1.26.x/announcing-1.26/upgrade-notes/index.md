---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.26.0.
weight: 20
---

{{< warning >}}
This is an automatically generated rough draft of the release notes and has not yet been reviewed.
{{< /warning >}}

When you upgrade from Istio 1.25.x to Istio 1.26.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.25.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.26.x.

## Upcoming deprecation of telemetry providers
The telemetry providers Lightstep and Opencensus are deprecated and will be removed in next release(v1.27). Please consider using the OpenTelemetry provider instead.
## Ztunnel Helm chart changes
In Istio 1.25, the resources in the ztunnel Helm chart were changed to be named `.Resource.Name`.
This often caused issues, as the name needs to be kept in sync with the Istiod Helm chart.

In this release, we have reverted to default to a static `ztunnel` name again.
As previously, this can be overriden with `--set resourceName=my-custom-name`.


---
title: Istio 1.26 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.26.0.
weight: 20
---

When upgrading from Istio 1.25.x to Istio 1.26.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.25.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.26.x.

## Upcoming removal of telemetry providers

The telemetry providers for Lightstep and OpenCensus are deprecated (since 1.22 and 1.25 respectively), as both have been replaced with the OpenTelemetry provider. They will be removed in Istio 1.27.  Please change to using the OpenTelemetry provider now if you use either.

## Ztunnel Helm chart changes

In Istio 1.25, the resources in the ztunnel Helm chart were changed to be named `.Resource.Name`.
This often caused issues, as the name needs to be kept in sync with the Istiod Helm chart.

In this release, we have reverted to default to a static `ztunnel` name again.
As before, this can be overridden with `--set resourceName=my-custom-name`.

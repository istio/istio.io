---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.7.
weight: 20
---

When you upgrade from Istio 1.6.x to Istio 1.7.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.6.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.6.x.

## Require Kubernetes 1.16+

Kubernetes 1.16+ is now required for installation.

## Installation

- `istioctl manifest apply` is removed, please use `istioctl install` instead.
- Installation of telemetry addons by istioctl is deprecated, please use these [addons integration instructions](/docs/ops/integrations/).

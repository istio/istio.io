---
title: ConflictingTelemetryWorkloadSelectors
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

The `ConflictingTelemetryWorkloadSelectors` message occurs when multiple Telemetry resources in the same namespace have overlapping workload selectors, causing ambiguity in determining which Telemetry resource should be applied to a specific pod. This can lead to unintended telemetry configuration for the affected workloads.

This message is generated when the following conditions are met:

1. There are multiple Telemetry resources within the same namespace.

1. These Telemetry resources have workload selectors that match the same set of pods.

To resolve this issue, review the conflicting Telemetry resources and update their workload selectors to ensure that each pod is matched by only one Telemetry resource. You may need to adjust the label selectors or reorganize the Telemetry resources to avoid overlapping selectors.

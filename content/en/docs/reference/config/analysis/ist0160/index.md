---
title: MultipleTelemetriesWithoutWorkloadSelectors
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

The `MultipleTelemetriesWithoutWorkloadSelectors` message occurs when there are multiple Telemetry resources in the same namespace that do not define any workload selector. Without workload selectors, these Telemetry resources apply to all workloads in the namespace by default. Having multiple such resources can lead to ambiguity in determining which Telemetry resource should be applied to a specific pod.

This message is generated when the following conditions are met:

1. There are multiple Telemetry resources within the same namespace.

1. These Telemetry resources do not define any workload selector.

To resolve this issue, review the conflicting Telemetry resources and define appropriate workload selectors for each of them. By specifying workload selectors, you can ensure that each Telemetry resource is applied to the intended set of pods, avoiding potential conflicts and ambiguity in Telemetry configurations.

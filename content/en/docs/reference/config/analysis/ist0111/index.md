---
title: MultipleSidecarsWithoutWorkloadSelectors
layout: analysis-message
---

This message occurs when more than one Sidecar resource in a namespace does not define any workload selector. This can lead to undefined behavior. See the reference for the [Sidecar](/docs/reference/config/networking/sidecar/) resource for more information.

To fix this, ensure that each namespace has only one Sidecar resource without a workload selector.

---
title: Workload ID
---
A unique identifier for an individual instance of a [workload](#workload).
Like [workload name](#workload-name), the workload ID is not a strongly verified property and should not be used
when enforcing ACLs. The workload IDs are accessible in Istio configuration as the
`source.uid` and `destination.uid` [attributes](#attribute).

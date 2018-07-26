---
title: Workload Name
---
A unique name for a [workload](#workload), identifying it within the [service mesh](#service-mesh).
Unlike the [service name](#service-name) and the [workload principal], the workload name is not a
strongly verified property and should not be used when enforcing ACLs.
The workload names is accessible in Istio configuration as the `source.name` and `destination.name`
[attributes](#attribute).

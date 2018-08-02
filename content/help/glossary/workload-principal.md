---
title: Workload Principal
---
Identifies the verifiable authority under which a [workload](#workload) runs.
Istio's service-to-service authentication is used to produce the workload principal.
By default workload principals are compliant with the SPIFFE ID format.

- Multiple [workloads](#workload) may share the same workload principal, but each workload has a single canonical workload
  principal

- Workload principals are accessible in Istio configuration as the `source.user` and `destination.user` [attributes](#attribute).

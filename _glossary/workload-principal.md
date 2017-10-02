---
title: Workload Principal
type: markdown
---
Identifies the verifiable authority under which a **Workload** runs.
Istio service-to-service authentication is used to produce the **Workload Principal**.
By default **Workload Principals** are compliant with the SPIFFE ID format.
  * Multiple **Workloads** may share the same **Workload Principal**, but each **Workload** has a single canonical **Workload Principal**.
  * **Workload Principals** are accessible in Istio configuration as the `source.user` and `destination.user` attributes.

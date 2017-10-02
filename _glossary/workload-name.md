---
title: Workload Name
type: markdown
---
A unique name for a **Workload**, identifying it within the **Service Mesh**.
Unlike **Service Name** and **Workload Principal**, **Workload Name** is not a strongly verified property and should not be used when enforcing ACLs.
  * **Workload Names** are accessible in Istio configuration as the `source.name` and `destination.name` attributes.

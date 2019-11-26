---
title: Workload
---
A binary deployed by [operators](#operator) to deliver some function in Istio. Workloads have names, namespaces, and unique ids. These properties are available in policy and telemetry configuration
using the following [attributes](#attribute):

* `source.workload.name`, `source.workload.namespace`, `source.workload.uid`
* `destination.workload.name`, `destination.workload.namespace`, `destination.workload.uid`

In Kubernetes, a workload typically corresponds to a Kubernetes deployment,
while a [workload instance](#workload-instance) corresponds to an individual [pod](#pod) managed
by the deployment.

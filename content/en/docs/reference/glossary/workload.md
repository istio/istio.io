---
title: Workload
---
A binary deployed by [operators](/docs/reference/glossary/#operator) to deliver some function of a service mesh application.
Workloads have names, namespaces, and unique ids. These properties are available in policy and telemetry configuration
using the following [attributes](/docs/reference/glossary/#attribute):

* `source.workload.name`, `source.workload.namespace`, `source.workload.uid`
* `destination.workload.name`, `destination.workload.namespace`, `destination.workload.uid`

In Kubernetes, a workload typically corresponds to a Kubernetes deployment,
while a [workload instance](/docs/reference/glossary/#workload-instance) corresponds to an individual [pod](/docs/reference/glossary/#pod) managed
by the deployment.

---
title: Namespace Sameness
test: n/a
---

Within a multicluster mesh, [namespace sameness](https://github.com/kubernetes/community/blob/master/sig-multicluster/namespace-sameness-position-statement.md)
applies and all namespaces with a given name are considered to be the same namespace. If multiple clusters contain a
`Service` with the same namespaced name, in addition same port within the same service should make sure `port.name` literally equal, then they will be recognized as a single combined service. By default, traffic is
load-balanced across all clusters in the mesh for a given service.

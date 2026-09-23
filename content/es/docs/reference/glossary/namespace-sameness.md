---
title: Namespace Sameness
test: n/a
---

Within a multicluster mesh, [namespace sameness](https://github.com/kubernetes/community/blob/master/sig-multicluster/namespace-sameness-position-statement.md)
applies and all namespaces with a given name are considered to be the same namespace. If multiple clusters contain a
`Service` with the same namespaced name, they will be recognized as a single combined service. By default, traffic is
load-balanced across all clusters in the mesh for a given service.

Ports that match on _number_ must also have the same port _name_ to be considered as a combined `service port`.

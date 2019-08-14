---
title: Multicluster Mesh
---
A [service mesh](#service-mesh) composed of services running within more than one underlying cluster.
All clusters in a multicluster mesh are under the same administrative control and share the same service definitions.
A service named `foo` in namespace `ns1` of cluster 1 represents the same service as `foo` in `ns1` of cluster 2.

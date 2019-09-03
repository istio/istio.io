---
title: Service Mesh
---
A *service mesh* or simply *mesh* is an infrastructure layer that enables
managed, observable and secure communication between
[workload instances](/docs/reference/glossary/#workload-instance).

Service names combined with a namespace are unique within a mesh.
In a [multi-cluster](/docs/reference/glossary/#multi-cluster) mesh, for example,
the `bar` service in the `foo` namespace in `cluster-1` is considered the same
service as the `bar` service in the `foo` namespace in `cluster-2`.

Since [identities](/docs/reference/glossary/#identity) are shared within the service
mesh, workload instances can authenticate communication with any other workload
instance within the same service mesh.

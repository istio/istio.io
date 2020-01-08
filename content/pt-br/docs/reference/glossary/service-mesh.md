---
title: Service Mesh
---
A *service mesh* or simply *mesh* is an infrastructure layer that enables
managed, observable and secure communication between
[workload instances](/pt-br/docs/reference/glossary/#workload-instance).

Service names combined with a namespace are unique within a mesh.
In a [multicluster](/pt-br/docs/reference/glossary/#multicluster) mesh, for example,
the `bar` service in the `foo` namespace in `cluster-1` is considered the same
service as the `bar` service in the `foo` namespace in `cluster-2`.

Since [identities](/pt-br/docs/reference/glossary/#identity) are shared within the service
mesh, [workload instances](#workload-instance) can authenticate communication with any other [workload
instance](#workload-instance) within the same service mesh.

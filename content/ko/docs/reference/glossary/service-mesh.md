---
title: Service Mesh
test: n/a
---
A *service mesh* or simply *mesh* is an infrastructure layer that enables
managed, observable and secure communication between
[workload instances](/ko/docs/reference/glossary/#workload-instance).

Service names combined with a namespace are unique within a mesh.
In a [multicluster](/ko/docs/reference/glossary/#multicluster) mesh, for example,
the `bar` service in the `foo` namespace in `cluster-1` is considered the same
service as the `bar` service in the `foo` namespace in `cluster-2`.

Since [identities](/ko/docs/reference/glossary/#identity) are shared within the service
mesh, [workload instances](/ko/docs/reference/glossary/#workload-instance) can authenticate communication with any other [workload
instance](/ko/docs/reference/glossary/#workload-instance) within the same service mesh.

---
title: External Control Plane
test: n/a
---

An external control plane is a [control plane](/es/docs/reference/glossary/#control-plane)
that externally manages mesh workloads running in their own [clusters](/es/docs/reference/glossary/#cluster)
or other infrastructure. The control plane may, itself, be deployed in a cluster, although not
in one of the clusters that is part of the mesh it's controlling.
Its purpose is to cleanly separate the control plane from the data plane of a mesh.

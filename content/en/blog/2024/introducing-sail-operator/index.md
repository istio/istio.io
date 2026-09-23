---
title: "Introducing the Sail Operator: a new way to manage Istio"
description: Introducing the Sail Operator to manage Istio, a project part of the istio-ecosystem organization.
publishdate: 2024-08-19
attribution: "Francisco Herrera - Red Hat"
keywords: [istio,operator,sail,incluster,deprecation]
---

With the recent announcement of the In-Cluster IstioOperator [deprecation](/blog/2024/in-cluster-operator-deprecation-announcement/) in Istio 1.23 and its subsequent deletion for Istio 1.24, we want to build awareness of a
[new operator](https://github.com/istio-ecosystem/sail-operator) that the team at Red Hat have been developing to manage Istio as part of the [istio-ecosystem](https://github.com/istio-ecosystem) organization.

The Sail Operator manages the lifecycle of Istio control planes, making it easier and more efficient for cluster administrators to deploy, configure and upgrade Istio in large scale production environments. Instead of
creating a new configuration schema and reinventing the wheel, the Sail Operator APIs are built around Istio's Helm chart APIs. All installation and configuration options that are exposed by Istio's Helm charts are available
through the Sail Operator CRDs' values fields. This means that you can easily manage and customize Istio using familiar configurations without adding additional items to learn.

The Sail Operator has 3 main resource concepts:
* [Istio](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istio-resource): used to manage the Istio control planes.
* [Istio Revision](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istiorevision-resource): represents a revision of that control plane, which is an instance of Istio with a specific version and revision name.
* [Istio CNI](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istiocni-resource): used to manage the resource and lifecycle of Istio's CNI plugin. To install the Istio CNI Plugin, you create an `IstioCNI` resource.

Currently, the main feature of the Sail Operator is the Update Strategy. The operator provides an interface that manages the upgrade of Istio control plane(s).  It currently supports two update strategies:
* [In Place](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#inplace): with the `InPlace` strategy, the existing Istio control plane is replaced with a new version, and the workload sidecars
  immediately connect to the new control plane. This way, workloads don't need to be moved from one control plane instance to another.
* [Revision Based](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#revisionbased): with the `RevisionBased` strategy, a new Istio control plane instance is created for every change to the
  `Istio.spec.version` field. The old control plane remains in place until all workloads have been moved to the new control plane instance. Optionally, the `updateWorkloads` flag can be set to automatically move
  workloads to the new control plane when it is ready.

We know that doing upgrades of the Istio control plane carries risk and can require a substantial manual effort for large deployments and this is why it is our current focus. For the future, we are looking at how the
Sail Operator can better support use cases such as multi-tenancy and isolation, multi-cluster federation, and simplified integration with 3rd party projects.

The Sail Operator project is still alpha and under heavy development. Note that as an istio-ecosystem project, it is not supported as part of the Istio project. We are actively seeking feedback and contributions from the
community. If you want to get involved with the project please refer to the repo [documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/README.md) and [contributing guidelines](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md). If you are a
user, you can also try the new operator by following the instructions in the
[user documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md).

For more information, contact us:

* [Discussions](https://github.com/istio-ecosystem/sail-operator/discussions)
* [Issues](https://github.com/istio-ecosystem/sail-operator/issues)
* [Slack](https://istio.slack.com/archives/C06SE9XCK3Q)

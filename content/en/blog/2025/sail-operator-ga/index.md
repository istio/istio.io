---
title: "Sail Operator 1.0.0 released: manage Istio with an operator"
description: Dive in into the basics of the Sail Operator and check out an example to see how easy it is to use it to manage Istio.
publishdate: 2025-04-01
attribution: "Francisco Herrera - Red Hat"
keywords: [istio,operator,sail,incluster,istiooperator]
---

The [Sail Operator](https://github.com/istio-ecosystem/sail-operator) is a community project launched by Red Hat to build a modern [operator](https://www.redhat.com/en/topics/containers/what-is-a-kubernetes-operator) for Istio. [First announced in August 2024](/blog/2024/introducing-sail-operator/) we are pleased to announce Sail Operator is now GA with a clear mission: to simplify and streamline Istio management in your cluster.

## Simplified deployment & management

The Sail Operator is engineered to cut down the complexity of installing and running Istio. It automates manual tasks, ensuring a consistent, reliable, and uncomplicated experience from initial installation to ongoing maintenance and upgrades of Istio versions in your cluster. The Sail Operator APIs are built around Istio’s Helm chart APIs, which means that all the istio configurations are available through the Sail Operator CRD’s values.

We encourage users to go through our [documentation](https://github.com/istio-ecosystem/sail-operator/tree/main/docs) to learn more about this new way to manage your Istio environment.

The main resources that are part of the Sail Operator are:
* `Istio`: manages an Istio control plane.
* `IstioRevision`: represents a revision of the control plane.
* `IstioRevisionTag`: represents a stable revision tag, which functions as an alias for an Istio control plane revision.
* `IstioCNI`: manages Istio's CNI node agent.
* `ZTunnel`: manage the ambient mode ztunnel DaemonSet (Alpha feature).

{{< idea >}}
If you are migrating from the [since-removed Istio in-cluster operator](/blog/2024/in-cluster-operator-deprecation-announcement/), you can check this section in our [documentation](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#migrating-from-istio-in-cluster-operator) where we explain the equivalence of resources, or you can also try our [resource converter](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#converter-script) to easily convert your `IstioOperator` resource to an `Istio` resource.
{{< /idea >}}

## Main features and support

- Each component of the Istio control plane is managed independently by the Sail Operator through dedicated Kubernetes Custom Resources (CRs). The Sail Operator provides separate CRDs for components such as `Istio`, `IstioCNI`, and `ZTunnel`, allowing you to configure, manage, and upgrade them individually. Additionally, there are CRDs for `IstioRevision` and `IstioRevisionTag` to manage Istio control plane revisions.
- Support for multiple Istio versions. Currently the 1.0.0 version supports: 1.24.3, 1.24.2, 1.24.1, 1.23.5, 1.23.4, 1.23.3, 1.23.0.
- Two update strategies are supported: `InPlace` and `RevisionBased`. Check our documentation for more information about the update types supported.
- Support for multicluster Istio [deployment models](/docs/setup/install/multicluster/): multi-primary, primary-remote, external control plane. More information and examples in our [documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#multi-cluster).
- Ambient mode support is Alpha: check our specific [documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/common/istio-ambient-mode.md).
- Addons are managed separately from the Sail Operator. They can be easily integrated with the Sail Operator, check this section for the [documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#addons) for examples and more information.

## Why now?

As cloud native architectures continue to evolve, we feel a robust and user-friendly operator for Istio is more essential than ever. The Sail Operator offers developers and operations teams a consistent, secure, and efficient solution that feels familiar to those used to working with operators. Its GA release signals a mature solution, ready to support even the most demanding production environments.

## Try it out

Would you like to try out Sail Operator?
Let's install the Sail Operator by using the helm repository.

{{< text bash >}}
$ helm repo add sail-operator https://istio-ecosystem.github.io/sail-operator
$ helm repo update
$ kubectl create namespace sail-operator
$ helm install sail-operator sail-operator/sail-operator --version 1.0.0 -n sail-operator
{{< /text >}}

The operator is now installed in your cluster:

{{< text plain >}}
NAME: sail-operator
LAST DEPLOYED: Tue Mar 18 12:00:46 2025
NAMESPACE: sail-operator
STATUS: deployed
REVISION: 1
TEST SUITE: None
{{< /text >}}

Check the operator pod is running:

{{< text bash >}}
$ kubectl get pods -n sail-operator
{{< /text >}}

{{< text plain >}}
NAME                             READY   STATUS    RESTARTS   AGE
sail-operator-56bf994f49-j67ft   1/1     Running   0          87s
{{< /text >}}

Do you want to run an example to see how easy it is to manage Istio with the Sail Operator?
Now that you have the operator installed, you can try out the example described in our [docs](https://github.com/istio-ecosystem/sail-operator/tree/release-1.0/docs#example-using-the-revisionbased-strategy-and-an-istiorevisiontag). This example demonstrates how to use the `IstioRevision` and `IstioRevisionTag` resources to manage the Istio control plane updates.

In this example, you'll see how Sail Operator enables two Istio control planes to run concurrently, making it possible to migrate workloads with minimal risk of service disruption using the `RevisionBased` update strategy and `IstioRevisionTag`.

## Conclusion

The Sail Operator automates manual tasks, ensuring a consistent, reliable, and uncomplicated experience from initial installation to ongoing maintenance and upgrades of Istio in your cluster. The Sail Operator is an [istio-ecosystem](https://github.com/istio-ecosystem) project, and we encourage you to try it out and provide feedback to help us improve it, you can check our [contribution guide](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md) for more information about how to contribute to the project.

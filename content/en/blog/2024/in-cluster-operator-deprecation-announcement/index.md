---
title: "Istio has deprecated its In-Cluster Operator"
description: What you need to know if you are running the Operator controller in your cluster.
publishdate: 2024-08-14
attribution: "Mitch Connors (Microsoft), for the Istio Technical Oversight Committee"
keywords: [operator,deprecation]
---

Istio’s In-Cluster Operator has been deprecated in Istio 1.23.  Users leveraging the operator — which we estimate to be fewer than 10% of our user base — will need to migrate to other install and upgrade mechanisms in order to upgrade to Istio 1.24 or above. Read on to learn why we are making this change, and what operator users need to do.

## Does this affect you?

This deprecation only affects users of the [In-Cluster Operator](https://archive.istio.io/v1.23/docs/setup/install/operator/).  **Users who install Istio with the <code>istioctl install</code> command and an `IstioOperator` YAML file are not affected**.

To determine if you are affected, run `kubectl get deployment -n istio-system istio-operator` and `kubectl get IstioOperator`.  If both commands return non-empty values, your cluster will be affected. Based on recent polls, we expect that this will affect fewer than 10% of Istio users.

Operator-based Installations of Istio will continue to run indefinitely, but cannot be upgraded past 1.23.x.

## When do I need to migrate?

In keeping with Istio’s deprecation policy for Beta features, the Istio In-Cluster Operator will be removed with the release of Istio 1.24, roughly three months from this announcement. Istio 1.23 will be supported through March 2025, at which time operator users will need to migrate to another install mechanism to retain support.

## How do I migrate?

The Istio project will continue to support installation and upgrade via the `istioctl` command, as well as with Helm. Because of Helm’s popularity within the platform engineering ecosystem, we recommend most users migrate to Helm. `istioctl install` is based on Helm templates, and future versions may integrate deeper with Helm.

Helm installs can also be managed with GitOps tools like [Flux](https://fluxcd.io/) or [Argo CD](https://argo-cd.readthedocs.io/).

Users who prefer the operator pattern for running Istio can migrate to either of two new Istio Ecosystem projects, the Classic Operator Controller, or the Sail Operator.

### Migrating to Helm

Helm migration requires translating your `IstioOperator` YAML into Helm values. Istio 1.24 and above includes a `manifest translate` command to perform this operation. The output is a `values.yaml` file, and a shell script to install equivalent Helm charts.

{{< text bash >}}
$ istioctl manifest translate -f istio.yaml
{{< /text >}}

### Migrating to istioctl

Identify your `IstioOperator` custom resource: there should be only one result.

{{< text bash >}}
$ kubectl get IstioOperator
{{< /text >}}

Using the name of your resource, download your operator configuration in YAML format:

{{< text bash >}}
$ kubectl get IstioOperator <name> -o yaml > istio.yaml
{{< /text >}}

Disable the In-Cluster Operator. This will not disable your control plane or disrupt your current mesh traffic.

{{< text bash >}}
$ kubectl scale deployment -n istio-system istio-operator –replicas 0
{{< /text >}}

When you are ready to upgrade Istio to version 1.24 or later, follow [the upgrade instructions](/docs/setup/upgrade/canary/), using the `istio.yaml` file you downloaded above.

Once you have completed and verified your migration, run the following commands to clean up your operator resources:

{{< text bash >}}
$ kubectl delete deployment -n istio-system istio-operator
$ kubectl delete customresourcedefinition istiooperator
{{< / text >}}

### Migrating to the Classic Operator Controller

A new ecosystem project, the [Classic Operator Controller](https://github.com/istio-ecosystem/classic-operator-controller), is a fork of the original controller built into Istio. This project maintains the same API and code base as the original operator, but is maintained outside of Istio core.

Because the API is the same, migration is straightforward: only the installation of the new operator will be required.

Classic Operator Controller is not supported by the Istio project.

### Migrating to Sail Operator

A new ecosystem project, the [Sail Operator](https://github.com/istio-ecosystem/sail-operator), is able to install and manage the lifecycle of the Istio control plane in a Kubernetes or OpenShift cluster.

Sail Operator APIs are built around Istio's Helm chart APIs. All installation and configuration options that are exposed by Istio's Helm charts are available through the Sail Operator CRD's `values:` fields.

Sail Operator is not supported by the Istio project.

## What is an operator, and why did Istio have one?

The [operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) was popularized by CoreOS in 2016 as a method for codifying human intelligence into code. The most common use case is a database operator, where a user might have multiple database instances in one cluster, with multiple ongoing operational tasks (backups, vacuums, sharding).

Istio introduced istioctl and the in-cluster operator in version 1.4, in response to problems with Helm v2. Around the same time, Helm v3 was introduced, which addressed the community’s concerns, and is a preferred method for installing software on Kubernetes today. Support for Helm v3 was added in Istio 1.8.

Istio’s in-cluster operator handled installation of the service mesh components - an operation you generally do one time, and for one instance, per cluster. You can think of it as a way to run istioctl inside your cluster. However, this meant you had a high-privilege controller running inside your cluster, which weakens your security posture. It doesn’t handle any ongoing administration tasks (backing up, taking snapshots etc, are not requirements for running Istio).

The Istio operator is something you have to install into the cluster, which means you already have to manage the installation of something. Using it to upgrade the cluster likewise first required you to download and run a new version of istioctl.

Using an operator means you have created a level of indirection, where you have to have options in your custom resource to configure everything you may wish to change about an installation. Istio worked around this by offering the `IstioOperator` API, which allows configuration of installation options. This resource is used by both the in-cluster operator and istioctl install, so there is a trivial migration path for operator users.

Three years ago — around the time of Istio 1.12 — we updated our documentation to say that use of the operator for new Istio installations is discouraged, and that users should use istioctl or Helm to install Istio.

[Having three different installation methods has caused confusion](https://blog.howardjohn.info/posts/istio-install/), and in order to provide the best experience for people using Helm or istioctl - over 90% of our install base - we have decided to formally deprecate the in-cluster operator in Istio 1.23.

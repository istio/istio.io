---
title: "Sail Operator 1.0.0 released: manage Istio with an operator"
description: Dive in into the basics of the Sail Operator and check out an example to see how easy it is to use it to manage Istio.
publishdate: 2025-04-03
attribution: "Francisco Herrera - Red Hat"
keywords: [istio,operator,sail,incluster,istiooperator]
---

The [Sail Operator](https://github.com/istio-ecosystem/sail-operator) is a community project launched by Red Hat to build a modern [operator](https://www.redhat.com/en/topics/containers/what-is-a-kubernetes-operator) for Istio. [First announced in August 2024](/blog/2024/introducing-sail-operator/), we are pleased to announce Sail Operator is now GA with a clear mission: to simplify and streamline Istio management in your cluster.

## Simplified deployment & management

The Sail Operator is engineered to cut down the complexity of installing and running Istio. It automates manual tasks, ensuring a consistent, reliable, and uncomplicated experience from initial installation to ongoing maintenance and upgrades of Istio versions in your cluster. The Sail Operator APIs are built around Istio’s Helm chart APIs, which means that all the Istio configurations are available through the Sail Operator CRD’s values.

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
This example will show you how to safely do an update of your Istio control plane by using the revision-based upgrade strategy. This means you will have two Istio control planes running at the same time, allowing you to migrate workloads easily, minimizing the risk of traffic disruptions.

Prerequisites:
- Running cluster
- Helm
- Kubectl
- Istioctl

### Install the Sail Operator using Helm

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
NAME                             READY   STATUS    RESTARTS   AGE
sail-operator-56bf994f49-j67ft   1/1     Running   0          87s
{{< /text >}}

### Create `Istio` and `IstioRevisionTag` resources

Create an `Istio` resource with the version `v1.24.2` and an `IstioRevisionTag`:

{{< text bash >}}
$ kubectl create ns istio-system
$ cat <<EOF | kubectl apply -f-
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: istio-system
  updateStrategy:
    type: RevisionBased
    inactiveRevisionDeletionGracePeriodSeconds: 30
  version: v1.24.2
---
apiVersion: sailoperator.io/v1
kind: IstioRevisionTag
metadata:
  name: default
spec:
  targetRef:
    kind: Istio
    name: default
EOF
{{< /text >}}

Note that the `IstioRevisionTag` has a target reference to the `Istio` resource with the name `default`

Check the state of the resources created:
- `istiod` pods are running

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istiod-default-v1-24-2-bd8458c4-jl8zm   1/1     Running   0          3m45s
    {{< /text >}}

- `Istio` resource created

    {{< text bash >}}
    $ kubectl get istio
    NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
    default   1           1       1        default-v1-24-2   Healthy   v1.24.2   4m27s
    {{< /text >}}

- `IstioRevisionTag` resource created

    {{< text bash >}}
    $ kubectl get istiorevisiontag
    NAME      STATUS                    IN USE   REVISION          AGE
    default   NotReferencedByAnything   False    default-v1-24-2   4m43s
    {{< /text >}}

Note that the `IstioRevisionTag` status is `NotReferencedByAnything`. This is because there are currently no resources using the revision `default-v1-24-2`.

### Deploy sample application

Create a namespace and label it to enable Istio injection:

{{< text bash >}}
$ kubectl create namespace sample
$ kubectl label namespace sample istio-injection=enabled
{{< /text >}}

After labeling the namespace you will see that the `IstioRevisionTag` resource status will change to 'In Use: True', because there is now a resource using the revision `default-v1-24-2`:

{{< text bash >}}
$ kubectl get istiorevisiontag
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-2   6m24s
{{< /text >}}

Deploy the sample application:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml -n sample
{{< /text >}}

Confirm the proxy version of the sample app matches the control plane version:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

### Upgrade the Istio control plane to version 1.24.3

Update the `Istio` resource with the new version:

{{< text bash >}}
$ kubectl patch istio default -n istio-system --type='merge' -p '{"spec":{"version":"v1.24.3"}}'
{{< /text >}}

Check the `Istio` resource. You will see that there are two revisions and they are both 'ready':

{{< text bash >}}
$ kubectl get istio
NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
default   2           2       2        default-v1-24-3   Healthy   v1.24.3   10m
{{< /text >}}

The `IstioRevisiontag` now references the new revision:

{{< text bash >}}
$ kubectl get istiorevisiontag
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-3   11m
{{< /text >}}

There are two `IstioRevisions`, one for each Istio version:

{{< text bash >}}
$ kubectl get istiorevision
NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
default-v1-24-2          True    Healthy   True     v1.24.2   11m
default-v1-24-3          True    Healthy   True     v1.24.3   92s
{{< /text >}}

The Sail Operator automatically detects whether a given Istio control plane is being used and writes this information in the "In Use" status condition that you see above. Right now, all `IstioRevisions` and our `IstioRevisionTag` are considered "In Use":
* The old revision `default-v1-24-2` is considered in use because it is referenced by the sample application’s sidecar.
* The new revision `default-v1-24-3` is considered in use because it is referenced by the tag.
* The tag is considered in use because it is referenced by the sample namespace.

Confirm there are two control plane pods running, one for each revision:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                      READY   STATUS    RESTARTS   AGE
istiod-default-v1-24-2-bd8458c4-jl8zm     1/1     Running   0          16m
istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          6m32s
{{< /text >}}

Confirm the proxy sidecar version remains the same:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS                LDS                EDS                RDS                ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

Restart the sample pod:

{{< text bash >}}
$ kubectl rollout restart deployment -n sample
{{< /text >}}

Confirm the proxy sidecar version is updated:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                      VERSION
sleep-6f87fcf556-k9nh9.sample     Kubernetes     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     IGNORED     istiod-default-v1-24-3-68df97dfbb-v7ndm     1.24.3
{{< /text >}}

When an `IstioRevision` is no longer in use and is not the active revision of an `Istio` resource (for example, when it is not the version that is set in the `spec.version` field), the Sail Operator will delete it after a grace period, which defaults to 30 seconds. Confirm the deletion of the old control plane and `IstioRevision`:

- The old control plane pod is deleted

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                      READY   STATUS    RESTARTS   AGE
    istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          10m
    {{< /text >}}

- The old `IstioRevision` is deleted

    {{< text bash >}}
    $ kubectl get istiorevision
    NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
    default-v1-24-3          True    Healthy   True     v1.24.3   13m
    {{< /text >}}

- The `Istio` resource now only has one revision

    {{< text bash >}}
    $ kubectl get istio
    NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
    default   1           1       1        default-v1-24-3   Healthy   v1.24.3   24m
    {{< /text >}}

**Congratulations!** You have successfully updated your Istio control plane using the revision-based upgrade strategy.

{{< idea >}}
To check the latest Sail Operator version, visit our [releases page](https://github.com/istio-ecosystem/sail-operator/releases).  As this example may evolve over time, please refer to our [documentation](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#example-using-the-revisionbased-strategy-and-an-istiorevisiontag) to ensure you’re reading the most up-to-date version.
{{< /idea >}}

## Conclusion

The Sail Operator automates manual tasks, ensuring a consistent, reliable, and uncomplicated experience from initial installation to ongoing maintenance and upgrades of Istio in your cluster. The Sail Operator is an [istio-ecosystem](https://github.com/istio-ecosystem) project, and we encourage you to try it out and provide feedback to help us improve it, you can check our [contribution guide](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md) for more information about how to contribute to the project.

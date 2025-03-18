---
title: "Sail operator 1.0.0 has been released: manage Istio with an operator"
description: Sail Operator 1.0.0 released, a project part of the istio-ecosystem organization. Let's dive in into the basics of the Sail Operator and let's run an example to show how easy it is to manage Istio with it.
publishdate: 2025-03-19
attribution: "Francisco Herrera - Red Hat"
keywords: [istio,operator,sail,incluster,istiooperator]
---

The Sail operator is GA with a clear mission: to simplify and streamline Istio management in your cluster. By using Kubernetes operator practices, Sail operator aims to add new value to istio by improving the upgrade process.

## Simplified Deployment & Management

The Sail operator is engineered to cut down the complexity of installing and running Istio with an operator. It automates manual tasks, ensuring a consistent, reliable, and uncomplicated experience from initial installation to ongoing maintenance and upgrades of Istio versions in your cluster. Besides this, the Sail operator APIs are built around Istio’s Helm chart APIs, which means that all the istio configurations are available through the Sail Operator CRDs’ values.

We encourage users to go through our live [documentation](https://github.com/istio-ecosystem/sail-operator/tree/main/docs) to help you easily get deep into this new way to manage your istio control plane.

The main resources that are part of the Sail operator are:
* `Istio`: manages your istio control plane.
* `IstioRevision`: it represents a revision of the control plane.
* `IstioRevisionTag`: resource represents a stable Revision Tag, which functions as an alias for Istio control plane revisions.
* `IstioCNI`: Istio's CNI plugin resource.
* `ZTunnel`: ambient mode Ztunnel DaemonSet (alpha feature).

Note that if you are migrating from the [deprecated and deleted] In-Cluster Istio operator, you can check this section in our [documentation](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#migrating-from-istio-in-cluster-operator) where we explain the equivalence of resources, or you can try also our [resource converter](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#converter-script) to convert your  IstioOperator resource to an Istio resource easily.

## Main Features and support

- Support for multiple Istio versions.
- Two update strategies are supported: `InPlace` and `RevisionBased`. Check our documentation for more information about the update types supported.
- Support for multicluster Istio [deployment models](/docs/setup/install/multicluster/): multi-primary, primary-remote, external control plane. More information and examples in our [documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#multi-cluster).
- Support for [multiple mesh](/docs/ops/deployment/deployment-models/#multiple-meshes): The Sail Operator supports running multiple meshes on a single cluster and associating each workload with a specific mesh. Each mesh is managed by a separate control plane. More information and examples can be found [here](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#multiple-meshes-on-a-single-cluster).
- [Dual-Stack](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#dual-stack-support) support since istio `v1.23` version.
- Ambient is alpha: check our specific [documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/common/istio-ambient-mode.md).
- Addons are managed separately from the Sail Operator. They can be easily integrated with the Sail operator, you can check this section for the [documentation](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#addons) for examples and more information.

## Why Now?

As cloud-native architectures continue to evolve, a robust and user-friendly operator for Istio is more essential than ever. The Sail Operator offers developers and operations teams a consistent, secure, and efficient solution that feels familiar to those used to working with operators. Its GA release signals a mature solution, ready to support even the most demanding production environments.

## Try it out

Do you want to try our operator?
Going over this example will show you how to safely do an update of your istio control plane by using the revision-based upgrade strategy, this means you will have two Istio control planes running at the same time,allowing you to migrate workloads easily, minimizing the risk of traffic disruptions.

Prerequisites:
- Running cluster
- Helm
- Kubectl
- Istioctl

### Install the operator from the sail operator helm repository

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

### Check the operator pod running

{{< text bash >}}
$ kubectl get pods -n sail-operator
{{< /text >}}

{{< text plain >}}
NAME                             READY   STATUS    RESTARTS   AGE
sail-operator-56bf994f49-j67ft   1/1     Running   0          87s
{{< /text >}}

#### Create an Istio resource with istio version 1.24.2 and a Istio revision tag

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

Note that `IstioRevisionTag` has target reference to `Istio` resources with name default.

Check the state of the resources created:
- `istiod` pods are running

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}

{{< text plain >}}
NAME                                    READY   STATUS    RESTARTS   AGE
istiod-default-v1-24-2-bd8458c4-jl8zm   1/1     Running   0          3m45s
{{< /text >}}

- `Istio` resource created

{{< text bash >}}
$ kubectl get istio
{{< /text >}}

{{< text plain >}}
NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
default   1           1       1        default-v1-24-2   Healthy   v1.24.2   4m27s
{{< /text >}}

- `IstioRevisionTag` resource created

{{< text bash >}}
$ kubectl get istiorevisiontag
{{< /text >}}

{{< text plain >}}
NAME      STATUS                    IN USE   REVISION          AGE
default   NotReferencedByAnything   False    default-v1-24-2   4m43s
{{< /text >}}

Note that the `IstioRevisionTag` status is `NotReferencedByAnything`, this is because there is no resource referenced using the revision `default-v1-24-2`.

### Deploy sample application

- Create a namespace and label it to enable istio injection

{{< text bash >}}
$ kubectl create namespace sample
$ kubectl label namespace sample istio-injection=enabled
{{< /text >}}

As a result of the label of the namespace you will see that the `IstioRevisionTag` resource status will change to In Use true, this is because there is already one resource making reference to the revision `default-v1-24-2`.

{{< text bash >}}
$ kubectl get istiorevisiontag
{{< /text >}}

{{< text plain >}}
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-2   6m24s
{{< /text >}}

- Deploy the sample application

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml -n sample
{{< /text >}}

- Confirm istio proxy version of the sample app match the control plane version

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

{{< text plain >}}
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

#### Upgrade the Istio control plane to version 1.24.3

- Update the `Istio` resource with the new version

{{< text bash >}}
$ kubectl patch istio default -n istio-system --type='merge' -p '{"spec":{"version":"v1.24.3"}}'
{{< /text >}}

- Check the `Istio` resource, you will see that there are two revisions and there are two `Istio` ready

{{< text bash >}}
$ kubectl get istio
{{< /text >}}

{{< text plain >}}
NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
default   2           2       2        default-v1-24-3   Healthy   v1.24.3   10m
{{< /text >}}

- The `IstioRevisiontag` now references the new revision

{{< text bash >}}
$ kubectl get istiorevisiontag
{{< /text >}}

{{< text plain >}}
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-3   11m
{{< /text >}}

- There are two `IstioRevisions`, one for each istio version

{{< text bash >}}
$ kubectl get istiorevision
{{< /text >}}

{{< text plain >}}
NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
default-v1-24-2          True    Healthy   True     v1.24.2   11m
default-v1-24-3          True    Healthy   True     v1.24.3   92s
{{< /text >}}

The Sail Operator automatically detects whether a given Istio control plane is being used and writes this information in the "In Use" status condition that you see above. Right now, all `IstioRevisions` and our `IstioRevisionTag` are considered "In Use":
* The old revision `default-v1-24-2` is considered in use because it is referenced by the sample application’s sidecar
* The new revision `default-v1-24-3` is considered in use because it is referenced by the tag.
* The tag is considered in use because it is referenced by the sample namespace.

- Confirm there are two control plane pods running, one for each revision

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}

{{< text plain >}}
NAME                                      READY   STATUS    RESTARTS   AGE
istiod-default-v1-24-2-bd8458c4-jl8zm     1/1     Running   0          16m
istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          6m32s
{{< /text >}}

- Confirm the proxy sidecar version remains the same

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

{{< text plain >}}
NAME                              CLUSTER        CDS                LDS                EDS                RDS                ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

- Restart the sample pod

{{< text bash >}}
$ kubectl rollout restart deployment -n sample
{{< /text >}}

- Confirm the proxy sidecar version is updated

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

{{< text plain >}}
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                      VERSION
sleep-6f87fcf556-k9nh9.sample     Kubernetes     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     IGNORED     istiod-default-v1-24-3-68df97dfbb-v7ndm     1.24.3
{{< /text >}}

- When an `IstioRevision` is no longer in use and is not the active revision of an `Istio` resource (for example not the version that is set in the `spec.version` field), the Sail Operator will delete it after a grace period, which defaults to 30 seconds. Confirm the deletion of the old control plane and `IstioRevision`:

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}

{{< text plain >}}
NAME                                      READY   STATUS    RESTARTS   AGE
istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          10m
{{< /text >}}

{{< text bash >}}
$ kubectl get istiorevision
{{< /text >}}

{{< text plain >}}
NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
default-v1-24-3          True    Healthy   True     v1.24.3   13m
{{< /text >}}

{{< text bash >}}
$ kubectl get istio
{{< /text >}}

{{< text plain >}}
NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
default   1           1       1        default-v1-24-3   Healthy   v1.24.3   24m
{{< /text >}}

## Conclusion

The Sail Operator automates manual tasks, ensuring a consistent, reliable, and uncomplicated experience from initial installation to ongoing maintenance and upgrades of Istio versions in your cluster. The Sail Operator is a project part of the istio-ecosystem organization, and we encourage you to try it out and provide feedback to help us improve it, you can check our contribution guide [here](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md) for more information about how to contribute to the project.

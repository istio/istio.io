---
title: "Introducing KWOK for Istio Control Plane Testing"
description: "Looking for a simple way to test your Istio control plane at scale? Look no further! KWOK makes it easy."
publishdate: 2023-07-20
attribution: "Shiming Zhang (DaoCloud)"
keywords: [Istio, kwok, testing]
---

Looking for a simple way to test your Istio control plane at scale?
Look no further! KWOK makes it easy.

In this article, we'll introduce [KWOK](https://kwok.sigs.k8s.io/) and set up a test environment for the Istio control plane.

For the latest information, see [KWOK with Istio](https://kwok.sigs.k8s.io/docs/examples/istio/).

## What is KWOK?

KWOK stands for Kubernetes WithOut Kubelet. So far, it provides two tools:

- `kwok` is the cornerstone of this project, responsible for simulating the lifecycle of fake nodes, pods, and other Kubernetes API resources.

- `kwokctl` is a CLI tool designed to streamline the creation and management of clusters, with nodes simulated by `kwok`.

## Why use KWOK?

KWOK has several advantages:

- **Lightweight**: You can simulate thousands of nodes on your laptop without significant consumption
  of CPU or memory resources.
- **Fast**: You can create and delete clusters and nodes almost instantly,
  without waiting for boot or provisioning.
- **Compatibility**: KWOK works with tools or clients that are compliant with Kubernetes APIs,
  such as kubectl, helm, etc.
- **Portability**: KWOK has no specific hardware or software requirements.
  You can run it using prebuilt images, once Docker/Podman/nerdctl is installed.
  Alternatively, binaries are also available for all platforms and can be easily installed.
- **Flexibility**: You can configure different node types, labels, taints, capacities, conditions, etc.,
  and you can configure different pod behaviors, status, etc. to test different scenarios and edge cases.

{{< image width="90%"
    link="./manage-clusters.svg"
    caption="Using kwokctl to manage simulated clusters"
    >}}

## Testing Istio with KWOK

To create a test environment for the Istio control plane with KWOK, you can follow these steps:

### Set up Cluster

{{< text bash >}}
$ kwokctl create cluster --runtime kind
{{< /text >}}

### Create Node

{{< text bash >}}
$ kubectl apply -f https://kwok.sigs.k8s.io/examples/node.yaml
{{< /text >}}

### Deploy Istio

{{< text bash >}}
$ istioctl install -y
{{< /text >}}

### Migrate Controllers to Real Node

We need to use [kind](https://kind.sigs.k8s.io/) to run the controller because KWOK itself cannot actually run a Pod.

{{< text bash >}}
$ kubectl patch deploy istiod -n istio-system --type=json -p='[{"op":"add","path":"/spec/template/spec/nodeName","value":"kwok-kwok-control-plane"}]'
{{< /text >}}

### Create Pod and Inject Sidecar

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
{{< /text >}}

You will see that the Pod is running on a fake node. However, it is still an injected sidecar.

## Limitations

With KWOK alone, we can only simulate the cluster data,
while the real environment is also connected with Sidecar's xDS, which cannot be simulated.
We need a xDS client connection generator to complete the load simulation.

### pilot-load

[pilot-load](https://github.com/howardjohn/pilot-load) is a tool, that can be generate xDS client connections to a pilot instance.

Just need to sue `pilot-load cluster`, the --cluster-type has 3 modes:

- real: actually create real pods. Can be combined with kwok to make those 0 cost
- fake-node: replace kwok basically. Create real pods but assign to fake nodes
- fake: connect to a plain apiserver with no controller-manager at all

We can use `pilot-load cluster --cluster-type real` with `kwokctl create cluster` to simulate a complete Istio control plane performance test.

## Look ahead

I have an idea for `pilot-load` to support `kwok` directly, but it is not implemented yet.

That is `pilot-load` watches all the pods managed by kwok and emulates the xDS client.

Then we can then manipulate the resource, view the metrics panel and stress test it as we normally would with Istio.

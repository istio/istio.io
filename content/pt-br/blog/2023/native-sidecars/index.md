---
title: Kubernetes Native Sidecars in Istio
description: Demoing the new SidecarContainers feature with Istio.
publishdate: 2023-08-15
attribution: "John Howard (Google)"
keywords: [istio,sidecars,kubernetes]
---

If you have heard anything about service meshes, it is that they work using the sidecar pattern: a proxy server is deployed alongside your application code.
The sidecar pattern is just that: a pattern.
Up until this point, there has been no formal support for sidecar containers in Kubernetes at all.

This has caused a number of problems: what if you have a job that terminates by design, but a sidecar container that doesn't?
This exact use case is the [most popular ever on the Kubernetes issue tracker](https://github.com/kubernetes/kubernetes/issues/25908).

A formal proposal for adding sidecar support in Kubernetes was raised in 2019. With many stops and starts along the way,
and after a reboot of the project last year, formal support for sidecars is being released to Alpha in Kubernetes 1.28.
Istio has implemented support for this feature, and in this post you can learn how to take advantage of it.

## Sidecar woes

Sidecar containers give a lot of power, but come with some issues.
While containers within a pod can share some things, their *lifecycle's* are entirely decoupled.
To Kubernetes, both of these containers are functionally the same.

However, in Istio they are not the same - the Istio container is required for the primary application container to run,
and has no value without the primary application container.

This mismatch in expectation leads to a variety of issues:
* If the application container starts faster than Istio's container, it cannot access the network.
  This wins the [most +1's](https://github.com/istio/istio/issues/11130) on Istio's GitHub by a landslide.
* If Istio's container shuts down before the application container, the application container cannot access the network.
* If an application container intentionally exits (typically from usage in a `Job`), Istio's container will still run and keep the pod running indefinitely.
  This is also a [top GitHub issue](https://github.com/istio/istio/issues/11659).
* `InitContainers`, which run before Istio's container starts, cannot access the network.

Countless hours have been spent in the Istio community and beyond to work around these issues - to limited success.

## Fixing the root cause

While increasingly-complex workarounds in Istio can help alleviate the pain for Istio users, ideally all of this would just work - and not just for Istio.
Fortunately, the Kubernetes community has been hard at work to address these directly in Kubernetes.

In Kubernetes 1.28, a new feature to add native support for sidecars was merged, closing out over 5 years of ongoing work.
With this merged, all of our issues can be addressed without workarounds!

While we are on the "GitHub issue hall of fame", [these](https://github.com/kubernetes/kubernetes/issues/25908) two [issues](https://github.com/kubernetes/kubernetes/issues/65502) account for #1 and #6 all time issues in Kubernetes - and have finally been closed!

A special thanks goes to the huge group of individuals involved in getting this past the finish line.

## Trying it out

While Kubernetes 1.28 was just released, the new `SidecarContainers` feature is Alpha (and therefore, off by default), and the support for the feature in Istio is not yet shipped, we can still try it out today - just don't try this in production!

First, we need to spin up a Kubernetes 1.28 cluster, with the `SidecarContainers` feature enabled:

{{< text shell >}}
$ cat <<EOF | kind create cluster --name sidecars --image gcr.io/istio-testing/kind-node:v1.28.0 --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  SidecarContainers: true
EOF
{{< /text >}}

Then we can download the latest Istio 1.19 pre-release (as 1.19 is not yet out). I used Linux here.
This is a pre-release of Istio, so again - do not try this in production!
When we install Istio, we will enable the feature flag for native sidecar support and turn on access logs to help demo things later.

{{< text shell >}}
$ TAG=1.19.0-beta.0
$ curl -L https://github.com/istio/istio/releases/download/$TAG/istio-$TAG-linux-amd64.tar.gz | tar xz
$ ./istioctl install --set values.pilot.env.ENABLE_NATIVE_SIDECARS=true -y --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

And finally we can deploy a workload:

{{< text shell >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f samples/sleep/sleep.yaml
{{< /text >}}

Let's look at the pod:

{{< text shell >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
sleep-7656cf8794-8fhdk   2/2     Running   0          51s
{{< /text >}}

Everything looks normal at first glance...
If we look under the hood, we can see the magic, though.

{{< text shell >}}
$ kubectl get pod -o "custom-columns="\
"NAME:.metadata.name,"\
"INIT:.spec.initContainers[*].name,"\
"CONTAINERS:.spec.containers[*].name"

NAME                     INIT                     CONTAINERS
sleep-7656cf8794-8fhdk   istio-init,istio-proxy   sleep
{{< /text >}}

Here we can see all the `containers` and `initContainers` in the pod.

Surprise! `istio-proxy` is now an `initContainer`.

More specifically, it is an `initContainer` with `restartPolicy: Always` set (a new field, enabled by the `SidecarContainers` feature).
This tells Kubernetes to treat it as a sidecar.

This means that later containers in the list of `initContainers`, and all normal `containers` will not start until the proxy container is ready.
Additionally, the pod will terminate even if the proxy container is still running.

### Init container traffic

To put this to the test, let's make our pod actually do something.
Here we deploy a simple pod that sends a request in an `initContainer`.
Normally, this would fail.

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: sleep
spec:
  initContainers:
  - name: check-traffic
    image: istio/base
    command:
    - curl
    - httpbin.org/get
  containers:
  - name: sleep
    image: istio/base
    command: ["/bin/sleep", "infinity"]
{{< /text >}}

Checking the proxy container, we can see the request both succeeded and went through the Istio sidecar:

{{< text shell >}}
$ kubectl logs sleep -c istio-proxy | tail -n1
[2023-07-25T22:00:45.703Z] "GET /get HTTP/1.1" 200 - via_upstream - "-" 0 1193 334 334 "-" "curl/7.81.0" "1854226d-41ec-445c-b542-9e43861b5331" "httpbin.org" ...
{{< /text >}}

If we inspect the pod, we can see our sidecar now runs *before* the `check-traffic` `initContainer`:

{{< text shell >}}
$ kubectl get pod -o "custom-columns="\
"NAME:.metadata.name,"\
"INIT:.spec.initContainers[*].name,"\
"CONTAINERS:.spec.containers[*].name"

NAME    INIT                                  CONTAINERS
sleep   istio-init,istio-proxy,check-traffic   sleep
{{< /text >}}

### Exiting pods

Earlier, we mentioned that when applications exit (common in `Jobs`), the pod would live forever.
Fortunately, this is addressed as well!

First we deploy a pod that will exit after one second and doesn't restart:

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: sleep
spec:
  restartPolicy: Never
  containers:
- name: sleep
  image: istio/base
  command: ["/bin/sleep", "1"]
{{< /text >}}

And we can watch its progress:

{{< text shell >}}
$ kubectl get pods -w
NAME    READY   STATUS     RESTARTS   AGE
sleep   0/2     Init:1/2   0          2s
sleep   0/2     PodInitializing   0          2s
sleep   1/2     PodInitializing   0          3s
sleep   2/2     Running           0          4s
sleep   1/2     Completed         0          5s
sleep   0/2     Completed         0          12s
{{< /text >}}

Here we can see the application container exited, and shortly after Istio's sidecar container exits as well.
Previously, the pod would be stuck in `Running`, while now it can transition to `Completed`.
No more zombie pods!

## What about ambient mode?

Last year, Istio announced [ambient mode](/blog/2022/introducing-ambient-mesh/) - a new data plane mode for Istio that doesn't rely on sidecar containers.
So with ambient mode coming, does any of this even matter?

I would say a resounding "Yes"!

While the impacts of sidecar are lessened when ambient mode is used for a workload, I expect that almost all large scale Kubernetes users have some sort of sidecar in their deployments.
This could be Istio workloads they don't want to migrate to ambient, that they haven't *yet* migrated, or things unrelated to Istio.
So while there may be fewer scenarios where this matters, it still is a huge improvement for the cases where sidecars are used.

You may wonder the opposite - if all our sidecar woes are addressed, why do we need ambient mode at all?
There are still a variety of benefits ambient brings with these sidecar limitations addressed.
For example, [this blog post](/blog/2023/waypoint-proxy-made-simple/) goes into details about why decoupling proxies from workloads is advantageous.

## Try it out yourself

We encourage the adventurous readers to try this out themselves in testing environments!
Feedback for these experimental and alpha features is critical to ensure they are stable and meeting expectations before promoting them.
If you try it out, let us know what you think in the [Istio Slack](/get-involved/)!

In particular, the Kubernetes team is interested in hearing more about:

* Handling of shutdown sequence, especially when there are multiple sidecars involved.
* Backoff restart handling when sidecar containers are crashing.
* Edge cases they have not yet considered.

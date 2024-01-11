---
title: "Cut Service Mesh Overhead with Istio Ambient Mesh"
description: An anaylsis of how cloud resources are utilized in ambient and sidecar service mesh architectures.
publishdate: 2023-07-14
attribution: "Greg Hanson - Solo.io"
keywords: [istio,ambient,waypoint,ztunnel]
---

Last year the Istio community announced [ambient mesh](/blog/2022/introducing-ambient-mesh/), a new data plane mode which replaces sidecar proxies with per-namespace proxies.

[Sidecars](/docs/reference/glossary/#sidecar) have been a staple of Istio’s architecture since day one, and are the way that most of Istio's features are provided today.  However, sidecars require the injection of an additional container to each Kubernetes `Pod` resource, and each sidecar container requires resources be allocated to it.

Ambient mesh was released in [alpha](/docs/releases/feature-stages/#feature-phase-definitions) in [Istio 1.18](/news/releases/1.18.x/announcing-1.18/). This makes it easy to install, test, and to preview what it will mean for you when it's production-ready.

Aside from the many other benefits of ambient mesh, the simple fact you no longer have to run as many proxies means that you can expect resource (and thus cost) savings. As you will see, these can be very substantial.

## Check Out the Savings

Our test scenario deploys four instances of the [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo), each to their own namespace, with each underlying microservice scaled to 3 replicas. There will be a total of 48 application services and 144 applications pods in this setup. Test scenarios utilize the provided [loadgenerator](https://github.com/GoogleCloudPlatform/microservices-demo/tree/main/src/loadgenerator) microservice running in each of the namespaces to generate traffic during the observed window. The tests deployed Istio in several scenarios and resource usage and allocation are compared across the runs. The scenarios are:

- Istio with sidecar
- Ambient with L4 ztunnel only
- Ambient with L4 ztunnel and L7 waypoint proxies (one per namespace, scaled to 3 replicas)

There are significant savings across the board for all ambient scenarios when compared to sidecars – up to 99% savings with only L4 and 89% with L4+L7.

{{< image width="100%"
    link="savings.png"
    caption="Total Memory and CPU: Consumption and Allocation"
    >}}

Looking at [total CPU and memory consumption numbers](#a-closer-look), we see that we can remove the allocations required for a sidecar container in every application pod in the mesh. The result is that memory usage of Istio’s dataplane in the ztunnel-only ambient scenario sees *more than 99% savings* compared to sidecar scenarios, and still 89% savings when waypoints are added. Looking at CPU, ztunnel once again sees 82% savings compared to the sidecar scenario, and 40% savings when waypoints are deployed.

## Where the Savings Are Coming From

Ambient mesh was designed to minimize resource requirements for users in their Kubernetes clusters. To explain how ambient does this, we must first clarify allocation versus utilization. When deploying a Kubernetes cluster, nodes determine the overall capacity of the cluster and customer deployments, and pods are an allocation of that capacity. Utilization is a measure of how well this is done. As an architecture, sidecars interfere with effective utilization as they:

- Define a high minimum for allocation at any scale
- Can strand capacity by reserving more than is needed
- Shift operational burden to adjust allocation if more than the default is needed

The sidecar architecture forces this mode of allocation on users. Ambient solves these issues by leveraging a new architecture that separates the responsibilities of zero-trust networking and L7 policy handling. This is done with two new components to Istio: ztunnels and waypoint proxies.

- [Ztunnels](/blog/2023/rust-based-ztunnel/) are a brand new Istio component written in Rust that are designed to be fast, secure, and lightweight. Ztunnels are deployed per node and serve all pods co-located on the node. They enable the most basic service mesh configurations for L4 features such as mTLS, telemetry, authentication, and L4 authorizations.
- [Waypoint proxies](/blog/2023/waypoint-proxy-made-simple/) provide L7 mesh features such as VirtualService routing, L7 telemetry, and L7 authorizations policies. Waypoints are still based on Envoy and are deployed per namespace or service account.

These ztunnels and waypoint proxies work in tandem to replace sidecars in the Istio service mesh, and most importantly, unlike sidecars they scale independent to a user's applications pods. So let’s take a closer look at how the two architectures compare in the scenarios above.

## A Closer Look

{{< image width="100%"
    link="cpu-by-pod.png"
    caption="CPU usage by pod for sidecar and ambient pods"
    >}}

{{< image width="100%"
    link="memory-by-pod.png"
    caption="Memory usage by pod for sidecar and ambient pods"
    >}}

{{< image width="100%"
    link="resource-usage.png"
    caption="CPU and Memory usage for cluster"
    >}}

Let’s start by looking at CPU usage by pod. In the sidecar scenarios, the containers utilizing the most CPU resources are the [frontend](https://github.com/GoogleCloudPlatform/microservices-demo/tree/main/src/frontend) service sidecars, which is the main server hit by the load generators and also responsible for making any subsequent calls to other underlying microservices.

In the ambient scenarios, a particular ztunnel's performance depends on the distribution of services across the nodes in the cluster. Ztunnels do use more CPU than a sidecar, but each ztunnel is handling inbound and outbound connections for about 48 application pods whereas a sidecar is responsible for only one.  In the ambient with both ztunnel and waypoint proxy scenario, there is an increase in average CPU usage per ztunnel as traffic is now directed to waypoint proxies. The waypoint proxies themselves consume more resources than their sidecar counterparts.  This is expected since there are only 3 waypoints handling L7 processing for all 48 pods in the namespace.

Next is memory usage by pod. In both ambient scenarios, the L4 ztunnel consumes less memory than a sidecar. In fact, in the L4 only scenario, almost all three ztunnel instances combined consume less memory than a single sidecar. Ztunnels are able to serve multiple applications while consuming fewer resources than sidecars because they are purpose built, and designed to have a small footprint. For a more in depth explanation of how this is done, refer to this [blog](/blog/2023/rust-based-ztunnel/#a-purpose-built-ztunnel). Waypoint proxies consume a similar amount of resources as sidecars do, but once again see a minor increase due to the same reasons outlined above for CPU. So what do these per pod usages mean for the totals across the cluster? Everything.

{{< image width="100%"
    link="total-cpu.png"
    caption="Total CPU usage for sidecar and ambient scenarios"
    >}}

{{< image width="100%"
    link="total-memory.png"
    caption="Total memory usage for sidecar and ambient scenarios"
    >}}

{{< image width="100%"
    link="cpu-by-pod-stacked.png"
    caption="Stacked CPU usage by pod for sidecar and ambient pods"
    >}}

{{< image width="100%"
    link="memory-by-pod-stacked.png"
    caption="Stacked memory usage by pod for sidecar and ambient pods"
    >}}

Looking at total CPU and memory utilization, we have to remember that in sidecar scenarios there are 144 sidecar containers required (48 services, 3 replicas each), while in ambient, only three ztunnel containers and 12 waypoint proxies are required. The stacked CPU and memory by pod graphs are excellent at highlighting just how many additional containers are present between scenarios. Memory usage of the Istio dataplane in the ztunnel-only ambient scenario sees *more than 99% savings* compared to sidecar scenarios, and 89% when waypoints are added. Looking at CPU, ztunnel sees *82% savings* compared to sidecar scenarios, and 40% when waypoints are deployed.

Finally, let’s consider allocation since the graphs above have only covered usage. Every sidecar resource has a default request of 100 millicores vCPU and 128 MB memory. For simplicity, we assume ztunnels and waypoint proxies have similar requests and limits as their sidecar counterparts. Breaking it down, that’s a 98% reduction in allocated resources with ztunnel, and 90% when waypoints are included.

{{< image width="100%"
    link="allocation.png"
    caption="CPU and memory allocation and cost breakdown for sidecar and ambient scenarios"
    >}}

Going further, we can calculate a dollar amount for these numbers by referring to [GCP monthly pricing](https://cloud.google.com/compute/vm-instance-pricing) for a monthly cost per GB memory and per CPU. Consider these two different machines and their costs:

- `n2-standard-4` (4 CPU, 16 GB) at $141/month
- `n2-highmem-4` (4 CPU, 32 GB) at $191/month

Calculating the difference in memory shows 1GB costs $3.33/month. In our test this brings memory costs from $60 down to only $1 in the ztunnel-only scenario, and $6 with waypoints deployed.  Similarly for CPU:

- `n2-standard-4` (4 CPU, 16 GB) at $141/month
- `n2-highmem-2` (2 CPU, 16 GB) at $95/month

Calculating the difference in CPU shows 1 CPU costs $23/month. In our test this brings CPU costs from over $300 down to only $7 in the ztunnel-only scenario, and $34 with waypoints deployed.

We can literally put a dollar amount on the savings ambient brings - and so can you!

## Test It Out

In comparison to what most users run Istio with in production, this test cluster is tiny. However, we expect even more savings with larger clusters and when more services are deployed. We encourage everyone to see what the savings with Istio ambient mesh looks like in their environments. Also note that these scripts have been pushed to GitHub so feel free to check them out [here](https://github.com/solo-io/ambient-performance/tree/boutique-demo). For tracking CPU and memory usage throughout the test scenarios, versions of [Prometheus](https://prometheus.io/), [node-exporter](https://prometheus.io/docs/guides/node-exporter/), and [Grafana](https://grafana.com/) are installed. A custom Grafana dashboard was created for observing relevant data, which can be found and imported from GitHub [here](https://github.com/solo-io/ambient-performance/blob/boutique-demo/dashboard/ambient-performance-analysis.json).

## Conclusion

Ka-ching. These results were collected with an alpha version of ambient, which is now [merged into the main branch](/blog/2023/ambient-merged-istio-main/) and included in Istio 1.18.

Huge thanks to all the Istio maintainers who work very hard to make ambient as lean and performant as possible. Ambient service mesh’s goal of reducing infrastructure costs is bearing fruit and setting a solid foot forward on its roadmap to production readiness. These early numbers suggest users could cut their cloud usage by *99%* and resource requirements by *90%* – especially if users only require an L4 mesh.

## Learn More About Istio Ambient Mesh

Check out these resources to learn more:

- [Ambient Mesh Documentation](/docs/ops/ambient/)
- [Introducing Ambient Mesh](/blog/2022/introducing-ambient-mesh/)
- [Get Started with Ambient Mesh](/blog/2022/get-started-ambient/)
- [Ambient Mesh Security Deep Dive](/blog/2022/ambient-security/)
- [Introducing Rust-Based Ztunnel for Istio Ambient Mesh](/blog/2023/rust-based-ztunnel/)
- [Istio Ambient Waypoint Proxy Made Simple](/blog/2023/waypoint-proxy-made-simple/)
- [Istio Ambient Service Mesh Merged to Istio’s Main Branch](/blog/2023/ambient-merged-istio-main/)

---
title: "Cut Service Mesh Overhead with Istio Ambient Mesh"
description: An anaylsis of how cloud resources are utilized in ambient and sidecar service mesh architectures.
publishdate: 2023-05-10
attribution: "Greg Hanson - Solo.io"
keywords: [istio,ambient,waypoint,ztunnel]
---

Istio Ambient Mesh is the new Istio data plane without requiring sidecars, refer to the [announcement](/blog/2022/introducing-ambient-mesh/) for more details. Istio Ambient Mesh will be included in Istio 1.18 but [pre-release builds](https://github.com/istio/istio/releases/tag/1.18.0-alpha.0) are available now. 

Sidecars have been a staple of Istio’s architecture since day one and are responsible for the majority of features available in Istio today. However, sidecars require the injection of an additional container to each Kubernetes pod resource, each of which needs allocated resources from the pod.

Many of you are familiar with the simplified operation brought by the Istio ambient architecture. Let’s explore how ambient mesh cuts the service mesh costs typically associated with sidecars.

## Check Out the Savings

Our test scenario deploys one [Fortio](https://github.com/fortio/fortio) client instance and three different versions of the [httpbin](https://github.com/postmanlabs/httpbin) service, each scaled to 10 replicas. The Fortio client will send requests to version 1 of httpbin for a few minutes, repeat the same for version 2, and finally for version 3. The tests deployed Istio in several scenarios and resource usage and allocation are compared across the runs. The scenarios are:

 - Istio with sidecar
 - Ambient with L4 ztunnel only
 - Ambient with L4 ztunnel and L7 waypoint proxies

Spoilers! There are significant savings across the board for all ambient scenarios when compared to sidecars – up to 99% savings in usage and 90% in allocation.

{{< image width="100%"
    link="savings.png"
    caption="Total Memory and CPU: Consumption and Allocation"
    >}}

Looking at total CPU and memory consumption, we have to remember that in the [ambient architecture](https://istio.io/latest/blog/2022/introducing-ambient-mesh/), there are not sidecar containers for every application pod in the mesh. The result is that memory usage of Istio’s dataplane in the ztunnel-only ambient scenario uses *1%* of what is used in sidecar scenarios, and still only 10% when waypoints are added. Looking at CPU, ztunnel once again uses *1%* of what the sidecar scenario requires, and 15% when waypoints are deployed.

Moving on to allocation, every sidecar resource has a default request of 100 millicores vCPU and 128Mi memory.  Assuming ztunnels and waypoint proxies have similar requests and limits as sidecars, that’s a *90% reduction* in allocated resources between L4 ambient and sidecar and 80% with waypoints!

## Where the Savings Are Coming From

Ambient mesh was designed to minimize resource requirements for users in their Kubernetes clusters. To explain how ambient does this, we must first clarify allocation versus utilization. When deploying a Kubernetes cluster on a hosted environment, nodes determine the overall capacity of the cluster and customer deployments, and pods are an allocation of that capacity. Utilization is a measure of how well this is done. As an architecture, sidecars interfere with effective utilization as they:

 - Define a high minimum for allocation at any scale
 - Can strand capacity by reserving more than is needed
 - Shift operational burden to adjust allocation if more than the default is needed

The sidecar architecture forces this mode of allocation on users. Ambient solves these issues by leveraging a new architecture that separates the responsibilities of zero-trust networking and L7 policy handling. This is done with two new components to Istio: ztunnels and waypoint proxies.

 - [Ztunnels](/blog/2023/rust-based-ztunnel/) are a brand new Istio component written in Rust that are designed to be fast, secure, and lightweight. Ztunnels are deployed per node on a cluster and enable the most basic service mesh configurations for L4 features such as mTLS, telemetry, authentication, and L4 authorizations.
 - [Waypoint proxies](/blog/2023/waypoint-proxy-made-simple/) provide L7 mesh features such as VirtualService routing, L7 telemetry, and L7 authorizations policies. Waypoints are still based on Envoy and are deployed at the namespace level per ServiceAccount. 

These ztunnels and waypoint proxies work in tandem to replace sidecars in the Istio service mesh. So let’s take a closer look at how the two architectures compare in the tests above.

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

Let’s start by looking at CPU usage by pod. In the sidecar scenarios, the container utilizing the most CPU resources is the Fortio client sidecar istio-proxy, which is responsible for sending traffic to all pods during the test. The httpbin server istio-proxy containers see very few changes since the requests are load balanced across N httpbin replicas and their sidecars.

In the ambient scenarios, each ztunnel instance sees small spikes as they handle cross-node traffic for the different requests. These ztunnel spikes depend on which nodes the Fortio client and httpbin server reside on as the different versions are hit. In the ambient with both ztunnel and waypoint proxy scenario, there are clear spikes in the waypoint proxies as a particular version of httpbin is called since one waypoint captures traffic for all instances of that version.

Though the waypoints consume similar resources as sidecars, the Rust-based ztunnel has a much smaller CPU utilization. An individual ztunnel use *less than 20%* in comparison to a sidecar and all three ztunnels for the entire cluster combined use less than a single sidecar!

Next is memory usage by pod. In all Istio scenarios, memory usage stays relatively constant for each pod during the test runs. In both ambient scenarios, the L4 ztunnel consumes so little memory it’s almost hard to display them on the same scale as sidecar usage. Waypoint proxies consume a similar amount of resources as sidecars do, with only minor improvements. So what do these per pod usage improvements mean for the totals across the cluster? Everything.

{{< image width="100%"
    link="total-cpu.png"
    caption="Total CPU usage for sidecar and ambient scenarios"
    >}}

{{< image width="100%"
    link="total-memory.png"
    caption="Total memory usage for sidecar and ambient scenarios"
    >}}

{{< image width="100%"
    link="cpu-by-pod.png"
    caption="Stacked CPU usage by pod for sidecar and ambient pods"
    >}}

{{< image width="100%"
    link="memory-by-pod-stacked.png"
    caption="Stacked memory usage by pod for sidecar and ambient pods"
    >}}

Looking at total CPU and memory utilization, we have to remember that in sidecar scenarios there are 31 sidecar containers required (one Fortio client and 30 httpbin servers), while in ambient, only three ztunnel containers and three waypoint proxies are required. The stacked CPU and memory by pod graphs are excellent at highlighting just how many additional containers are present between scenarios. Memory usage of the Istio dataplane in the ztunnel-only ambient scenario uses *1%* of what is used in sidecar scenarios, and still only 10% when waypoints are added. Looking at CPU, ztunnel once again uses *1%* of what sidecar scenarios require, and 15% when waypoints are deployed.

Finally, let’s consider allocation since the graphs above have only covered usage. Every sidecar resource has a default request of 100 millicores vCPU and 128Mi memory, as well as limits set for 2 vCPUs and 1Gi memory. For simplicity, we assume ztunnels and waypoint proxies have similar requests and limits as their sidecar counterparts – even though every measurement so far has suggested ztunnels will require significantly less. Breaking it down, that’s a 90% reduction in allocated resources with ztunnel, and 80% when waypoints are included.

{{< image width="100%"
    link="allocation.png"
    caption="Memory usage by pod for sidecar and ambient pods"
    >}}

Going further, we can calculate a dollar amount for these numbers by referring to [GCP monthly pricing](https://cloud.google.com/compute/vm-instance-pricing) for a monthly cost per GB memory and per CPU. Consider these two different machines and their costs:

 - n2-standard-4 (4CPU, 16GB) at $141/month
 - n2-highmem-4 (4CPU, 32GB) at $191/month 

Calculating the difference in memory results in 1GB costing $3.33/month. Similarly for CPU:

 - n2-standard-4 (4CPU, 16GB) at $141/month
 - n2-highmem-2 (2CPU, 16GB) at $95/month

Calculating the difference results in 1 CPU costing approximately $23/month. We can literally put a dollar amount on the savings ambient brings! 

## Test It Out!

In comparison to what most users run Istio with in production, this test cluster is tiny. However, we expect even more savings with larger clusters and when more services are deployed. We encourage everyone to see what the savings with Istio ambient mesh look like in their environments. Also note that these scripts have been pushed to GitHub so feel free to check them out [here](https://github.com/solo-io/ambient-performance/tree/fortio-ambient). For tracking CPU and memory usage throughout the test scenarios, versions of [Prometheus](https://prometheus.io/), [node-exporter](https://prometheus.io/docs/guides/node-exporter/), and [Grafana](https://grafana.com/) are installed. A custom Grafana dashboard was created for observing relevant data, which can be found and imported from GitHub [here](https://github.com/solo-io/ambient-performance/blob/fortio-ambient/dashboard/ambient-performance-analysis.json).

## Conclusion

Ka-ching. These results were collected with a pre-alpha version of ambient which is now [merged into the main branch](https://istio.io/latest/blog/2023/ambient-merged-istio-main/). 

Ambient service mesh’s goal of reducing infrastructure costs is bearing fruit and setting a solid foot forward on its roadmap to production readiness. These early numbers suggest users could cut their cloud usage by *99%* and resource requirements by *90%* – especially if users only require an L4 mesh.

## Learn More About Istio Ambient Mesh

Check out these resources to learn more:

 - [Introducing Ambient Mesh](/latest/blog/2022/introducing-ambient-mesh/) article from John Howard – Google, Ethan J. Jackson – Google, Yuval Kohavi – Solo.io, Idit Levine – Solo.io, Justin Pettit – Google, Lin Sun – Solo.io
 - [Get Started with Ambient Mesh](/latest/blog/2022/get-started-ambient/) guide by Lin Sun – Solo.io, John Howard – Google
 - [Ambient Mesh Security Deep Dive](/latest/blog/2022/ambient-security/) article by Ethan Jackson – Google, Yuval Kohavi – Solo.io, Justin Pettit – Google, Christian Posta – Solo.io
 - [Introducing Rust-Based Ztunnel for Istio Ambient Mesh](https://istio.io/latest/blog/2023/rust-based-ztunnel/) article by Lin Sun – Solo.io, John Howard – Google
 - [Istio Ambient Waypoint Proxy Made Simple](https://istio.io/latest/blog/2023/waypoint-proxy-made-simple/) article by Lin Sun – Solo.io, John Howard – Google
 - [Istio Ambient Service Mesh Merged to Istio’s Main Branch](https://istio.io/latest/blog/2023/ambient-merged-istio-main/) article by Lin Sun – Solo.io, John Howard – Google
 - [The Cloudcast](https://www.thecloudcast.net/2022/09/istio-ambient-mesh.html) podcast with Louis Ryan – Solo.io, Christian Posta – Solo.io
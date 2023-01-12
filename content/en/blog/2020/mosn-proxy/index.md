---
title: "Using MOSN with Istio: an alternative data plane"
subtitle: "A Cloud Native Proxy for Edge or Service Mesh"
description: "An alternative sidecar proxy for Istio."
publishdate: 2020-07-28
attribution: "Wang Fakang (mosn.io)"
keywords: [mosn,sidecar,proxy]
---

[MOSN](https://github.com/mosn/mosn) (Modular Open Smart Network) is a network proxy server written in Go. It was built at [Ant Group](https://www.antfin.com) as a sidecar/API Gateway/cloud-native Ingress/Layer 4 or Layer 7 load balancer etc. Over time, we've added extra features, like a multi-protocol framework, multi-process plug-in mechanism, a DSL, and support for the [xDS APIs](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol). Supporting xDS means we are now able to use MOSN as the network proxy for Istio. This configuration is not supported by the Istio project; for help, please see [Learn More](#learn-more) below.

## Background

In the service mesh world, using Istio as the control plane has become the mainstream. Because Istio was built on Envoy, it uses Envoy's data plane [APIs](https://blog.envoyproxy.io/the-universal-data-plane-api-d15cec7a) (collectively known as the xDS APIs). These APIs have been standardized separately from Envoy, and so by implementing them in MOSN, we are able to drop in MOSN as a replacement for Envoy. Istio's integration of third-party data planes can be implemented in three steps, as follows.

- Implement xDS protocols to fulfill the capabilities for data plane related services.
- Build `proxyv2` images using Istio's script and set the relevant `SIDECAR` and other parameters.
- Specify a specific data plane via the `istioctl` tool and set the proxy-related configuration.

## Architecture

MOSN has a layered architecture with four layers, NET/IO, Protocol, Stream, and Proxy, as shown in the following figure.

{{< image width="80%"
    link="./mosn-arch.png"
    caption="The architecture of MOSN"
    >}}

- NET/IO acts as the network layer, monitoring connections and incoming packets, and as a mount point for the listener filter and network filter.
- Protocol is the multi-protocol engine layer that examines packets and uses the corresponding protocol for decode/encode processing.
- Stream does a secondary encapsulation of the decode packet into stream, which acts as a mount for the stream filter.
- Proxy acts as a forwarding framework for MOSN, and does proxy processing on the encapsulated streams.

## Why use MOSN?

Before the service mesh transformation, we have expected that as the next generation of Ant Group's infrastructure, service mesh will inevitably bring revolutionary changes and evolution costs. We have a very ambitious blueprint: ready to integrate the original network and middleware various capabilities have been re-precipitated and polished to create a low-level platform for the next-generation architecture of the future, which will carry the responsibility of various service communications.

This is a long-term planning project that takes many years to build and meets the needs of the next five or even ten years, and cooperates to build a team that spans business, SRE, middleware, and infrastructure departments. We must have a network proxy forwarding plane with flexible expansion, high performance, and long-term evolution. Nginx and Envoy have a very long-term capacity accumulation and active community in the field of network agents. We have also borrowed from other excellent open source network agents such as Nginx and Envoy. At the same time, we have enhanced research and development efficiency and flexible expansion. Mesh transformation involves a large number of departments and R & D personnel. We must consider the landing cost of cross-team cooperation. Therefore, we have developed a new network proxy MOSN based on Go in the cloud-native scenario. For Go's performance, we also did a full investigation and test in the early stage to meet the performance requirements of Ant Group's services.

At the same time, we received a lot of feedback and needs from the end user community. Everyone has the same needs and thoughts. So we combined the actual situation of the community and ourselves to conduct the research and development of MOSN from the perspective of satisfying the community and users. We believe that the open source competition is mainly competition between standards and specifications. We need to make the most suitable implementation choice based on open source standards.

## What is the difference between MOSN and Istio's default proxy?

### Differences in language stacks

MOSN is written in Go. Go has strong guarantees in terms of production efficiency and memory security. At the same time, Go has an extensive library ecosystem in the cloud-native era. The performance is acceptable and usable in the service mesh scenario. Therefore, MOSN has a lower intellectual cost for companies and individuals using languages such as Go and Java.

### Differentiation of core competence

- MOSN supports a multi-protocol framework, and users can easily access private protocols with a unified routing framework.
- Multi-process plug-in mechanism, which can easily extend the plug-ins of independent MOSN processes through the plug-in framework, and do some other management, bypass and other functional module extensions.
- Transport layer national secret algorithm support with Chinese encryption compliance, etc.

### What are the drawbacks of MOSN

- Because MOSN is written in Go, it doesn't have as good performance as Istio default proxy, but the performance is acceptable and usable in the service mesh scenario.
- Compared with Istio default proxy, some features are not fully supported, such as WASM, HTTP3, Lua, etc.  However, these are all in the [roadmap](https://docs.google.com/document/d/12lgyCW-GmlErr_ihvAO7tMmRe87i70bv2xqe4h2LUz4/edit?usp=sharing) of MOSN, and the goal is to be fully compatible with Istio.

## MOSN with Istio

The following describes how to set up MOSN as the data plane for Istio.

## Setup Istio

You can download a zip file for your operating system from the [Istio release](https://github.com/istio/istio/releases/tag/1.5.2) page. This file contains: the installation file, examples and the `istioctl` command line tool.
To download Istio (this example uses Istio 1.5.2) uses the following command.

{{< text bash >}}
$ export ISTIO_VERSION=1.5.2
$ curl -L https://istio.io/downloadIstio | sh -
{{< /text >}}

The downloaded Istio package is named `istio-1.5.2` and contains:
- `install/kubernetes`: Contains YAML installation files related to Kubernetes.
- `examples/`: Contains example applications.
- `bin/`: Contains the istioctl client files.

Switch to the folder where Istio is located.

{{< text bash >}}
$ cd istio-$ISTIO_VERSION/
{{< /text >}}

Add the `istioctl` client path to `$PATH` with the following command.

{{< text bash >}}
$ export PATH=$PATH:$(pwd)/bin
{{< /text >}}

## Setting MOSN as the Data Plane

It is possible to flexibly customize the Istio control plane and data plane configuration parameters using the `istioctl` command line tool. MOSN can be specified as the data plane for Istio using the following command.

{{< text bash >}}
$ istioctl manifest apply  --set .values.global.proxy.image="mosnio/proxyv2:1.5.2-mosn"  --set meshConfig.defaultConfig.binaryPath="/usr/local/bin/mosn"
{{< /text >}}

Check that Istio-related pods and services are deployed successfully.

{{< text bash >}}
$ kubectl get svc -n istio-system
{{< /text >}}

If the service `STATUS` is Running, then Istio has been successfully installed using MOSN and you can now deploy the Bookinfo sample.

## Bookinfo Examples

You can run the Bookinfo sample by following the [MOSN with Istio tutorial](https://katacoda.com/mosn/courses/istio/mosn-with-istio) where you can find instructions for using MOSN and Istio. You can install MOSN and get to the same point you would have using the default Istio instructions with Envoy.

## Moving forward

Next, MOSN will not only be compatible with the features of the latest version of Istio, but also evolve in the following aspects.

- _As a microservices runtime_, MOSN oriented programming makes services lighter, smaller and faster.
- _Programmable_, support WASM.
- _More scenario support_, Cache Mesh/Message Mesh/Block-chain Mesh etc.

MOSN is an open source project that anyone in the community can use, improve, and enjoy. We'd love you to join us! [Here](https://github.com/mosn/community) are a few ways to find out what's happening and get involved.

## Learn More

- [MOSN website](https://mosn.io/en)
- [MOSN community](https://mosn.io/en/docs/community/)
- [MOSN tutorials](https://katacoda.com/mosn)

---
title: "Introducing MOSN: An Alternative Data Plane"
subtitle: "A Cloud Native Proxy for Edge or Service Mesh"
description: "An alternative sidecar proxy for Istio."
publishdate: 2020-07-17
attribution: "Wang Fakang(mosn.io)"
keywords: [mson,sidecar,proxy]
---

Thanks to the efforts of the MOSN community, MOSN has completed the most of adaptation for Istio. The MOSN [v0.14.0 release](https://github.com/mosn/mosn/releases/tag/v0.14.0) is now compatible with Istio 1.5.x, and it has went through the BookInfo sample as the data plane of Istio.

## Background

In the Service Mesh world, using Istio as the control plane has become the mainstream. Istio provides dynamic configuration of routes, service discovery, etc. to data plane proxies via the xDS protocol. The proxy can conveniently serve as Istio's data by simply interfacing with Envoy's xDS protocol. Istio's integration of third-party data planes can be implemented in three steps, as follows.

- Implement xDS protocols to fulfill the capabilities for data plane related services.
- Build `proxyv2` images using Istio's script and set the relevant `SIDCAR` and other parameters.
- Specify a specific data plane via the `istioctl` tool and set the proxy-related configuration.

## What is MOSN?

MOSN is a network proxy written in Golang. It can be used as a cloud-native network data plane, providing services with the following proxy functions: multi-protocol, modular, intelligent, and secure. MOSN is the short name of Modular Open Smart Network (proxy). MOSN can be integrated with any Service Mesh which supports xDS API. It can also be used as an independent Layer 4 or Layer 7 load balancer, API Gateway, cloud-native Ingress, etc.

## Architecture

MOSN follows the OSI (Open Systems Interconnection), it has four layers, NET/IO, Protocol, Stream, and Proxy, as shown in the following figure.

{{< image width="80%"
    link="./mosn-arch.png"
    caption="The architecture of MOSN"
    >}}

- NET/IO acts as the network layer, monitoring connections and incoming packets, and as a mount point for the listener filter and network filter.
- Protocol is the multi-protocol engine layer that examines packets and uses the corresponding protocol for decode/encode processing.
- Stream does a secondary encapsulation of the decode packet into stream, which acts as a mount for the stream filter.
- Proxy acts as a forwarding framework for MOSN, and does proxy processing on the encapsulated streams.

## MOSN with Istio

MOSN can be used not only as a stand-alone Layer 4/Layer 7 load balancer, but can also be integrated into Istio as a sidecar proxy or ingress gateway in Kubernetes. The following is an introduction to the use of MOSN as an Istio data plane. Tryout on [katacoda](https://katacoda.com/mosn/courses/istio/mosn-with-istio).

## Setup Istio

You can download a zip file for your operating system from the [Istio release](https://github.com/istio/istio/releases/tag/1.5.2) page. This file contains: the installation file, examples and the `istioctl` command line tool.
To download Istio (this example uses Istio 1.5.2) uses the following command.

{{< text bash >}}   
$ export ISTIO_VERSION=1.5.2
$ curl -L https://raw.githubusercontent.com/istio/istio/release-1.5/release/downloadIstioCandidate.sh | sh - 
{{< /text >}} 

The downloaded Istio package is named `istio-1.5.2` and contains:
- `install/kubernetes`: Contains YAML installation files related to Kubernetes.
- `examples/`: Contains example applications.
- `bin/`: Contains the istioctl client files.

Switch to the folder where of Istio located.

{{< text bash >}}
$ cd istio-$ISTIO_VERSION/
{{< /text >}}

Add the `istioctl` client path to `$PATH` with the following command.

{{< text bash >}}
$ export PATH=$PATH:$(pwd)/bin
{{< /text >}}

Until now, it has been possible to flexibly customize the Istio control plane and data plane configuration parameters via the `istioctl` command line tool.

## Setting MOSN as the Data Plane

MOSN is specified as the data plane in Istio via the parameters of the istioctl command.

{{< text bash >}}
$ istioctl manifest apply  --set .values.global.proxy.image="mosnio/proxyv2:1.5.2-mosn"   --set meshConfig.defaultConfig.binaryPath="/usr/local/bin/mosn"
{{< /text >}}

Check that Istio-related pod services are deployed successfully.

{{< text bash >}}
$ kubectl get svc -n istio-system
{{< /text >}}

If the service `STATUS` is Running, then Istio has been successfully installed and you can deploy the BookInfo sample later.

## Bookinfo Examples

You can run the BookInfo samples through [katacoda](https://katacoda.com/mosn/courses/istio/mosn-with-istio) where you can find some other tutorials for MOSN and Istio.

## Learn More

- [MOSN website](https://mosn.io/en)
- [MOSN community](https://mosn.io/en/docs/community/)
- [MOSN tutorials](https://katacoda.com/mosn)

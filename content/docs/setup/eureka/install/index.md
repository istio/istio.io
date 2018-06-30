---
title: Installation
description: Instructions for installing the Istio control plane in an Eureka based environment.
weight: 30
keywords: [eureka]
---

Using Istio in a non-Kubernetes environment involves a few key tasks:

1. Setting up the Istio control plane with the Istio API server
1. Adding the Istio sidecar to every instance of a service
1. Ensuring requests are routed through the sidecars

## Setting up the control plane

Istio control plane consists of four main services: Pilot, Mixer, Citadel, and
the API server.

### API server

Istio's API server (based on Kubernetes' API server) provides key functions
such as configuration management and Role-Based Access Control. The API
server requires an
[etcd cluster](https://kubernetes.io/docs/getting-started-guides/scratch/#etcd)
as a persistent store. Detailed instructions for setting up the API server can
be found
[here](https://kubernetes.io/docs/getting-started-guides/scratch/#apiserver-controller-manager-and-scheduler).

#### Local install

For _proof of concept_ purposes, it is possible to install
a simple single container API server using the following Docker Compose file:

{{< text yaml >}}
version: '2'
services:
  etcd:
    image: quay.io/coreos/etcd:latest
    networks:
      default:
        aliases:
          - etcd
    ports:
      - "4001:4001"
      - "2380:2380"
      - "2379:2379"
    environment:
      - SERVICE_IGNORE=1
    command: [
              "/usr/local/bin/etcd",
              "-advertise-client-urls=http://0.0.0.0:2379",
              "-listen-client-urls=http://0.0.0.0:2379"
             ]

  istio-apiserver:
    image: gcr.io/google_containers/kube-apiserver-amd64:v1.7.3
    networks:
      default:
        aliases:
          - apiserver
    ports:
      - "8080:8080"
    privileged: true
    environment:
      - SERVICE_IGNORE=1
    command: [
               "kube-apiserver", "--etcd-servers", "http://etcd:2379",
               "--service-cluster-ip-range", "10.99.0.0/16",
               "--insecure-port", "8080",
               "-v", "2",
               "--insecure-bind-address", "0.0.0.0"
             ]
{{< /text >}}

### Other Istio components

Debian packages for Istio Pilot, Mixer, and Citadel are available through the
Istio release. Alternatively, these components can be run as Docker
containers (docker.io/istio/pilot, docker.io/istio/mixer,
docker.io/istio/citadel). Note that these components are stateless and can
be scaled horizontally. Each of these components depends on the Istio API
server, which in turn depends on the etcd cluster for persistence.

## Adding sidecars to service instances

Each instance of a service in an application must be accompanied by the
Istio sidecar. Depending on the unit of your installation (Docker
containers, VM, bare metal nodes), the Istio sidecar needs to be installed
into these components.  For example, if your infrastructure uses VMs, the
Istio sidecar process must be run on each VM that needs to be part of the
service mesh.

## Routing traffic through the Istio sidecar

Part of the sidecar installation should involve setting up appropriate IP
Table rules to transparently route application's network traffic through
the Istio sidecars. The IP table script to setup such forwarding can be
found [here](https://raw.githubusercontent.com/istio/istio/{{<branch_name>}}/tools/deb/istio-iptables.sh).

> This script must be executed before starting the application or
> the sidecar process.

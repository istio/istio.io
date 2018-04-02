---
title: Installation
overview: Instructions for installing the Istio control plane in a Consul based environment, with or without Nomad.

order: 30

layout: docs
type: markdown
---

> Note: Setup on Nomad has not been tested.

Using Istio in a non-kubernetes environment involves a few key tasks:

1. Setting up the Istio control plane with the Istio API server
2. Adding the Istio sidecar to every instance of a service
3. Ensuring requests are routed through the sidecars

## Setting up the Control Plane

Istio control plane consists of four main services: Pilot, Mixer, CA, and
the API server.

### API Server

Istio's API server (based on Kubernetes' API server) provides key functions
such as configuration management and Role-Based Access Control. The API
server requires an
[etcd cluster](https://kubernetes.io/docs/getting-started-guides/scratch/#etcd)
as a persistent store. Detailed instructions for setting up the API server can
be found
[here](https://kubernetes.io/docs/getting-started-guides/scratch/#apiserver-controller-manager-and-scheduler). 
Documentation on set of startup options for the Kubernetes API server can be found [here](https://kubernetes.io/docs/admin/kube-apiserver/)

#### Local Install

For _proof of concept_ purposes, it is possible to install
a simple single container API server using the following Docker-compose file:

```yaml
version: '2'
services:
  etcd:
    image: quay.io/coreos/etcd:latest
    networks:
      istiomesh:
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
      istiomesh:
        ipv4_address: 172.28.0.13
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
```


### Other Istio Components

Debian packages for Istio Pilot, Mixer, and CA are available through the
Istio release. Alternatively, these components can be run as Docker
containers (docker.io/istio/pilot, docker.io/istio/mixer,
docker.io/istio/istio-ca). Note that these components are stateless and can
be scaled horizontally. Each of these components depends on the Istio API
server, which in turn depends on the etcd cluster for persistence. To
achieve high availability, each control plane service could be run as a
[job](https://www.nomadproject.io/docs/job-specification/index.html) in
Nomad, where the
[service stanza](https://www.nomadproject.io/docs/job-specification/service.html)
can be used to describe the desired properties of the control plane services.


## Adding Sidecars to Service Instances

Each instance of a service in an application must be accompanied by the
Istio sidecar. Depending on the unit of your installation (Docker
containers, VM, bare metal nodes), the Istio sidecar needs to be installed
into these components.  For example, if your infrastructure uses VMs, the
Istio sidecar process must be run on each VM that needs to be part of the
service mesh.

One way to package the sidecars into a Nomad-based deployment is to add the
Istio sidecar process as a task in a
[task group](https://www.nomadproject.io/docs/job-specification/group.html). A
task group is a collection of one or more related tasks that are guaranteed to be
colocated on the same host. However, unlike Kubernetes Pods, tasks in a
group do not share the same network namespace. Hence, care must be taken to
ensure that only one task group is run per host, when using `iptables`
rules to transparently re-route all network traffic via the Istio
sidecar. When support for non-transparent proxying (application explicitly
talks to the sidecar) is available in Istio, this restriction will no
longer apply.

## Routing traffic through Istio Sidecar

Part of the sidecar installation should involve setting up appropriate IP
Table rules to transparently route application's network traffic through
the Istio sidecars. The IP table script to setup such forwarding can be
found in the
[here](https://raw.githubusercontent.com/istio/istio/master/tools/deb/istio-iptables.sh).

> Note: This script must be executed before starting the application or
> the sidecar process. 

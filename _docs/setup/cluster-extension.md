---
title: Istio Kubernetes Cluster Extension
overview: Instructions to add external machines to your Istio managed Kubernetes cluster.

order: 25

layout: docs
type: markdown
---

This task shows how to install Istio in a non-kubernetes machine in the same network
(VPC, VPN) as the Kubernetes cluster.

_This document is under construction._

## Prerequisites

* You have [installed Istio](install-kubernetes.html) on your cluster

* The machine must have IP connectivity to the endpoints in the cluster. This
typically requires same VPC or a VPN connection, as well as a container network that
provides direct (without NAT or firewall deny) routing to the endpoints. The machine
is not required to have access to the cluster IP addresses assigned by K8S.

* The control plane (Pilot, Mixer, CA) and Kubernetes DNS server must be accessible
from the VM. This is typically done using an [Internal Load
Balancer](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer).

## Installation steps

Setup consists of preparing the cluster for extensions and installing and configuring each VM.

An example script to help with the cluster setup is available in
[install/tools/setupMeshEx.sh](https://raw.githubusercontent.com/istio/istio/master/install/tools/setupMeshEx.sh).

An example script to help configure a machine is available in [install/tools/setupIstioVM.sh](https://raw.githubusercontent.com/istio/istio/master/install/tools/setupIstioVM.sh).
You should customize it based on your provisioning tools and DNS requirements.

### Preparing the K8s cluster

* Setup internal load balancers for Kube DNS, Pilot, Mixer and CA. This step is specific to
each cluster, you may need to add annotations.

```bash
  admin$ install/tools/setupMeshEx initCluster
  
  or 
  
  admin$ kubectl apply -f install/kubernetes/meshex.yaml
```

* Generate the Istio 'cluster.env' config to be deployed in the VMs. This file contains
the cluster IP address ranges to intercept. 

```bash
  admin$ install/tools/setupMeshEx generateConfigs MY_CLUSTER_NAME
  
```

Example generated files:

   ```bash

    vm$ cat /usr/local/istio/proxy/cluster.env
   ISTIO_SERVICE_CIDR=10.23.240.0/20

  ```
* Generate DNS config file to be used in the VMs. This will allow apps on the VM to resolve
cluster service names, which will be intercepted by the sidecar and forwarded.

```bash
  admin$ install/tools/setupMeshEx generateConfigs MY_CLUSTER_NAME

```

Example generated files:

   ```bash

   vm$ cat /etc/dnsmasq/kubedns
   server=/svc.cluster.local/10.128.0.6
   address=/istio-mixer/10.128.0.7
   address=/mixer-server/10.128.0.7
   address=/istio-pilot/10.128.0.5
   address=/istio-ca/10.128.0.8

  ```

### Setting up the machines

* Copy the config files and istio debian files to each machine joining the cluster.

* Configure and verify DNS settings - this may require installing dnsmasq, adding it to
/etc/resolv.conf directly or via DHCP scripts.  To verify, check that the VM can resolve
names and connect to pilot, for example:

    ```bash

    dig istio-pilot.istio-system
    curl http://istio-mixer.istio-system:42422/metrics
    ```

* If auth is enabled, extract the initial kubernetes secrets and copy them to the machine.
An example in 'istio_provision_cert' - the generated files must be copied to /etc/certs on
each machine.

* Install istio debian files and start 'istio' and 'istio-auth-node-agent' services.


After setup, the machine should be able to access services running in the k8s cluster
or other cluster extension machines.


## Running services on a cluster extension machine

* Configure the sidecar to intercept the port. This is configured in /var/lib/istio/envoy/sidecar.env,
using the ISTIO_INBOUND_PORTS environment variable.

  Example (on the VM running the service):

   ```bash

   echo "ISTIO_INBOUND_PORTS=27017,3306,8080" > /var/lib/istio/envoy/sidecar.env
   systemctl restart istio
   ```

* Manually configure a selector-less service and endpoints. The 'selector-less' service is used for
services that are not backed by Kubernetes pods.

   Example, on a machine with permissions to modify k8s services:
   ```bash

   # istioctl register servicename machine-ip portname:port
   istioctl -n onprem register mysql 1.2.3.4 3306
   istioctl -n onprem register svc1 1.2.3.4 http:7000
   ```

After the setup, k8s pods and other cluster extensions should be able to access the
services running on the machine.

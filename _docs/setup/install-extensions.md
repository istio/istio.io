---
title: Istio with Cluster Extensions
overview: Quick Start instructions to extend the Istio service mesh with external machines.

order: 30

layout: docs
type: markdown
---

This task shows how to install Istio in a non-kubernetes machine in the same network
(VPC, VPN) as the kubernetes cluster.


## Prerequisites

* The machine must have IP connectivity to the nodes and endpoints in the cluster.

* The control plane (Pilot, Mixer, CA) and kuberentes DNS server must be accessible
from the VM in order for the machine to access services running in the cluster. This
is typically done using an [Internal Load Balancer](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer)

_This document is under construction._

## Installation steps

Example functions to help with the setup are available in install/tools/istio_vm_common.sh -
depending on cluster and environment you may need to tweak them. The functions need to run
on an cluster admin machine, with permissions to kubernetes and the VM.

An example script to run on a machine is available in install/tools/istio_vm_setup.sh.
You should customize it to match your normal provisioning toos and DNS requirements.

* Setup internal load balancers for Kube DNS, Pilot, Mixer and CA. This step is specific to
each cluster - the istioInitILB function has an example for GKE using internal load balancers.
This step should result in IP addresses accessible from the VM and allowing direct access
to the components above.

* Generate iptables config files to be used in the VMs. Istio sidecar  will
use a /usr/local/istio/proxy/cluster.env file, containing the cluster IP address ranges to intercept.
You can use the 'istioGenerateClusterConfigs' function to generate this file on the admin machine.

Example generated files:
   ```bash

   cat /usr/local/istio/proxy/cluster.env
   ISTIO_SERVICE_CIDR=10.23.240.0/20

  ```

* Generate DNS config file to be used in the VMs.
As an example using dnsmasq for DNS configuration, you can use the 'istioGenerateClusterConfigs' function.

Example generated files:
   ```bash

   cat /etc/dnsmasq/kubedns
   server=/svc.cluster.local/10.128.0.6
   address=/istio-mixer/10.128.0.7
   address=/mixer-server/10.128.0.7
   address=/istio-pilot/10.128.0.5
   address=/istio-ca/10.128.0.8

  ```

* Copy the config files to each machine joining the cluster, and make sure dnsmasq is installed
and works properly.

To verify, check that the VM can resolve names and connect to pilot, for example:

    ```bash
    dig ...
    curl ...
    ```

* If auth is enabled, extract the initial kubernetes secrets and copy them to the machine.
An example is 'istio_provision_cert' - the generated files must be copied to /etc/certs on
each machine.

* Download istio debian files and install them on the machines, and start 'istio' and
'istio-auth-node-agent' services.


After setup, the machine should be able to access services running in the k8s cluster
or other cluster extension machines.

## Running services on a cluster extension machine

* Intercept the port with istio sidecar. This is configured in /var/lib/istio/envoy/sidecar.env,
using the ISTIO_INBOUND_PORTS

  Example (on the VM running the service):

   ```bash

   echo "ISTIO_INBOUND_PORTS=27017,8080" > /var/lib/istio/envoy/sidecar.env
   systemctl restart istio
   ```

* Manually configure a selector-less service and endpoints. The 'selector-less' service is used for
services that are not backed by Kubernetes pods.

   Example, on a machine with permissions to modify k8s services:
   ```bash

   istioctl register SERVICENAME ...

   ```

After the setup, k8s pods and other cluster extensions should be able to access the
services running on the machine.

## Debugging cluster extensions

...
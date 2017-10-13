---
title: Istio Mesh Expansion
overview: Instructions for integrating VMs and bare metal hosts into an Istio mesh deployed on Kubernetes.

order: 60

layout: docs
type: markdown
---

Instructions for integrating VMs and bare metal hosts into an Istio mesh
deployed on Kubernetes.

## Prerequisites

* Setup Istio on Kubernetes by following the instructions in the [Installation guide](quick-start.html).

* The machine must have IP connectivity to the endpoints in the mesh. This
typically requires a VPC or a VPN, as well as a container network that
provides direct (without NAT or firewall deny) routing to the endpoints. The machine
is not required to have access to the cluster IP addresses assigned by Kubernetes.

* The Istio control plane services (Pilot, Mixer, CA) and Kubernetes DNS server must be accessible
from the VMs. This is typically done using an [Internal Load
Balancer](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer).
You can also use NodePort, run Istio components on VMs, or use custom network configurations,
separate documents will cover these advanced configurations.

## Installation steps

Setup consists of preparing the mesh for expansion and installing and configuring each VM.

An example script to help with Kubernetes setup is available in
[install/tools/setupMeshEx.sh](https://raw.githubusercontent.com/istio/istio/master/install/tools/setupMeshEx.sh). Check the script content and environment variables supported (like GCP_OPTS).

An example script to help configure a machine is available in [install/tools/setupIstioVM.sh](https://raw.githubusercontent.com/istio/istio/master/install/tools/setupIstioVM.sh).
You should customize it based on your provisioning tools and DNS requirements.

### Preparing the Kubernetes cluster for expansion

* Setup Internal Load Balancers (ILBs) for Kube DNS, Pilot, Mixer and CA. This step is specific to
each cloud provider, so you may need to edit annotations.

> The yaml file of the 0.2.7 distribution has an incorrect namespace for the DNS ILB.
Use
[this one](https://raw.githubusercontent.com/istio/istio/master/install/kubernetes/mesh-expansion.yaml)
instead.
The `setupMeshEx.sh` also has a typo. Use the latest file from the link above or from cloning [GitHub.com/istio/istio](https://github.com/istio/istio/)

```
kubectl apply -f install/kubernetes/mesh-expansion.yaml
```

* Generate the Istio 'cluster.env' configuration to be deployed in the VMs. This file contains
the cluster IP address ranges to intercept.

```bash
export GCP_OPTS="--zone MY_ZONE --project MY_PROJECT"
install/tools/setupMeshEx.sh generateClusterEnv MY_CLUSTER_NAME
```

Example generated file:

```bash
cat cluster.env
```
```
ISTIO_SERVICE_CIDR=10.63.240.0/20
```

* Generate DNS configuration file to be used in the VMs. This will allow apps on the VM to resolve
cluster service names, which will be intercepted by the sidecar and forwarded.

```bash
# Make sure your kubectl context is set to your cluster
install/tools/setupMeshEx.sh generateDnsmasq
```

Example generated file:

```bash
cat /etc/dnsmasq.d/kubedns
```
```
server=/svc.cluster.local/10.150.0.7
address=/istio-mixer/10.150.0.8
address=/istio-pilot/10.150.0.6
address=/istio-ca/10.150.0.9
address=/istio-mixer.istio-system/10.150.0.8
address=/istio-pilot.istio-system/10.150.0.6
address=/istio-ca.istio-system/10.150.0.9
```

### Setting up the machines

As an example, you can use the following script to copy and install the setup:
```bash
# Check what the script does to see that it meets your needs.
# On a Mac, either brew install base64 or set BASE64_DECODE="/usr/bin/base64 -D"
export GCP_OPTS="--zone MY_ZONE --project MY_PROJECT"
install/tools/setupMeshEx.sh machineSetup DESTINATION
```

Equivalent manual steps:

* Copy the configuration files and Istio Debian files to each machine joining the cluster.
Save the files as `/etc/dnsmasq.d/kubedns` and `/var/lib/istio/envoy/cluster.env`.

* Configure and verify DNS settings. This may require installing `dnsmasq` and either
adding it to `/etc/resolv.conf` directly or via DHCP scripts. To verify, check that the VM can resolve
names and connect to pilot, for example:

On the VM/external host:
```bash
dig istio-pilot.istio-system
```
```
# Verify you get the same address as shown as "EXTERNAL-IP" in 'kubectl get svc -n istio-system istio-pilot-ilb'
...
istio-pilot.istio-system. 0	IN	A	10.128.0.5
...
```
```bash
# Check that you can resolve cluster IPs. The actual IN A will depend on cluster configuration.
dig istio-pilot.istio-system.svc.cluster.local.
```
```
...
istio-pilot.istio-system.svc.cluster.local. 30 IN A 10.23.251.121
```
```bash
dig istio-ingress.istio-system.svc.cluster.local.
```
```
...
istio-ingress.istio-system.svc.cluster.local. 30 IN A 10.23.245.11
```

* Verify connectivity by checking whether the VM can connect to Pilot and to an endpoint.

```bash
curl -v 'http://istio-pilot.istio-system:8080/v1/registration/istio-pilot.istio-system.svc.cluster.local|http-discovery'
```
```
...
"ip_address": "10.20.1.18",
...
```
```bash
# On the VM, use the address above. It will directly connect to the pod running istio-pilot.
curl -v 'http://10.20.1.18:8080/v1/registration/istio-pilot.istio-system.svc.cluster.local|http-discovery'
```


* Extract the initial Istio authentication secrets and copy them to the machine. The default
installation of Istio includes Istio CA and will generate Istio secrets even if
the automatic 'mTLS'
setting is disabled (it creates secret for each service account, and the secret
is named as `istio.<serviceaccount>`). It is recommended that you perform this
step to make it easy to enable mTLS in the future and to upgrade to a future version
that will have mTLS enabled by default.

```bash
# ACCOUNT defaults to 'default', or SERVICE_ACCOUNT environment variable
# NAMESPACE defaults to current namespace, or SERVICE_NAMESPACE environment variable
# (this step is done by machineSetup)
# On a mac either brew install base64 or set BASE64_DECODE="/usr/bin/base64 -D"
install/tools/setupMeshEx.sh machineCerts ACCOUNT NAMESPACE
```

The generated files (`key.pem`, `root-cert.pem`, `cert-chain.pem`) must be copied to /etc/certs on each machine, readable by istio-proxy.

* Install Istio Debian files and start 'istio' and 'istio-auth-node-agent' services.
Get the debian packages from [github releases](https://github.com/istio/istio/releases) or:

  ```bash
      # Note: This will be replaced with an 'apt-get' command once the repositories are setup.

      source istio.VERSION # defines version and URLs env var
      curl -L ${PILOT_DEBIAN_URL}/istio-agent.deb > ${ISTIO_STAGING}/istio-agent.deb
      curl -L ${AUTH_DEBIAN_URL}/istio-auth-node-agent.deb > ${ISTIO_STAGING}/istio-auth-node-agent.deb
      curl -L ${PROXY_DEBIAN_URL}/istio-proxy.deb > ${ISTIO_STAGING}/istio-proxy.deb

      dpkg -i istio-proxy-envoy.deb
      dpkg -i istio-agent.deb
      dpkg -i istio-auth-node-agent.deb

      systemctl start istio
      systemctl start istio-auth-node-agent
  ```


After setup, the machine should be able to access services running in the Kubernetes cluster
or other mesh expansion machines.

```bash
   # Assuming you install bookinfo in 'bookinfo' namespace
   curl productpage.bookinfo.svc.cluster.local:9080
```
```
   ... html content ...
```

## Running services on a mesh expansion machine

* Configure the sidecar to intercept the port. This is configured in ``/var/lib/istio/envoy/sidecar.env`,
using the ISTIO_INBOUND_PORTS environment variable.

  Example (on the VM running the service):

   ```bash
   echo "ISTIO_INBOUND_PORTS=27017,3306,8080" > /var/lib/istio/envoy/sidecar.env
   systemctl restart istio
   ```

* Manually configure a selector-less service and endpoints. The 'selector-less' service is used for
services that are not backed by Kubernetes pods.

   Example, on a machine with permissions to modify Kubernetes services:
   ```bash
   # istioctl register servicename machine-ip portname:port
   istioctl -n onprem register mysql 1.2.3.4 3306
   istioctl -n onprem register svc1 1.2.3.4 http:7000
   ```

After the setup, Kubernetes pods and other mesh expansions should be able to access the
services running on the machine.

## Putting it all together

See the [BookInfo Mesh Expansion]({{home}}/docs/guides/integrating-vms.html) guide.

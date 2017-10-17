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
```
```bash
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
cat kubedns
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

As an example, you can use the following "all inclusive" script to copy
and install the setup:

```bash
# Check what the script does to see that it meets your needs.
# On a Mac, either brew install base64 or set BASE64_DECODE="/usr/bin/base64 -D"
export GCP_OPTS="--zone MY_ZONE --project MY_PROJECT"
```
```bash
install/tools/setupMeshEx.sh machineSetup VM_NAME
```

Or the equivalent manual steps:

------ Manual setup steps begin ------

* Copy the configuration files and Istio Debian files to each machine joining the cluster.
Save the files as `/etc/dnsmasq.d/kubedns` and `/var/lib/istio/envoy/cluster.env`.

* Configure and verify DNS settings. This may require installing `dnsmasq` and either
adding it to `/etc/resolv.conf` directly or via DHCP scripts. To verify, check that the VM can resolve
names and connect to pilot, for example:

On the VM/external host:
```bash
host istio-pilot.istio-system
```
Example generated message:
```
# Verify you get the same address as shown as "EXTERNAL-IP" in 'kubectl get svc -n istio-system istio-pilot-ilb'
istio-pilot.istio-system has address 10.150.0.6
```
```bash
# Check that you can resolve cluster IPs. The actual address will depend on your deployment.
host istio-pilot.istio-system.svc.cluster.local.
```
Example generated message:
```
istio-pilot.istio-system.svc.cluster.local has address 10.63.247.248
```
```bash
host istio-ingress.istio-system.svc.cluster.local.
```
Example generated message:
```
istio-ingress.istio-system.svc.cluster.local has address 10.63.243.30
```

* Verify connectivity by checking whether the VM can connect to Pilot and to an endpoint.

```bash
curl 'http://istio-pilot.istio-system:8080/v1/registration/istio-pilot.istio-system.svc.cluster.local|http-discovery'
```
```
{
  "hosts": [
   {
    "ip_address": "10.60.1.4",
    "port": 8080
   }
  ]
}
```
```bash
# On the VM, use the address above. It will directly connect to the pod running istio-pilot.
curl 'http://10.60.1.4:8080/v1/registration/istio-pilot.istio-system.svc.cluster.local|http-discovery'
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

------ Manual setup steps end ------

After setup, the machine should be able to access services running in the Kubernetes cluster
or other mesh expansion machines.

```bash
   # Assuming you install bookinfo in 'bookinfo' namespace
   curl productpage.bookinfo.svc.cluster.local:9080
```
```
   ... html content ...
```

Check that the processes are running:
```bash
ps aux |grep istio
```
```
root      6941  0.0  0.2  75392 16820 ?        Ssl  21:32   0:00 /usr/local/istio/bin/node_agent --logtostderr
root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=default exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.default~default.svc.cluster.local
```
Istio auth node agent is healthy:
```bash
sudo systemctl status istio-auth-node-agent
```
```
● istio-auth-node-agent.service - istio-auth-node-agent: The Istio auth node agent
   Loaded: loaded (/lib/systemd/system/istio-auth-node-agent.service; disabled; vendor preset: enabled)
   Active: active (running) since Fri 2017-10-13 21:32:29 UTC; 9s ago
     Docs: http://istio.io/
 Main PID: 6941 (node_agent)
    Tasks: 5
   Memory: 5.9M
      CPU: 92ms
   CGroup: /system.slice/istio-auth-node-agent.service
           └─6941 /usr/local/istio/bin/node_agent --logtostderr

Oct 13 21:32:29 demo-vm-1 systemd[1]: Started istio-auth-node-agent: The Istio auth node agent.
Oct 13 21:32:29 demo-vm-1 node_agent[6941]: I1013 21:32:29.469314    6941 main.go:66] Starting Node Agent
Oct 13 21:32:29 demo-vm-1 node_agent[6941]: I1013 21:32:29.469365    6941 nodeagent.go:96] Node Agent starts successfully.
Oct 13 21:32:29 demo-vm-1 node_agent[6941]: I1013 21:32:29.483324    6941 nodeagent.go:112] Sending CSR (retrial #0) ...
Oct 13 21:32:29 demo-vm-1 node_agent[6941]: I1013 21:32:29.862575    6941 nodeagent.go:128] CSR is approved successfully. Will renew cert in 29m59.137732603s
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

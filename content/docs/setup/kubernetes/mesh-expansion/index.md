---
title: Mesh Expansion
description: Instructions for integrating VMs and bare metal hosts into an Istio mesh deployed on Kubernetes.
weight: 50
keywords: [kubernetes,vms]
---

Instructions for integrating VMs and bare metal hosts into an Istio mesh
deployed on Kubernetes.

## Prerequisites

* Setup Istio on Kubernetes by following the instructions in the [Installation guide](/docs/setup/kubernetes/quick-start/).

* The machine must have IP connectivity to the endpoints in the mesh. This
typically requires a VPC or a VPN, as well as a container network that
provides direct (without NAT or firewall deny) routing to the endpoints. The machine
is not required to have access to the cluster IP addresses assigned by Kubernetes.

* The Istio control plane services (Pilot, Mixer, Citadel) and Kubernetes DNS server must be accessible
from the VMs. This is typically done using an [Internal Load
Balancer](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer).
You can also use NodePort, run Istio components on VMs, or use custom network configurations,
separate documents will cover these advanced configurations.

## Installation steps

Setup consists of preparing the mesh for expansion and installing and configuring each VM.

An example script to help with Kubernetes setup is available as part of the release bundle called
[`install/tools/setupMeshEx.sh`]({{< github_file >}}/install/tools/setupMeshEx.sh). Check the script content and environment variables supported (like GCP_OPTS).

An example script to help configure a machine is available as part of the release bundle called [`install/tools/setupIstioVM.sh`]({{< github_file >}}/install/tools/setupIstioVM.sh).
You should customize it based on your provisioning tools and DNS requirements.

### Preparing the Kubernetes cluster for expansion

*   Setup Internal Load Balancers (ILBs) for Kube DNS, Pilot, Mixer and Citadel. This step is specific to
each cloud provider, so you may need to edit annotations. You can use an ILB based on Keepalived at
[here](https://github.com/gyliu513/work/tree/master/k8s/charts/keepalived) for demo or test in case where
the cloud provider or private cloud (for example IBM Cloud Private) doesn't have load balancer service
support out of box.

    {{< text bash >}}
    $ kubectl apply -f @install/kubernetes/mesh-expansion.yaml@
    {{< /text >}}

*   Generate the Istio `cluster.env` configuration to be deployed in the VMs. This file contains
the cluster IP address ranges to intercept.

    {{< text bash >}}
    $ export GCP_OPTS="--zone MY_ZONE --project MY_PROJECT"
    $ @install/tools/setupMeshEx.sh@ generateClusterEnv MY_CLUSTER_NAME
    {{< /text >}}

    Here's an example generated file

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_SERVICE_CIDR=10.63.240.0/20
    {{< /text >}}

*   Generate DNS configuration file to be used in the VMs. This will allow apps on the VM to resolve
cluster service names, which will be intercepted by the sidecar and forwarded.

    {{< text bash >}}
    $ @install/tools/setupMeshEx.sh@ generateDnsmasq
    {{< /text >}}

    Here's an example generated file

    {{< text bash >}}
    $ cat kubedns
    server=/svc.cluster.local/10.150.0.7
    address=/istio-mixer/10.150.0.8
    address=/istio-pilot/10.150.0.6
    address=/istio-citadel/10.150.0.9
    address=/istio-mixer.istio-system/10.150.0.8
    address=/istio-pilot.istio-system/10.150.0.6
    address=/istio-citadel.istio-system/10.150.0.9
    {{< /text >}}

### Setting up the machines

As an example, you can use the following "all inclusive" script to copy
and install the setup:

{{< text bash >}}
$ export GCP_OPTS="--zone MY_ZONE --project MY_PROJECT"
$ export SERVICE_NAMESPACE=vm
{{< /text >}}

If you are running on a GCE VM, run

{{< text bash >}}
$ @install/tools/setupMeshEx.sh@ gceMachineSetup VM_NAME
{{< /text >}}

Otherwise, run

{{< text bash >}}
$ @install/tools/setupMeshEx.sh@ machineSetup VM_NAME
{{< /text >}}

GCE provides better user experience since node agent can always relies on
GCE metadata instance document to authenticate to Citadel. For everything
else, e.g., on-prem or raw VM, we have to bootstrap a key/cert as credential,
which typically has a limited lifetime. And when the cert expires, you have to
rerun the above command.

Or the equivalent manual steps:

------ Manual setup steps begin ------

* Copy the configuration files and Istio Debian files to each machine joining the cluster.
Save the files as `/etc/dnsmasq.d/kubedns` and `/var/lib/istio/envoy/cluster.env`.

*   Configure and verify DNS settings. This may require installing `dnsmasq` and either
adding it to `/etc/resolv.conf` directly or via DHCP scripts. To verify, check that the VM can resolve
names and connect to pilot, for example:

    On the VM/external host:

    {{< text bash >}}
    $ host istio-pilot.istio-system
    {{< /text >}}

    Example generated message:

    {{< text plain >}}
    $ istio-pilot.istio-system has address 10.150.0.6
    {{< /text >}}

    Check that you can resolve cluster IPs. The actual address will depend on your deployment.

    {{< text bash >}}
    $ host istio-pilot.istio-system.svc.cluster.local.
    {{< /text >}}

    Example generated message:

    {{< text plain >}}
    istio-pilot.istio-system.svc.cluster.local has address 10.63.247.248
    {{< /text >}}

    Check istio-ingress similarly:

    {{< text bash >}}
    $ host istio-ingress.istio-system.svc.cluster.local.
    {{< /text >}}

    Example generated message:

    {{< text plain >}}
    istio-ingress.istio-system.svc.cluster.local has address 10.63.243.30
    {{< /text >}}

*   Verify connectivity by checking whether the VM can connect to Pilot and to an endpoint.

    {{< text bash json >}}
    $ curl 'http://istio-pilot.istio-system:8080/v1/registration/istio-pilot.istio-system.svc.cluster.local|http-discovery'
    {
      "hosts": [
       {
        "ip_address": "10.60.1.4",
        "port": 8080
       }
      ]
    }
    {{< /text >}}

    On the VM, use the address above. It will directly connect to the pod running istio-pilot.

    {{< text bash >}}
    $ curl 'http://10.60.1.4:8080/v1/registration/istio-pilot.istio-system.svc.cluster.local|http-discovery'
    {{< /text >}}

*   Extract the initial Istio authentication secrets and copy them to the machine. The default
installation of Istio includes Citadel and will generate Istio secrets even if
the automatic 'mTLS'
setting is disabled (it creates secret for each service account, and the secret
is named as `istio.<serviceaccount>`). It is recommended that you perform this
step to make it easy to enable mTLS in the future and to upgrade to a future version
that will have mTLS enabled by default.

    `ACCOUNT` defaults to 'default', or `SERVICE_ACCOUNT` environment variable
    `NAMESPACE` defaults to current namespace, or `SERVICE_NAMESPACE` environment variable
    (this step is done by machineSetup)
    On a Mac either `brew install base64` or `set BASE64_DECODE="/usr/bin/base64 -D"`

    {{< text bash >}}
    $ @install/tools/setupMeshEx.sh@ machineCerts ACCOUNT NAMESPACE
    {{< /text >}}

    The generated files (`key.pem`, `root-cert.pem`, `cert-chain.pem`) must be copied to /etc/certs on each machine, readable by istio-proxy.

*   Install Istio Debian files and start 'istio' and 'istio-auth-node-agent' services.
Get the debian packages from [GitHub releases](https://github.com/istio/istio/releases) or:

    {{< text bash >}}
    $ source istio.VERSION # defines version and URLs env var
    $ curl -L ${PILOT_DEBIAN_URL}/istio-sidecar.deb > istio-sidecar.deb
    $ dpkg -i istio-sidecar.deb
    $ systemctl start istio
    $ systemctl start istio-auth-node-agent
    {{< /text >}}

------ Manual setup steps end ------

After setup, the machine should be able to access services running in the Kubernetes cluster
or other mesh expansion machines.

{{< text bash >}}
$ curl productpage.bookinfo.svc.cluster.local:9080
... html content ...
{{< /text >}}

Check that the processes are running:

{{< text bash >}}
$ ps aux |grep istio
root      6941  0.0  0.2  75392 16820 ?        Ssl  21:32   0:00 /usr/local/istio/bin/node_agent --logtostderr
root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=default exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.default~default.svc.cluster.local
{{< /text >}}

Istio auth node agent is healthy:

{{< text bash >}}
$ sudo systemctl status istio-auth-node-agent
● istio-auth-node-agent.service - istio-auth-node-agent: The Istio auth node agent
   Loaded: loaded (/lib/systemd/system/istio-auth-node-agent.service; disabled; vendor preset: enabled)
   Active: active (running) since Fri 2017-10-13 21:32:29 UTC; 9s ago
     Docs: https://istio.io/
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
{{< /text >}}

## Running services on a mesh expansion machine

*   Configure the sidecar to intercept the port. This is configured in `/var/lib/istio/envoy/sidecar.env`,
using the `ISTIO_INBOUND_PORTS` environment variable.

    Example (on the VM running the service):

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" > /var/lib/istio/envoy/sidecar.env
    $ systemctl restart istio
    {{< /text >}}

*   Manually configure a selector-less service and endpoints. The `selector-less` service is used for
services that are not backed by Kubernetes pods.

    Example, on a machine with permissions to modify Kubernetes services:

    {{< text bash >}}
    $ istioctl -n onprem register mysql 1.2.3.4 3306
    $ istioctl -n onprem register svc1 1.2.3.4 http:7000
    {{< /text >}}

After the setup, Kubernetes pods and other mesh expansions should be able to access the
services running on the machine.

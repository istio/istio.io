---
title: Virtual Machines in Multi-Network Meshes
description: Learn how to add a service running on a virtual machine to your multi-network
  Istio mesh.
weight: 30
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
aliases:
- /docs/examples/mesh-expansion/multi-network
- /docs/tasks/virtual-machines/multi-network
---

This example provides instructions to integrate a VM or a bare metal host into a
multi-network Istio mesh deployed on Kubernetes using gateways. This approach
doesn't require VPN connectivity or direct network access between the VM, the
bare metal and the clusters.

## Prerequisites

- One or more Kubernetes clusters with versions: {{< supported_kubernetes_versions >}}.

- Virtual machines (VMs) must have IP connectivity to the Ingress gateways in the mesh.

- Services in the cluster must be accessible through the Ingress gateway.

## Installation steps

### Preparing the Kubernetes cluster for VMs

The first step when adding non-Kubernetes services to an Istio mesh is to
configure the Istio installation itself, and generate the configuration files
that let VMs connect to the mesh. Prepare the cluster for the VM with the
following commands on a machine with cluster admin privileges:

1. Create a Kubernetes secret for your generated CA certificates using a command similar to the following. See [Certificate Authority (CA) certificates](/docs/tasks/security/plugin-ca-cert/) for more details.

1. Follow the same steps as [setting up single-network](/docs/examples/virtual-machines/single-network) configuration for the initial setup of the
   cluster and certificates with the change of how you deploy Istio control plane:

    {{< text bash >}}
    $ istioctl manifest apply \
       -f install/kubernetes/operator/examples/vm/values-istio-meshexpansion.yaml
    {{< /text >}}

### Setting up the VM

Next, run the following commands on each machine that you want to add to the mesh:

1.  Copy the previously created `cluster.env` and `*.pem` files to the VM. For example:

    {{< text bash >}}
    $ export GCE_NAME="your-gce-instance"
    $ gcloud compute scp --project=${MY_PROJECT} --zone=${MY_ZONE} {key.pem,cert-chain.pem,cluster.env,root-cert.pem} ${GCE_NAME}:~
    {{< /text >}}

1.  Install the Debian package with the Envoy sidecar.

    {{< text bash >}}
    $ gcloud compute ssh --project=${MY_PROJECT} --zone=${MY_ZONE} "${GCE_NAME}"
    $ curl -L https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb > istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1.  Add the IP address of Istio gateway to `/etc/hosts`. Revisit the [preparing the cluster](#preparing-the-kubernetes-cluster-for-vms) section to learn how to obtain the IP address.
The following example updates the `/etc/hosts` file with the Istiod address:

    {{< text bash >}}
    $ echo "${GWIP} istiod.istio-system.svc" | sudo tee -a /etc/hosts
    {{< /text >}}

   A better options is to configure the DNS resolver of the VM to resolve the address, using a split-DNS server. Using
   /etc/hosts is an easy to use example. It is also possible to use a real DNS and certificate for Istiod, this is beyond
   the scope of this document.

1.  Install `root-cert.pem`, `key.pem` and `cert-chain.pem` under `/etc/certs/`.

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1.  Install `root-cert.pem` under `/var/run/secrets/istio/`.

1.  Install `cluster.env` under `/var/lib/istio/envoy/`.

    {{< text bash >}}
    $ sudo cp cluster.env /var/lib/istio/envoy
    {{< /text >}}

1.  Transfer ownership of the files in `/etc/certs/` , `/var/lib/istio/envoy/` and `/var/run/secrets/istio/`to the Istio proxy.

    {{< text bash >}}
    $ sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy /var/run/secrets/istio/
    {{< /text >}}

1.  Start Istio using `systemctl`.

    {{< text bash >}}
    $ sudo systemctl start istio
    {{< /text >}}

## Send requests from VM workloads to Kubernetes services

After setup, the machine can access services running in the Kubernetes cluster
or on other VMs.

The following example shows accessing a service running in the Kubernetes cluster from a VM using
`/etc/hosts/`, in this case using a service from the [Bookinfo example](/docs/examples/bookinfo/).

1.  Connect to the cluster service from VM as in the example below:

    {{< text bash >}}
$ curl -v ${GWIP}/productpage
< HTTP/1.1 200 OK
< content-type: text/html; charset=utf-8
< content-length: 1836
< server: istio-envoy
... html content ...
    {{< /text >}}

The `server: istio-envoy` header indicates that the sidecar intercepted the traffic.

## Running services on the added VM

1. Setup an HTTP server on the VM instance to serve HTTP traffic on port 8080:

    {{< text bash >}}
    $ gcloud compute ssh ${GCE_NAME}
    $ python -m SimpleHTTPServer 8080
    {{< /text >}}

1. Determine the VM instance's IP address. For example, find the IP address
    of the GCE instance with the following commands:

    {{< text bash >}}
    $ export GCE_IP=$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances describe ${GCE_NAME})
    $ echo ${GCE_IP}
    {{< /text >}}

1. Add VM services to the mesh

    {{< text bash >}}
    $ istioctl experimental add-to-mesh external-service vmhttp ${VM_IP} http:8080 -n ${SERVICE_NAMESPACE}
    {{< /text >}}

    {{< tip >}}
    Ensure you have added the `istioctl` client to your path, as described in the [download page](/docs/setup/getting-started/#download).
    {{< /tip >}}

1. Deploy a pod running the `sleep` service in the Kubernetes cluster, and wait until it is ready:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl get pod
    NAME                             READY     STATUS    RESTARTS   AGE
    sleep-88ddbcfdd-rm42k            2/2       Running   0          1s
    ...
    {{< /text >}}

1. Send a request from the `sleep` service on the pod to the VM's HTTP service:

    {{< text bash >}}
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl vmhttp.${SERVICE_NAMESPACE}.svc.cluster.local:8080
    {{< /text >}}

    You should see something similar to the output below.

    {{< text html >}}
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"><html>
    <title>Directory listing for /</title>
    <body>
    <h2>Directory listing for /</h2>
    <hr>
    <ul>
    <li><a href=".bashrc">.bashrc</a></li>
    <li><a href=".ssh/">.ssh/</a></li>
    ...
    </body>
    {{< /text >}}

**Congratulations!** You successfully configured a service running in a pod within the cluster to
send traffic to a service running on a VM outside of the cluster and tested that
the configuration worked.

## Cleanup

Run the following commands to remove the expansion VM from the mesh's abstract
model.

{{< text bash >}}
$ istioctl experimental remove-from-mesh -n ${SERVICE_NAMESPACE} vmhttp
Kubernetes Service "vmhttp.vm" has been deleted for external service "vmhttp"
Service Entry "mesh-expansion-vmhttp" has been deleted for external service "vmhttp"
{{< /text >}}


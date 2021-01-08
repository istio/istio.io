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
owner: istio/wg-environments-maintainers
test: no
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

Setup consists of preparing the mesh for expansion and installing and configuring each VM.

### Preparing your environment

When expanding Istio's mesh capabilities to VMs across multiple networks (where the VM is in a network where traffic cannot directly route to pods in the Kubernetes cluster, for example), we'll need to take advantage of Istio's split-horizon DNS capabilities.

Before we get started, you should prepare a VM and connect it to the Istio control plane through the Ingress Gateway. These steps are detailed in [Setup: Install: Virtual Machine Installation](/docs/setup/install/virtual-machine/).

**Note** There are a few alterations to that document as follows:

{{< warning >}}
You must alter the VM set up instructions based on the suggestions in this section!
{{< /warning >}}

1. When we create the `IstioOperator` resource, we need to specify the network for the cluster.
1. When creating the `WorkloadEntry` template as part of the `WorkloadGroup`, we need to set the `network` field.
1. We need to specify the `clusterName` and `networkName` when creating the East-West Gateway.

### Installing the Istio Control Plane

When following the [Virtual Machine Installation](/docs/setup/install/virtual-machine/#install-the-istio-control-plane) setup guide to install the control plane, we will need to tweak the installation as follows:

1. Specify the cluster's network in the `IstioOperator` spec.

    {{< text bash yaml >}}
    $ cat <<EOF > ./vmintegration.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      values:
        global:
          multiCluster:
            clusterName: kube-cluster
          network: main-network
    EOF
    {{< /text >}}

1. Install the control plane with the network configured.

    {{< text bash >}}
    $ istioctl install -f ./vmintegration.yaml
    {{< /text >}}

1. Specify the cluster name and network when installing the East-West gateway.

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --mesh mesh1 --cluster kube-cluster --network main-network | \
        istioctl install -y -f -
    {{< /text >}}

### Specify the network for the VM sidecar

Specify the network before following the [Virtual Machine Installation](/docs/setup/install/virtual-machine/#create-files-to-transfer-to-the-virtual-machine) setup guide for creating files to transfer to the virtual machine:

    {{< text bash >}}
    $ NETWORK=vm-network
    {{< /text >}}

### Create Gateway for application traffic

The last step is to create a `Gateway` resource that routes application traffic from the VMs to services running in the cluster.

    {{< text bash >}}
    $ kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
        @samples/multicluster/expose-services.yaml@
    {{< /text >}}

Applying this gateway will route any of the traffic from the VM destined for the workloads in the mesh running on `*.local` via the
East-West gateway.

At this point, you can continue with the [Setup Virtual Machine documentation](/docs/setup/install/virtual-machine/).

## Verify setup

After setup, the machine can access services running in the Kubernetes cluster
or on other VMs. When a service on the VM tries to access a service in the mesh running on Kubernetes, the endpoints (i.e., IPs) for those services will be the ingress gateway on the Kubernetes Cluster. To verify that, on the VM run the following command (assuming you have a service named `httpbin` on the Kubernetes cluster):

    {{< text bash >}}
    $ curl -v localhost:15000/clusters | grep httpbin
    {{< /text >}}

This should show endpoints for `httpbin` that point to the ingress gateway similar to this:

    {{< text text >}}
    outbound|8000||httpbin.default.svc.cluster.local::34.72.46.113:443::cx_active::1
    outbound|8000||httpbin.default.svc.cluster.local::34.72.46.113:443::cx_connect_fail::0
    outbound|8000||httpbin.default.svc.cluster.local::34.72.46.113:443::cx_total::1
    outbound|8000||httpbin.default.svc.cluster.local::34.72.46.113:443::rq_active::0
    {{< /text >}}

The IP `34.72.46.113` in this case is the ingress gateway public endpoint.

### Send requests from VM workloads to Kubernetes services

At this point we should be able to send traffic to `httpbin.default.svc.cluster.local` and get a response from the server. You may have to set up DNS in `/etc/hosts` to map the `httpbin.default.svc.cluster.local` domain name to an IP since the IP will not resolve. In this case, the IP should be an IP that gets routed to the local Istio Proxy sidecar. You can use the IP from the `ISTIO_SERVICE_CIDR` variable in the `cluster.env` file you created in the [Setup Virtual Machine documentation](/docs/setup/install/virtual-machine/).

    {{< text bash >}}
    $ curl -v httpbin.default.svc.cluster.local:8000/headers
    {{< /text >}}

### Running services on the added VM

1. Setup an HTTP server on the VM instance to serve HTTP traffic on port 8080:

    {{< text bash >}}
    $ python -m SimpleHTTPServer 8080
    {{< /text >}}

    {{< idea >}}
    Note, you may have to open firewalls to be able to access the 8080 port on your VM
    {{< /idea >}}

1. Add VM services to the mesh

    Add a service to the Kubernetes cluster into a namespace (in this example, `<vm-namespace>`) where you prefer to keep resources (like `Service`, `ServiceEntry`, `WorkloadEntry`, `ServiceAccount`) with the VM services:

    {{< text bash >}}
    $ cat <<EOF | kubectl -n <vm-namespace> apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: cloud-vm
      labels:
        app: cloud-vm
    spec:
      ports:
      - port: 8080
        name: http-vm
        targetPort: 8080
      selector:
        app: cloud-vm
    EOF
    {{< /text >}}

    Lastly create a workload with the external IP of the VM (substitute `VM_IP` with the IP of your VM):

    {{< tip >}}
    You can skip this step if using Automated WorkloadEntry Creation.
    {{< /tip >}}

    {{< text bash >}}
    $ cat <<EOF | kubectl -n <vm-namespace> apply -f -
    apiVersion: networking.istio.io/v1beta1
    kind: WorkloadEntry
    metadata:
      name: "cloud-vm"
      namespace: "<vm-namespace>"
    spec:
      address: "${VM_IP}"
      labels:
        app: cloud-vm
      serviceAccount: "<service-account>"
    EOF
    {{< /text >}}

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
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl cloud-vm.${VM_NAMESPACE}.svc.cluster.local:8080
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

At this point, you can remove the VM resources from the Kubernetes cluster in the `<vm-namespace>` namespace.

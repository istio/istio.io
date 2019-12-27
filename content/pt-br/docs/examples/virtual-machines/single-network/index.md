---
title: Virtual Machines in Single-Network Meshes
description: Learn how to add a service running on a virtual machine
  to your single network Istio mesh.
weight: 20
keywords:
- kubernetes
- vms
- virtual-machines
aliases:
- /docs/setup/kubernetes/additional-setup/mesh-expansion/
- /docs/examples/mesh-expansion/single-network
- /docs/tasks/virtual-machines/single-network
---

This example shows how to integrate a VM or a bare metal host into a single-network
Istio mesh deployed on Kubernetes.

## Prerequisites

- You have already set up Istio on Kubernetes. If you haven't done so, you can
  find out how in the [Installation guide](/pt-br/docs/setup/getting-started/).

- Virtual machines (VMs) must have IP connectivity to the endpoints in the mesh.
  This typically requires a VPC or a VPN, as well as a container network that
  provides direct (without NAT or firewall deny) routing to the endpoints. The
  machine is not required to have access to the cluster IP addresses assigned by
  Kubernetes.

- VMs must have access to a DNS server that resolves names to cluster IP
  addresses. Options include exposing the Kubernetes DNS server through an
  internal load balancer, using a [Core DNS](https://coredns.io/) server, or
  configuring the IPs in any other DNS server accessible from the VM.

The following instructions:

- Assume the expansion VM is running on GCE.
- Use Google platform-specific commands for some steps.

## Installation steps

Setup consists of preparing the mesh for expansion and installing and configuring each VM.

### Preparing the Kubernetes cluster for VMs

The first step when adding non-Kubernetes services to an Istio mesh is to
configure the Istio installation itself, and generate the configuration files
that let VMs connect to the mesh. Prepare the cluster for the VM with the
following commands on a machine with cluster admin privileges:

1. Create a Kubernetes secret for your generated CA certificates using a command similar to the following. See [Certificate Authority (CA) certificates](/pt-br/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key) for more details.

    {{< warning >}}
    The root and intermediate certificate from the samples directory are widely
    distributed and known.  Do **not** use these certificates in production as
    your clusters would then be open to security vulnerabilities and compromise.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file=@samples/certs/ca-cert.pem@ \
        --from-file=@samples/certs/ca-key.pem@ \
        --from-file=@samples/certs/root-cert.pem@ \
        --from-file=@samples/certs/cert-chain.pem@
    {{< /text >}}

1. Deploy Istio control plane into the cluster

        {{< text bash >}}
        $ istioctl manifest apply \
            -f install/kubernetes/operator/examples/vm/values-istio-meshexpansion.yaml
        {{< /text >}}

    For further details and customization options, refer to the
    [installation instructions](/pt-br/docs/setup/install/istioctl/).

1. Define the namespace the VM joins. This example uses the `SERVICE_NAMESPACE`
   environment variable to store the namespace. The value of this variable must
   match the namespace you use in the configuration files later on.

    {{< text bash >}}
    $ export SERVICE_NAMESPACE="default"
    {{< /text >}}

1. Determine and store the IP address of the Istio ingress gateway since the VMs
   access [Citadel](/pt-br/docs/concepts/security/) and
   [Pilot](/pt-br/docs/ops/deployment/architecture/#pilot) through this IP address.

    {{< text bash >}}
    $ export GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GWIP
    35.232.112.158
    {{< /text >}}

1. Generate a `cluster.env` configuration to deploy in the VMs. This file contains the Kubernetes cluster IP address ranges
    to intercept and redirect via Envoy. You specify the CIDR range when you install Kubernetes as `servicesIpv4Cidr`.
    Replace `$MY_ZONE` and `$MY_PROJECT` in the following example commands with the appropriate values to obtain the CIDR
    after installation:

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $K8S_CLUSTER --zone $MY_ZONE --project $MY_PROJECT --format "value(servicesIpv4Cidr)")
    $ echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
    {{< /text >}}

1. Check the contents of the generated `cluster.env` file. It should be similar to the following example:

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_CP_AUTH=MUTUAL_TLS
    ISTIO_SERVICE_CIDR=10.55.240.0/20
    {{< /text >}}

1. If the VM only calls services in the mesh, you can skip this step. Otherwise, add the ports the VM exposes
    to the `cluster.env` file with the following command. You can change the ports later if necessary.

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> cluster.env
    {{< /text >}}

1. Extract the initial keys the service account needs to use on the VMs.

    {{< text bash >}}
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.root-cert\.pem}' |base64 --decode > root-cert.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.key\.pem}' |base64 --decode > key.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
          -o jsonpath='{.data.cert-chain\.pem}' |base64 --decode > cert-chain.pem
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

1.  Add the IP address of the Istio gateway to `/etc/hosts`. Revisit the [preparing the cluster](#preparing-the-kubernetes-cluster-for-vms) section to learn how to obtain the IP address.
The following example updates the `/etc/hosts` file with the Istio gateway address:

    {{< text bash >}}
    $ echo "35.232.112.158 istio-citadel istio-pilot istio-pilot.istio-system" | sudo tee -a /etc/hosts
    {{< /text >}}

1.  Install `root-cert.pem`, `key.pem` and `cert-chain.pem` under `/etc/certs/`.

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1.  Install `cluster.env` under `/var/lib/istio/envoy/`.

    {{< text bash >}}
    $ sudo cp cluster.env /var/lib/istio/envoy
    {{< /text >}}

1.  Transfer ownership of the files in `/etc/certs/` and `/var/lib/istio/envoy/` to the Istio proxy.

    {{< text bash >}}
    $ sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy
    {{< /text >}}

1.  Verify the node agent works:

    {{< text bash >}}
    $ sudo node_agent
    ....
    CSR is approved successfully. Will renew cert in 1079h59m59.84568493s
    {{< /text >}}

1.  Start Istio using `systemctl`.

    {{< text bash >}}
    $ sudo systemctl start istio-auth-node-agent
    $ sudo systemctl start istio
    {{< /text >}}

## Send requests from VM workloads to Kubernetes services

After setup, the machine can access services running in the Kubernetes cluster
or on other VMs.

The following example shows accessing a service running in the Kubernetes cluster from a VM using
`/etc/hosts/`, in this case using a service from the [Bookinfo example](/pt-br/docs/examples/bookinfo/).

1.  First, on the cluster admin machine get the virtual IP address (`clusterIP`) for the service:

    {{< text bash >}}
    $ kubectl get svc productpage -o jsonpath='{.spec.clusterIP}'
    10.55.246.247
    {{< /text >}}

1.  Then on the added VM, add the service name and address to its `etc/hosts`
    file. You can then connect to the cluster service from the VM, as in the
    example below:

    {{< text bash >}}
$ echo "10.55.246.247 productpage.default.svc.cluster.local" | sudo tee -a /etc/hosts
$ curl -v productpage.default.svc.cluster.local:9080
< HTTP/1.1 200 OK
< content-type: text/html; charset=utf-8
< content-length: 1836
< server: envoy
... html content ...
    {{< /text >}}

The `server: envoy` header indicates that the sidecar intercepted the traffic.

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
    Ensure you have added the `istioctl` client to your path, as described in the [download page](/pt-br/docs/setup/getting-started/#download).
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

## Troubleshooting

The following are some basic troubleshooting steps for common VM-related issues.

-    When making requests from a VM to the cluster, ensure you don't run the requests as `root` or
    `istio-proxy` user. By default, Istio excludes both users from interception.

-    Verify the machine can reach the IP of the all workloads running in the cluster. For example:

    {{< text bash >}}
    $ kubectl get endpoints productpage -o jsonpath='{.subsets[0].addresses[0].ip}'
    10.52.39.13
    {{< /text >}}

    {{< text bash >}}
    $ curl 10.52.39.13:9080
    html output
    {{< /text >}}

-    Check the status of the node agent and sidecar:

    {{< text bash >}}
    $ sudo systemctl status istio-auth-node-agent
    $ sudo systemctl status istio
    {{< /text >}}

-    Check that the processes are running. The following is an example of the processes you should see on the VM if you run
     `ps`, filtered for `istio`:

    {{< text bash >}}
    $ ps aux | grep istio
    root      6941  0.0  0.2  75392 16820 ?        Ssl  21:32   0:00 /usr/local/istio/bin/node_agent --logtostderr
    root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=default exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
    istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
    istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.default~default.svc.cluster.local
    {{< /text >}}

-    Check the Envoy access and error logs:

    {{< text bash >}}
    $ tail /var/log/istio/istio.log
    $ tail /var/log/istio/istio.err.log
    {{< /text >}}

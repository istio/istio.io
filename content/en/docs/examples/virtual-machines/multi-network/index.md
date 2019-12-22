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

## Installation steps

Setup consists of preparing the mesh for expansion and installing and configuring each VM.

### Customized installation of Istio on the cluster

The first step when adding non-Kubernetes services to an Istio mesh is to
configure the Istio installation itself, and generate the configuration files
that let VMs connect to the mesh. Prepare the cluster for the VM with the
following commands on a machine with cluster admin privileges:

1. Create a Kubernetes secret for your generated CA certificates using a command similar to the following. See [Certificate Authority (CA) certificates](/docs/tasks/security/citadel-config/plugin-ca-cert/#plugging-in-the-existing-certificate-and-key) for more details.

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
            -f install/kubernetes/operator/examples/vm/values-istio-meshexpansion-gateways.yaml \
            --set coreDNS.enabled=true
        {{< /text >}}

    For further details and customization options, refer to the
    [installation instructions](/docs/setup/install/istioctl/).

1. Create `vm` namespace for the VM services.

    {{< text bash >}}
    $ kubectl create ns vm
    {{< /text >}}

1. Define the namespace the VM joins. This example uses the `SERVICE_NAMESPACE` environment variable to store the namespace. The value of this variable must match the namespace you use in the configuration files later on.

    {{< text bash >}}
    $ export SERVICE_NAMESPACE="vm"
    {{< /text >}}

1. Extract the initial keys the service account needs to use on the VMs.

    {{< text bash >}}
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.root-cert\.pem}' | base64 --decode > root-cert.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.key\.pem}' | base64 --decode > key.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
          -o jsonpath='{.data.cert-chain\.pem}' | base64 --decode > cert-chain.pem
    {{< /text >}}

1. Determine and store the IP address of the Istio ingress gateway since the
   VMs access [Citadel](/docs/concepts/security/) and
   [Pilot](/docs/ops/deployment/architecture/#pilot) and workloads on cluster through
   this IP address.

    {{< text bash >}}
    $ export GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GWIP
    35.232.112.158
    {{< /text >}}

1. Generate a `cluster.env` configuration to deploy in the VMs. This file contains the Kubernetes cluster IP address ranges
    to intercept and redirect via Envoy.

    {{< text bash >}}
    $ echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
    {{< /text >}}

1. Check the contents of the generated `cluster.env` file. It should be similar to the following example:

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_CP_AUTH=MUTUAL_TLS
    ISTIO_SERVICE_CIDR=172.21.0.0/16
    {{< /text >}}

1. If the VM only calls services in the mesh, you can skip this step. Otherwise, add the ports the VM exposes
    to the `cluster.env` file with the following command. You can change the ports later if necessary.

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=8888" >> cluster.env
    {{< /text >}}

### Setup DNS

Reference [Setup DNS](/docs/setup/install/multicluster/gateways/#setup-dns) to set up DNS for the cluster.

### Setting up the VM

Next, run the following commands on each machine that you want to add to the mesh:

1.  Copy the previously created `cluster.env` and `*.pem` files to the VM.

1.  Install the Debian package with the Envoy sidecar.

    {{< text bash >}}
    $ curl -L https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb > istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1.  Add the IP address of the Istio gateway to `/etc/hosts`. Revisit the [Customized installation of Istio on the Cluster](#customized-installation-of-istio-on-the-cluster) section to learn how to obtain the IP address.
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

1.  Start Istio using `systemctl`.

    {{< text bash >}}
    $ sudo systemctl start istio-auth-node-agent
    $ sudo systemctl start istio
    {{< /text >}}

## Added Istio resources

The Istio resources below are added to support adding VMs to the mesh with
gateways. These resources remove the flat network requirement between the VM and
cluster.

| Resource Kind| Resource Name | Function |
| ----------------------------       |---------------------------       | -----------------                          |
| `configmap`                           | `coredns`                            | Send *.global request to `istiocordns` service |
| `service`                             | `istiocoredns`                       | Resolve *.global to Istio Ingress gateway    |
| `gateway.networking.istio.io`         | `meshexpansion-gateway`              | Open port for Pilot, Citadel and Mixer       |
| `gateway.networking.istio.io`         | `istio-multicluster-ingressgateway`  | Open port 15443 for inbound *.global traffic |
| `envoyfilter.networking.istio.io`     | `istio-multicluster-ingressgateway`  | Transform `*.global` to `*. svc.cluster.local`   |
| `destinationrule.networking.istio.io` | `istio-multicluster-destinationrule` | Set traffic policy for 15443 traffic         |
| `destinationrule.networking.istio.io` | `meshexpansion-dr-pilot`             | Set traffic policy for `istio-pilot`         |
| `destinationrule.networking.istio.io` | `istio-policy`                       | Set traffic policy for `istio-policy`        |
| `destinationrule.networking.istio.io` | `istio-telemetry`                    | Set traffic policy for `istio-telemetry`     |
| `virtualservice.networking.istio.io`  | `meshexpansion-vs-pilot`             | Set route info for `istio-pilot`             |
| `virtualservice.networking.istio.io`  | `meshexpansion-vs-citadel`           | Set route info for `istio-citadel`           |

## Expose service running on cluster to VMs

Every service in the cluster that needs to be accessed from the VM requires a service entry configuration in the cluster. The host used in the service entry should be of the form `<name>.<namespace>.global` where name and namespace correspond to the service’s name and namespace respectively.

To demonstrate access from VM to  cluster services, configure the
the [httpbin service]({{< github_tree >}}/samples/httpbin)
in the cluster.

1. Deploy the `httpbin` service in the cluster

    {{< text bash >}}
    $ kubectl create namespace bar
    $ kubectl label namespace bar istio-injection=enabled
    $ kubectl apply -n bar -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Create a service entry for the `httpbin` service in the cluster.

    To allow services in VM  to access `httpbin` in the cluster, we need to create
    a service entry for it. The host name of the service entry should be of the form
    `<name>.<namespace>.global` where name and namespace correspond to the
    remote service's name and namespace respectively.

    For DNS resolution for services under the `*.global` domain, you need to assign these
    services an IP address.

    {{< tip >}}
    Each service (in the `.global` DNS domain) must have a unique IP within the cluster.
    {{< /tip >}}

    If the global services have actual VIPs, you can use those, but otherwise we suggest
    using IPs from the loopback range `127.0.0.0/8` that are not already allocated.
    These IPs are non-routable outside of a pod.
    In this example we'll use IPs in `127.255.0.0/16` which avoids conflicting with
    well known IPs such as `127.0.0.1` (`localhost`).
    Application traffic for these IPs will be captured by the sidecar and routed to the
    appropriate remote service.

    {{< text bash >}}
    $ kubectl apply  -n bar -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin.bar.forvms
    spec:
      hosts:
      # must be of form name.namespace.global
      - httpbin.bar.global
      location: MESH_INTERNAL
      ports:
      - name: http1
        number: 8000
        protocol: http
      resolution: DNS
      addresses:
      # the IP address to which httpbin.bar.global will resolve to
      # must be unique for each service, within a given cluster.
      # This address need not be routable. Traffic for this IP will be captured
      # by the sidecar and routed appropriately.
      # This address will also be added into VM's /etc/hosts
      - 127.255.0.3
      endpoints:
      # This is the routable address of the ingress gateway in the cluster.
      # Traffic from the VMs will be
      # routed to this address.
      - address: ${CLUSTER_GW_ADDR}
        ports:
          http1: 15443 # Do not change this port value
    EOF
    {{< /text >}}

    The configurations above will result in all traffic from VMs for
    `httpbin.bar.global` on *any port* to be routed to the endpoint
    `<IPofClusterIngressGateway>:15443` over a mutual TLS connection.

    The gateway for port 15443 is a special SNI-aware Envoy
    preconfigured and installed as part of the meshexpansion with gateway Istio installation step
    in the [Customized installation of Istio on the Cluster](#customized-installation-of-istio-on-the-cluster) section. Traffic entering port 15443 will be
    load balanced among pods of the appropriate internal service of the target
    cluster (in this case, `httpbin.bar` in the cluster).

    {{< warning >}}
    Do not create a `Gateway` configuration for port 15443.
    {{< /warning >}}

## Send requests from VM to Kubernetes services

After setup, the machine can access services running in the Kubernetes cluster.

The following example shows accessing a service running in the Kubernetes
cluster from a VM using `/etc/hosts/`, in this case using a
service from the [httpbin service]({{<github_tree>}}/samples/httpbin).

1.  On the added VM, add the service name and address to its `/etc/hosts` file.
    You can then connect to the cluster service from the VM, as in the example
    below:

    {{< text bash >}}
$ echo "127.255.0.3 httpbin.bar.global" | sudo tee -a /etc/hosts
$ curl -v httpbin.bar.global:8000
< HTTP/1.1 200 OK
< server: envoy
< content-type: text/html; charset=utf-8
< content-length: 9593

... html content ...
    {{< /text >}}

The `server: envoy` header indicates that the sidecar intercepted the traffic.

## Running services on the added VM

1. Setup an HTTP server on the VM instance to serve HTTP traffic on port 8888:

    {{< text bash >}}
    $ python -m SimpleHTTPServer 8888
    {{< /text >}}

1. Determine the VM instance's IP address.

1. Add VM services to the mesh

    {{< text bash >}}
    $ istioctl experimental add-to-mesh external-service vmhttp ${VM_IP} http:8888 -n ${SERVICE_NAMESPACE}
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
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl vmhttp.${SERVICE_NAMESPACE}.svc.cluster.local:8888
    {{< /text >}}

    If configured properly, you will see something similar to the output below.

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


---
title: Mesh Expansion with gateways (multi-network)
description: Integrate VMs and bare metal hosts into an Istio mesh deployed on Kubernetes with gateways.
weight: 95
keywords: [kubernetes,vms,gateways]
aliases:
    - /docs/setup/kubernetes/mesh-expansion-with-gateways/
---

This guide provides instructions to integrate VMs and bare metal hosts into
an Istio mesh deployed on Kubernetes with gateways. No VPN connectivity nor direct network access between workloads in 
VMs, bare metals and clusters is required.

## Prerequisites

* One or more Kubernetes clusters with versions: 1.12, 1.13, 1.14

* Mesh expansion machines must have IP connectivity to the Ingress gateways in the mesh. 

* Install the [Helm client](https://docs.helm.sh/using_helm/). Helm is needed to enable mesh expansion.


## Installation steps

Setup consists of preparing the mesh for expansion and installing and configuring each VM.

### Customized installation of Istio on the Cluster

The first step when adding non-Kubernetes services to an Istio mesh is to configure the Istio installation itself, and
generate the configuration files that let mesh expansion VMs connect to the mesh. To prepare the
cluster for mesh expansion, run the following commands on a machine with cluster admin privileges:

1. Generate a meshexpansion-gateways Istio configuration file using `helm`:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
        -f @install/kubernetes/helm/istio/example-values/values-istio-meshexpansion-gateways.yaml@ \ > $HOME/istio.meshexpansion-gateways.yaml
    {{< /text >}}

    For further details and customization options, refer to the
    [Installation with Helm](/docs/setup/kubernetes/install/helm/) instructions.

1. Deploy Istio control plane into the cluster

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ helm template  install/kubernetes/helm/istio-init --name istio-init --namespace istio-system  | kubectl apply -f -
    $ kubectl apply -f istio.meshexpansion-gateways.yaml
    {{< /text >}}

1. Verify Istio is installed successfully

    
    {{< text bash >}}
    $ istioctl verify-install -f istio.gateway.expansion.yaml
    {{< /text >}}


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
        -o jsonpath='{.data.root-cert\.pem}' |base64 --decode > root-cert.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.key\.pem}' |base64 --decode > key.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
          -o jsonpath='{.data.cert-chain\.pem}' |base64 --decode > cert-chain.pem
    {{< /text >}}

1. Determine and store the IP address of the Istio ingress gateway since the mesh expansion machines access [Citadel](/docs/concepts/security/),[Pilot](/docs/concepts/traffic-management/#pilot) and workloads on cluster through this IP address.

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

### Setup DNS

Providing DNS resolution to allow services running on VM can access the
services runnning in the cluster. Istio itself does not use the DNS for 
routing requests between services. Services local to a cluster share a 
common DNS suffix(e.g., `svc.cluster.local`). Kubernetes DNS provides
DNS resolution for these services.

To provide a similar setup to allow services accessible from Vms, you name
services in the clusters in the format
`<name>.<namespace>.global`. Istio also ships with a CoreDNS server that
will provide DNS resolution for these services. In order to utilize this
DNS, Kubernetes' DNS must be configured to `stub a domain` for `.global`.

{{< warning >}}
Some cloud providers have different specific `DNS domain stub` capabilities
and procedures for their Kubernetes services.  Reference the cloud provider's
documentation to determine how to `stub DNS domains` for each unique
environment.  The objective of this bash is to stub a domain for `.global` on
port `53` to reference or proxy the `istiocoredns` service in Istio's service
namespace.
{{< /warning >}}

Create one of the following ConfigMaps, or update an existing one, in each
cluster that will be calling services in remote clusters
(every cluster in the general case):

For clusters that use `kube-dns`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"global": ["$(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})"]}
EOF
{{< /text >}}

For clusters that use CoreDNS:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
    global:53 {
        errors
        cache 30
        proxy . $(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})
    }
EOF
{{< /text >}}


### Setting up the VM

Next, run the following commands on each machine that you want to add to the mesh:

1.  Copy the previously created `cluster.env` and `*.pem` files to the VM. 


1.  Install the Debian package with the Envoy sidecar.

    {{< text bash >}}
    $ curl -L https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb > istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1.  Add the IP address of the Istio gateway to `/etc/hosts`. Revisit the [ustomized installation of Istio on the Cluster](#Customized-installation-of-Istio-on-the-Cluster) section to learn how to obtain the IP address.
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

## Added Istio resources

Below Istio resources are added to support Mesh Expansion with gateways. This released the flat network requirement between the VM and  cluster.


| Resource Kind| Resource Name | Function |
| ----------------------------       |---------------------------       | -----------------                          |
| configmap                          | coredns                          | Send *.global request to istiocordns service |
| service                            | istiocoredns                     | Resolve *.global to Istio Ingress gateway    |
| gateway.networking.istio.io        | meshexpansion-gateway            | Open port for Pilot, Citadel and Mixer       |
| gateway.networking.istio.io        | istio-multicluster-egressgateway | Open port 15443 for outbound *.global traffic|
| gateway.networking.istio.io        | istio-multicluster-ingressgateway| Open port 15443 for inbound *.global traffic |
| envoyfilter.networking.istio.io    | istio-multicluster-ingressgateway| Transform *.global to *. svc.cluster.local   |
| destinationrule.networking.istio.io| stio-multicluster-destinationrule| Set traffic policy for 15443 traffic         |
| destinationrule.networking.istio.io| meshexpansion-dr-pilot           | Set traffic policy for `istio-pilot`         |
| destinationrule.networking.istio.io| istio-policy                     | Set traffic policy for `istio-policy`        |
| destinationrule.networking.istio.io| istio-telemetry                  | Set traffic policy for `istio-telemetry`     |
| virtualservice.networking.istio.io | meshexpansion-vs-pilot           | Set route info for `istio-pilot`             |
| virtualservice.networking.istio.io | meshexpansion-vs-citadel         | Set route info for `istio-citadel` 


## Expose service running on cluster to VMs

Every service in the cluster that needs to be accessed from the VM requires a ServiceEntry configuration in the cluster. The host used in the service entry should be of the form <name>.<namespace>.global where name and namespace correspond to the service’s name and namespace respectively.

To demonstrate access from VM to  cluster services, configure the
the [httpbin service]({{<github_tree>}}/samples/httpbin)
in the cluster. 

1. Deploy the `httpbin` service in the cluster

    {{< text bash >}}
    $ kubectl create namespace bar
    $ kubectl label namespace bar istio-injection=enabled
    $ kubectl apply -n bar -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Create a service entry for the `httpbin` service in the cluster.

    To allow services running in VM  to access `httpbin` in the cluster, we need to create
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
    in the [Customized installation of Istio on the Cluster](#Customized-installation-of-Istio-on-the-Cluster) section. Traffic entering port 15443 will be
    load balanced among pods of the appropriate internal service of the target
    cluster (in this case, `httpbin.bar` in the cluster).

    {{< warning >}}
    Do not create a `Gateway` configuration for port 15443.
    {{< /warning >}}



## Send requests from VM to Kubernetes services

After setup, the machine can access services running in the Kubernetes cluster.

The following example shows accessing a service running in the Kubernetes cluster from a mesh expansion VM using
`/etc/hosts/`, in this case using a service from the [httpbin service]({{<github_tree>}}/samples/httpbin).


1.  On the mesh expansion machine, add the service name and address to its `etc/hosts` file. You can then connect to
    the cluster service from the VM, as in the example below:

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

## Running services on a mesh expansion machine

1. Setup an HTTP server on the VM instance to serve HTTP traffic on port 8080:

    {{< text bash >}}
    $ gcloud compute ssh ${GCE_NAME}
    $ python -m SimpleHTTPServer 8888
    {{< /text >}}

1. Determine the VM instance's IP address. 

1. Configure a service entry to enable service discovery for the VM. You can add VM services to the mesh using a
    [service entry](/docs/reference/config/networking/v1alpha3/service-entry/). Service entries let you manually add
    additional services to Pilot's abstract model of the mesh. Once VM services are part of the mesh's abstract model,
    other services can find and direct traffic to them. Each service entry configuration contains the IP addresses, ports,
    and appropriate labels of all VMs exposing a particular service, for example:

    {{< text bash yaml >}}
    $ kubectl -n ${SERVICE_NAMESPACE} apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: vmhttp
    spec:
      hosts:
      - vmhttp.${SERVICE_NAMESPACE}.svc.cluster.local
      ports:
      - number: 8888
        name: http
        protocol: HTTP
      resolution: STATIC
      endpoints:
      - address: ${GCE_IP}
        ports:
          http: 8888
        labels:
          app: vmhttp
          version: "v1"
    EOF
    {{< /text >}}

1. The workloads in a Kubernetes cluster need a DNS mapping to resolve the domain names of VM services. To
    integrate the mapping with your own DNS system, use `istioctl register` and creates a Kubernetes `selector-less`
    service, for example:

    {{< text bash >}}
    $ istioctl  register -n ${SERVICE_NAMESPACE} vmhttp ${VM IP} 8888
    {{< /text >}}

    {{< tip >}}
    Make sure you have already added `istioctl` client to your `PATH` environment variable, as described in the Download page.
    {{< /tip >}}

1. Deploy a pod running the `sleep` service in the Kubernetes cluster, and wait until it is ready:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl get pod
    NAME                             READY     STATUS    RESTARTS   AGE
    productpage-v1-8fcdcb496-xgkwg   2/2       Running   0          1d
    sleep-88ddbcfdd-rm42k            2/2       Running   0          1s
    ...
    {{< /text >}}

1. Send a request from the `sleep` service on the pod to the VM's HTTP service:

    {{< text bash >}}
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl vmhttp.${SERVICE_NAMESPACE}.svc.cluster.local:8888
    {{< /text >}}

    You should see something similar to the output below.

    ```html
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
    ```

**Congratulations!** You successfully configured a service running in a pod within the cluster to
send traffic to a service running on a VM outside of the cluster and tested that
the configuration worked.

## Cleanup

Run the following commands to remove the expansion VM from the mesh's abstract
model.

{{< text bash >}}
$ istioctl deregister -n ${SERVICE_NAMESPACE} vmhttp ${GCE_IP}
2019-02-21T22:12:22.023775Z     info    Deregistered service successfull
$ kubectl delete ServiceEntry vmhttp -n ${SERVICE_NAMESPACE}
serviceentry.networking.istio.io "vmhttp" deleted
{{< /text >}}


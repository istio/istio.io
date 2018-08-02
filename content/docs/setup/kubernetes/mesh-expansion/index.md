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

* The VM must have access to a DNS server that resolves names to cluster IP addresses. Options
include exposing the Kubernetes DNS server through an internal load balancer, using a Core DNS
server, or configuring the IPs in any other DNS server accessible from the VM.

## Installation steps

Setup consists of preparing the mesh for expansion and installing and configuring each VM.
We'll use /etc/hosts as an example in this guide, it is the easiest way to get things working.

### Preparing the Kubernetes cluster for expansion

The following commands must be run on a machine with admin privileges to the cluster.

*  If `--set global.meshExpansion=true` was not specified at install, re-apply the
   template or 'helm upgrade' with the option enabled.

    {{< text bash >}}

    $ cd install/kubernetes/helm/istio
    $ helm upgrade --set global.meshExpansion=true --values myvalues.yaml istio-system .
    $ cd -

    {{< /text >}}

* Find the IP address of the Istio gateway. Advanced users can expose services on a dedicated gateway,
or use an internal load balancer by using a custom `values.yaml` and creating `Gateway` and `VirtualService`
entries to expose istio-pilot and istio-citadel.

    {{< text bash >}}

    $ GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GWIP
    35.232.112.158

    {{< /text >}}

*   Generate a `cluster.env` configuration to be deployed in the VMs. This file contains
the k8s cluster IP address ranges to intercept. The CIDR range is specified at k8s
install time as `servicesIpv4Cidr`. Example commands to obtain the CIDR after install:

    {{< text bash >}}

    $ ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $K8S_CLUSTER --zone $MY_ZONE --project $MY_PROJECT --format "value(servicesIpv4Cidr)")
    $ echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env

    {{< /text >}}

    Here's an example config file

    {{< text bash >}}

    $ cat cluster.env
    ISTIO_CP_AUTH=MUTUAL_TLS
    ISTIO_SERVICE_CIDR=10.55.240.0/20

    {{< /text >}}

* Add the ports that will be exposed by the VM to the cluster env. This can be changed later, and
is not required if the VM only calls services in the mesh.

    {{< text bash >}}

    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> cluster.env

    {{< /text >}}

* Extract the initial keys for the service account to use on the VMs.

    {{<text bash>}}

    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.root-cert\.pem}' |base64 --decode > root-cert.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.key\.pem}' |base64 --decode > key.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
          -o jsonpath='{.data.cert-chain\.pem}' |base64 --decode > cert-chain.pem

    {{< /text >}}

### Setting up the machines

* Install the debian package:

    {{< text bash >}}

    $ curl -L https://storage.googleapis.com/istio-release/releases/1.0.0/deb/istio-sidecar.deb > istio-sidecar.deb
    $ dpkg -i istio-sidecar.deb

    {{< /text >}}

* Copy the cluster.env and the *.pem files to the VM.

* Add the IP address of istio gateway to /etc/hosts or to the DNS server. Example for /etc/hosts:

    {{< text bash>}}

    $ echo "35.232.112.158 istio-citadel istio-pilot istio-pilot.istio-system" >> /etc/hosts

    {{< /text >}}

* Install root-cert.pem, key.pem and cert-chain.pem under /etc/certs, owned by istio-proxy.

    {{< text bash >}}

    $ sudo mkdir /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    $ sudo chown -R istio-proxy /etc/certs

    {{< /text >}}

* Install cluster.env under /var/lib/istio/envoy, owned by istio-proxy.

    {{< text bash >}}

    $ sudo cp cluster.env /var/lib/istio/envoy
    $ sudo chown -R istio-proxy /var/lib/istio/envoy

    {{< /text >}}

* Verify the node agent works:

    {{< text bash >}}

    $ sudo node_agent
    ....
    CSR is approved successfully. Will renew cert in 1079h59m59.84568493s

    {{< /text >}}

* Start istio using systemctl.

    {{< text bash >}}

    $ sudo systemctl start istio-auth-node-agent
    $ sudo systemctl start istio

    {{< /text >}}

After setup, the machine should be able to access services running in the Kubernetes cluster
or other mesh expansion machines.

Example using `/etc/hosts`:

    {{< text bash >}}

    $ # On the kubeadm machine
    $ kubectl -n bookinfo get svc productpage -o jsonpath='{.spec.clusterIP}'
    10.55.246.247

    {{< /text >}}

    {{< text bash >}}

    $ # On the VM
    $ sudo echo "10.55.246.247 productpage.bookinfo.svc.cluster.local" >> /etc/hosts
    $ curl productpage.bookinfo.svc.cluster.local:9080
    ... html content ...

    {{< /text >}}

## Running services on a mesh expansion machine

VMs are added to the mesh by configuring a ServiceEntry. The ServiceEntry will contain the IP
addresses, ports and labels of all VMs exposing a service.

    {{< text bash yaml>}}

    $ kubectl -n test apply -f - << EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: vm1
    spec:
       hosts:
       - vm1.test.svc.cluster.local
       ports:
       - number: 80
         name: http
         protocol: HTTP
       resolution: STATIC
       endpoints:
        - address: 10.128.0.17
          ports:
            http: 8080
          labels:
            app: vm1
            version: 1
    EOF

    {{< /text >}}

## Troubleshooting

The following steps provide basic trouble shooting for common mesh expansion issues.

1. When making requests from VM to the cluster, ensure you don't run the requests as `root` or
 `istio-proxy` user. By default, Istio excludes both users from interception.

1. Verify the machine can reach the IP of the all workloads running in the cluster. For example:

    {{< text bash >}}

    $ kubectl get endpoints -n bookinfo productpage -o jsonpath='{.subsets[0].addresses[0].ip}'
    10.52.39.13

    {{< /text >}}

    {{< text bash >}}

    $ curl 10.52.39.13:9080
    html output

    {{< /text >}}

1. Check the status of the node agent and sidecar:

    {{< text bash >}}

    $ sudo systemctl status istio-auth-node-agent
    $ sudo systemctl status istio

    {{< /text >}}

1. Check that the processes are running:

    {{< text bash >}}

    $ ps aux |grep istio
    root      6941  0.0  0.2  75392 16820 ?        Ssl  21:32   0:00 /usr/local/istio/bin/node_agent --logtostderr
    root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=default exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
    istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
    istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.default~default.svc.cluster.local

    {{< /text >}}

1. Check the Envoy access and error logs:

    {{< text bash >}}

    $ tail /var/log/istio/istio.log
    $ tail /var/log/istio/istio.err.log

    {{< /text >}}
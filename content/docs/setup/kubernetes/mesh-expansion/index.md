---
title: Mesh Expansion
description: Instructions for integrating VMs and bare metal hosts into an Istio mesh deployed on Kubernetes.
weight: 95
keywords: [kubernetes,vms]
---

This guide provides instructions for integrating VMs and bare metal hosts into an Istio mesh
deployed on Kubernetes.

## Prerequisites

* You have already set up Istio on Kubernetes. If you haven't done so, you can find out how in the [Installation guide](/docs/setup/kubernetes/quick-start/).

* Mesh expansion machines must have IP connectivity to the endpoints in the mesh. This
typically requires a VPC or a VPN, as well as a container network that
provides direct (without NAT or firewall deny) routing to the endpoints. The machine
is not required to have access to the cluster IP addresses assigned by Kubernetes.

* Mesh expansion VMs must have access to a DNS server that resolves names to cluster IP addresses. Options
include exposing the Kubernetes DNS server through an internal load balancer, using a Core DNS
server, or configuring the IPs in any other DNS server accessible from the VM.

* If you haven't already enabled mesh expansion [at install time with Helm](/docs/setup/kubernetes/helm-install/), you have
installed the [Helm client](https://docs.helm.sh/using_helm/). You'll need it to enable mesh expansion for the cluster.

## Installation steps

Setup consists of preparing the mesh for expansion and installing and configuring each VM.

### Preparing the Kubernetes cluster for expansion

The first step when adding non-Kubernetes services to an Istio mesh is to configure the Istio installation itself, and
generate the configuration files that let mesh expansion VMs connect to the mesh. To prepare the
cluster for mesh expansion, run the following commands on a machine with cluster admin privileges:

1.  Ensure that mesh expansion is enabled for the cluster. If you did not specify `--set global.meshExpansion=true` at
    install time with Helm, there are two options for enabling mesh expansion, depending on how you originally installed
    Istio on the cluster:

    *   If you installed Istio with Helm and Tiller, run `helm upgrade` with the new option:

    {{< text bash >}}
    $ cd install/kubernetes/helm/istio
    $ helm upgrade --set global.meshExpansion=true istio-system .
    $ cd -
    {{< /text >}}

    *   If you installed Istio without Helm and Tiller, use `helm template` to update your configuration with the option and
        reapply with `kubectl`:

    {{< text bash >}}
    $ cd install/kubernetes/helm/istio
    $ helm template --set global.meshExpansion=true --namespace istio-system . > istio.yaml
    $ kubectl apply -f istio.yaml
    $ cd -
    {{< /text >}}

    > When updating configuration with Helm, you can either set the option on the command line, as in our examples, or add
    it to a `.yaml` values file and pass it to
    the command with `--values`, which is the recommended approach when managing configurations with multiple options. You
    can see some sample values files in your Istio installation's `install/kubernetes/helm/istio` directory and find out
    more about customizing Helm charts in the [Helm documentation](https://docs.helm.sh/using_helm/#using-helm).

1.  Find the IP address of the Istio ingress gateway, as this is how the mesh expansion machines will access [Citadel](/docs/concepts/security/) and [Pilot](/docs/concepts/traffic-management/#pilot-and-envoy).

    {{< text bash >}}
    $ GWIP=$(kubectl get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GWIP
    35.232.112.158
    {{< /text >}}

1.  Generate a `cluster.env` configuration to deploy in the VMs. This file contains the Kubernetes cluster IP address ranges
    to intercept and redirect via Envoy. You specify the CIDR range when you install Kubernetes as `servicesIpv4Cidr`.
    Replace `$MY_ZONE` and `$MY_PROJECT` in the following example commands with the appropriate values to obtain the CIDR
    after installation:

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(gcloud container clusters describe $K8S_CLUSTER --zone $MY_ZONE --project $MY_PROJECT --format "value(servicesIpv4Cidr)")
    $ echo -e "ISTIO_CP_AUTH=MUTUAL_TLS\nISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR\n" > cluster.env
    {{< /text >}}

1.  Check the contents of the generated `cluster.env` file. It should be similar to the following example:

    {{< text bash >}}
    $ cat cluster.env
    ISTIO_CP_AUTH=MUTUAL_TLS
    ISTIO_SERVICE_CIDR=10.55.240.0/20
    {{< /text >}}

1.  (Optional)  If the VM only calls services in the mesh, you can skip this step. Otherwise, add the ports the VM exposes
    to the `cluster.env` file with the following command. You can change the ports later if necessary.

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> cluster.env
    {{< /text >}}

1.  Extract the initial keys for the service account to use on the VMs.

    {{< text bash >}}
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.root-cert\.pem}' |base64 --decode > root-cert.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
        -o jsonpath='{.data.key\.pem}' |base64 --decode > key.pem
    $ kubectl -n $SERVICE_NAMESPACE get secret istio.default  \
          -o jsonpath='{.data.cert-chain\.pem}' |base64 --decode > cert-chain.pem
    {{< /text >}}

### Setting up the machines

Next, run the following commands on each machine that you want to add to the mesh:

1.  Install the Debian package with the Envoy sidecar:

    {{< text bash >}}
    $ curl -L https://storage.googleapis.com/istio-release/releases/1.0.0/deb/istio-sidecar.deb > istio-sidecar.deb
    $ dpkg -i istio-sidecar.deb
    {{< /text >}}

1.  Copy the `cluster.env` and `*.pem` files that you created in the previous section to the VM.

1.  Add the IP address of the Istio gateway (which we found in the [previous section](#preparing-the-kubernetes-cluster-for-expansion))
    to `/etc/hosts` or to
    the DNS server. In our example we'll use `/etc/hosts` as it is the easiest way to get things working. The following is
    an example of updating an `/etc/hosts` file with the Istio gateway address:

    {{< text bash >}}
    $ echo "35.232.112.158 istio-citadel istio-pilot istio-pilot.istio-system" >> /etc/hosts
    {{< /text >}}

1.  Install `root-cert.pem`, `key.pem` and `cert-chain.pem` under `/etc/certs/`.

    {{< text bash >}}
    $ sudo mkdir /etc/certs
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

After setup, the machine can access services running in the Kubernetes cluster
or on other mesh expansion machines.

The following example shows accessing a service running in the Kubernetes cluster from a mesh expansion VM using
`/etc/hosts/`, in this case using a service from the [Bookinfo example](/docs/examples/bookinfo/).

1.  First, on the cluster admin machine get the virtual IP address (`clusterIP`) for the service:

    {{< text bash >}}
$ kubectl -n bookinfo get svc productpage -o jsonpath='{.spec.clusterIP}'
10.55.246.247
    {{< /text >}}

1.  Then on the mesh expansion machine, add the service name and address to its `etc/hosts` file. You can then connect to
    the cluster service from the VM, as in the example below:

    {{< text bash >}}
$ sudo echo "10.55.246.247 productpage.bookinfo.svc.cluster.local" >> /etc/hosts
$ curl productpage.bookinfo.svc.cluster.local:9080
... html content ...
    {{< /text >}}

## Running services on a mesh expansion machine

You add VM services to the mesh by configuring a
[`ServiceEntry`](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry). A service entry lets you manually add
additional services to Istio's model of the mesh so that other services can find and direct traffic to them. Each
`ServiceEntry` configuration contains the IP addresses, ports, and labels (where appropriate) of all VMs exposing a
particular service, as in the following example.

{{< text bash yaml >}}
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

The following are some basic troubleshooting steps for common mesh expansion issues.

*    When making requests from a VM to the cluster, ensure you don't run the requests as `root` or
    `istio-proxy` user. By default, Istio excludes both users from interception.

*    Verify the machine can reach the IP of the all workloads running in the cluster. For example:

    {{< text bash >}}
    $ kubectl get endpoints -n bookinfo productpage -o jsonpath='{.subsets[0].addresses[0].ip}'
    10.52.39.13
    {{< /text >}}

    {{< text bash >}}
    $ curl 10.52.39.13:9080
    html output
    {{< /text >}}

*    Check the status of the node agent and sidecar:

    {{< text bash >}}
    $ sudo systemctl status istio-auth-node-agent
    $ sudo systemctl status istio
    {{< /text >}}

*    Check that the processes are running. The following is an example of the processes you should see on the VM if you run
     `ps`, filtered for `istio`:

    {{< text bash >}}
    $ ps aux | grep istio
    root      6941  0.0  0.2  75392 16820 ?        Ssl  21:32   0:00 /usr/local/istio/bin/node_agent --logtostderr
    root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=default exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
    istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
    istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.default~default.svc.cluster.local
    {{< /text >}}

*    Check the Envoy access and error logs:

    {{< text bash >}}
    $ tail /var/log/istio/istio.log
    $ tail /var/log/istio/istio.err.log
    {{< /text >}}

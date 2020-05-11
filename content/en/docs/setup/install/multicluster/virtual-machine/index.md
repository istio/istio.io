---
title: Installing Istio for virtual machine connectivity
description: Install an Istio mesh such that a virtual machine can connect to it and configure the virtual machine.
weight: 3
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
---

Follow this guide to install an Istio control plane
[multicluster deployment](/docs/ops/deployment/deployment-models/#multiple-clusters) and connect your first virtual machine.

## Prerequisites

1. [Download the Istio release] (/docs/setup/getting-started/#download)
1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/)
1. Check the requirements [for Pods and Services](/docs/ops/deployment/requirements/)
1.  Virtual machines must have IP connectivity to the ingress gateway in the connecting mesh, or alternatively, every pod in the mesh via L3 networking.

## Installing the Istio control plane

1. Generate intermediate CA certificates for each cluster's CA from your
    organization's root CA. The shared root CA enables mutual TLS communication
    across different clusters or virtual machines. For illustration purposes,
    the following instructions use the certificates from the Istio samples
    directory for the cluster.

1. Run the following commands on each cluster in the mesh where a virtual
    machine connection should be established. See
    [Certificate Authority (CA) certificates](/docs/tasks/security/cert-management/plugin-ca-cert/)
    for more details on configuring an external CA.

    {{< text bash >}}
    $ cd samples/certs
    $ make vm
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file=vm/ca-cert.pem \
        --from-file=vm/ca-key.pem \
        --from-file=vm/root-cert.pem \
        --from-file=vm/cert-chain.pem
    $ cd ../..
    {{< /text >}}

1. Generate a `cluster.env` configuration file that informs the virtual machine
   deployment which network CIDR to capture and redirect to the Kubernetes
   cluster:

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(echo '{"apiVersion":"v1","kind":"Service","metadata":{"name":"tst"},"spec":{"clusterIP":"1.1.1.1","ports":[{"port":443}]}}' | kubectl apply -f - 2>&1 | sed 's/.*valid IPs is //')
    $ echo -n ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR > $HOME/cluster.env
    {{< /text >}}

1. Configure a select set of ports for exposure from the virtual machine. If you do not
   apply this optional step, all outbound traffic on all ports is sent to the
   Kubernetes cluster. You may wish to send some traffic on specific ports to
   other destinations. This example shows enabling ports `3306` and `8080`
   for capture by the Istio virtual machine integration and transmission to Kubernetes.
   All other ports are sent over the default gateway of the virtual machine.

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> $HOME/cluster.env
    {{< /text >}}

1. Install Istio with mesh expansion features:

    {{< text bash >}}
    $ cat <<EOF> vmintegration.yaml
    apiVersion: install.istio.io/v1alpha1

    kind: IstioOperator
    spec:
      values:
        global:
          meshExpansion:
            enabled: true
          controlPlaneSecurityEnabled: true
    EOF
    $ istioctl install -f vmintegration.yaml
    {{< /text >}}

### Installing the virtual machine

Run the following commands on the virtual machine you want to add to the Istio mesh:

1. Copy the previously created `cluster.env` and `*.pem` files to the virtual machine.

1. Install the Debian package containing the Istio virtual machine integration runtime.

    {{< text bash >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1. Add an IP address for Istiod to `/etc/hosts`. Replace `<INGRESS_GATEWAY>`  with the
    ingress gateway service of istiod. Revisit
    [Determining the Ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) to determine the <INGRESS_GATEWAY>.

    {{< text bash >}}
    $ sudo echo "<INGRESS_GATEWAY> istiod.istio-system.svc" >> /etc/hosts
    {{< /text >}}

    {{< idea >}}
    A sophisticated option involves configuring DNS within the virtual
    machine to reference an external DNS server. This option is beyond
    the scope of this document.
    {{< /idea >}}

1. The ingress gateway port for Istiod is automatically programmed to 15012 throughout
    the Istio software. Record the ISTIO_PILOT_PORT address.

    {{< text bash >}}
    $ echo "ISTIO_PILOT_PORT=15012" >> cluster.env
    {{< /text >}}

1. Install `root-cert.pem`, `key.pem` and `cert-chain.pem` within the directory `/etc/certs/`.

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1. Install `cluster.env` under `/var/lib/istio/envoy/`.

    {{< text bash >}}
    $ sudo cp cluster.env /var/lib/istio/envoy
    {{< /text >}}

1. Transfer ownership of the files in `/etc/certs/` and `/var/lib/istio/envoy/` to the Istio proxy.

    {{< text bash >}}
    $ sudo chown -R istio-proxy /etc/certs /var/lib/istio/envoy
    {{< /text >}}

1. Start Istio within the virtual machine.

    {{< text bash >}}
    $ sudo systemctl start istio
    {{< /text >}}

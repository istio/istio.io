---
title: Installing Istio for virtual machine connectivity
description: Install an Istio mesh such that a virtual machine can connect to it and configure the virtual machine.
weight: 40
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
---

Follow this guide to deploy a [multicluster service mesh](/docs/ops/deployment/deployment-models/#multiple-clusters) spanning one more more clusters and then connect a virtual machine to it.

{{< warning >}}
This guide relies heavily on the
[stable plugin ca certificate](/docs/tasks/security/cert-management/plugin-ca-cert/) feature. Istio
does not offer an industry standard recommendation for certificate management. Please consult your
information security team when using any plugin certificate.  The determination of your company
policies for certificate management is the choice of your company.
{{< /warning >}}

{{< tip >}}
This guide is tested and validated. The Istio authors feel this guide is suitable for experimentation
but not production. Like all alpha features, this guide is subject to change.
{{< /tip >}}

## Prerequisites

1. [Download the Istio release](/docs/setup/getting-started/#download)
1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/)
1. Check the requirements [for Pods and Services](/docs/ops/deployment/requirements/)
1. Virtual machines must have IP connectivity to the ingress gateway in the connecting mesh, and optionally every pod in the mesh via L3 networking if enhanced performance is desired.

## Installing the Istio control plane

1. Set the name of your cluster as an environment variable.

    {{< text bash >}}
    $ CLUSTER_NAME="<the name of your cluster>"
    {{< /text >}}

1. Set the name of your desired namespace as an environment variable.

    {{< text bash >}}
    $ SERVICE_NAMESPACE="<the name of your service namespace>"
    {{< /text >}}

1. Create a working directory for files generated in this install guide.

    {{< text bash >}}
    $ mkdir -p "${HOME}"/"${CLUSTER_NAME}"
    $ mkdir -p "${HOME}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"
    {{< /text >}}

1. Execute the following commands on the cluster in the mesh where a virtual
    machine connection should be established. See
    [Certificate Authority (CA) certificates](/docs/tasks/security/cert-management/plugin-ca-cert/)
    for more details on configuring an external CA.  The `NAME` variable is
    unimportant, although this is used during certificate generation to
    uniquely identify clusters.  The `NAMESPACE` variable identifies the
    namespace where the virtual machine connectivity is hosted.

    {{< text bash >}}
    $ make -C samples/certs NAME="${CLUSTER_NAME}" NAMESPACE="${SERVICE_NAMESPACE}" "${CLUSTER_NAME}"-certs-wl
    $ cp -a samples/certs/"${CLUSTER_NAME}"/ca-cert.pem "${HOME}"/"${CLUSTER_NAME}"
    $ cp -a samples/certs/"${CLUSTER_NAME}"/ca-key.pem "${HOME}"/"${CLUSTER_NAME}"
    $ cp -a samples/certs/"${CLUSTER_NAME}"/root-cert.pem "${HOME}"/"${CLUSTER_NAME}"
    $ cp -a samples/certs/"${CLUSTER_NAME}"/cert-chain.pem "${HOME}"/"${CLUSTER_NAME}"
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file="${HOME}"/"${CLUSTER_NAME}"/ca-cert.pem \
        --from-file="${HOME}"/"${CLUSTER_NAME}"/ca-key.pem \
        --from-file="${HOME}"/"${CLUSTER_NAME}"/root-cert.pem \
        --from-file="${HOME}"/"${CLUSTER_NAME}"/cert-chain.pem
    {{< /text >}}

1. Copy certificates to a directory for later provisioning of a virtual machine.

    {{< text bash >}}
    $ cp -a samples/certs/"${CLUSTER_NAME}"/key.pem "${HOME}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"
    $ cp -a samples/certs/"${CLUSTER_NAME}"/root-cert.pem "${HOME}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"
    $ cp -a samples/certs/"${CLUSTER_NAME}"/workload-cert-chain.pem "${HOME}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/cert-chain.pem
    {{< /text >}}

1. Generate a `cluster.env` configuration file that informs the virtual machine
   deployment which network CIDR to capture and redirect to the Kubernetes
   cluster:

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(echo '{"apiVersion":"v1","kind":"Service","metadata":{"name":"tst"},"spec":{"clusterIP":"1.1.1.1","ports":[{"port":443}]}}' | kubectl apply -f - 2>&1 | sed 's/.*valid IPs is //')
    $ echo -n ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR > "${HOME}"/"${CLUSTER_NAME}"/cluster.env
    {{< /text >}}

1. Configure a select set of ports for exposure from the virtual machine. If you do not
   apply this optional step, all outbound traffic on all ports is sent to the
   Kubernetes cluster. You may wish to send some traffic on specific ports to
   other destinations. This example shows enabling ports `3306` and `8080`
   for capture by Istio virtual machine integration and transmission to Kubernetes.
   All other ports are sent over the default gateway of the virtual machine.

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> "${HOME}"/"${CLUSTER_NAME}"/cluster.env
    {{< /text >}}

1. Install Istio with virtual machine integration features enabled:

    {{< text bash >}}
    $ cat <<EOF> "${HOME}"/vmintegration.yaml
    apiVersion: install.istio.io/v1alpha1
    metadata:
      namespace: istio-system
      name: example-istiocontrolplane
    kind: IstioOperator
    spec:
      values:
        global:
          meshExpansion:
            enabled: true
    EOF
    $ istioctl install -f "${HOME}"/vmintegration.yaml
    {{< /text >}}

### Installing the virtual machine

Run the following commands on the virtual machine you want to add to the Istio mesh:

1. Copy the previously created `cluster.env` and `*.pem` files to the virtual machine.

1. Install the Debian package containing the Istio virtual machine integration runtime.

    {{< text bash >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1. Add an IP address for Istiod to `/etc/hosts`. Replace `<INGRESS_GATEWAY>` with the
    ingress gateway service of istiod. Revisit
    [Determining the ingress host and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) to set the environment variable `${INGRESS_HOST}`.

    {{< text bash >}}
    $ sudo echo "${INGRESS_HOST} istiod.istio-system.svc" >> /etc/hosts
    {{< /text >}}

    {{< idea >}}
    A sophisticated option involves configuring DNS within the virtual
    machine to reference an external DNS server. This option is beyond
    the scope of this document.
    {{< /idea >}}

1. Install `root-cert.pem`, `key.pem` and `cert-chain.pem` within the directory `/etc/certs/`.

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1. Install `cluster.env` within `/var/lib/istio/envoy/`.

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

## Uninstall

To uninstall Istio, run the following command:

{{< text bash >}}
$ istioctl manifest generate -f "${HOME}"/vmintegration.yaml | kubectl delete -f -
{{< /text >}}

The control plane namespace (e.g., `istio-system`) is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

---
title: Virtual Machine Installation
description: Deploy Istio and connect a workload running within a virtual machine to it.
weight: 40
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
owner: istio/wg-environments-maintainers
test: no
---

Follow this guide to deploy Istio and connect a virtual machine to it.

{{< warning >}}
This guide has a requirement that the user is using a [plugin root CA](/docs/tasks/security/cert-management/plugin-ca-cert/)
and has configured Istio as an intermediate CA.
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

## Prepare the guide environment

1. Set the environment variables `"${ISTIO_DIR}"`, `"${WORK_DIR}"`, your cluster
    name, and the service namespace. Ensure `"${WORK_DIR}"` is prefixed with `"${HOME}"`
    (e.g. `WORK_DIR="${HOME}"/vmintegration`).

    {{< text bash >}}
    $ ISTIO_DIR="<the directory containing an unarchived version of Istio>"
    $ CLUSTER_NAME="<the name of your cluster>"
    $ SERVICE_NAMESPACE="<the name of your service namespace>"
    $ WORK_DIR="<a certificate working directory>"
    {{< /text >}}

1. Create the `"${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"` working directories.

    {{< text bash >}}
    $ mkdir -p "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"
    {{< /text >}}

## Create certificates for use with the virtual machine and Istio control plane

{{< tip >}}
This `Makefile` is limited to creating one virtual machine certificate per cluster. The Istio authors
expect operators to read and understand this guide to formulate their own plans for creating and
managing virtual machines. It is important for you to read and understand this `Makefile` for any
deployment you place into production.
{{< /tip >}}

1. Execute the following commands to create certificates for use by Istio. See
    [Certificate Authority (CA) certificates](/docs/tasks/security/cert-management/plugin-ca-cert/)
    for more details on configuring an external CA. The `NAME` variable is
    used during certificate generation to uniquely identify clusters. The
    `NAMESPACE` variable identifies the namespace where the virtual machine
    connectivity is hosted.

    {{< text bash >}}
    $ cd "${WORK_DIR}"
    $ make -f "${ISTIO_DIR}"/tools/certs/Makefile NAME="${CLUSTER_NAME}" NAMESPACE="${SERVICE_NAMESPACE}" "${CLUSTER_NAME}"-cacerts-selfSigned
    {{< /text >}}

1. Execute the following commands to create certificates for use on the virtual machine.

    {{< text bash >}}
    $ cd "${WORK_DIR}"
    $ make -f "${ISTIO_DIR}"/tools/certs/Makefile NAME="${CLUSTER_NAME}" NAMESPACE="${SERVICE_NAMESPACE}" "${NAMESPACE}"-certs-selfSigned
    {{< /text >}}

## Install the Istio control plane

The Istio control plane must be installed with virtual machine integration enabled (`values.global.meshExpansion.enabled: true`).

1. Register the certificates needed for installation.

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
        --from-file=ca-cert.pem="${WORK_DIR}"/"${CLUSTER_NAME}"/selfSigned-ca-cert.pem \
        --from-file=ca-key.pem="${WORK_DIR}"/"${CLUSTER_NAME}"/selfSigned-ca-key.pem \
        --from-file=root-cert.pem="${WORK_DIR}"/"${CLUSTER_NAME}"/root-cert.pem \
        --from-file=cert-chain.pem="${WORK_DIR}"/"${CLUSTER_NAME}"/selfSigned-ca-cert-chain.pem
    {{< /text >}}

1. Create the install `IstioOperator` custom resource:

    {{< text bash >}}
    $ cat <<EOF> "${WORK_DIR}"/vmintegration.yaml
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
    {{< /text >}}

1. Install or upgrade Istio with virtual machine integration features enabled.

    {{< text bash >}}
    $ istioctl install -f "${WORK_DIR}"/vmintegration.yaml
    {{< /text >}}

## Create files to transfer to the virtual machine

1. Make a copy of files to copy to the virtual machine

    {{< text bash >}}
    $ cp -a "${WORK_DIR}"/"${SERVICE_NAMESPACE}"/key.pem "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/
    $ cp -a "${WORK_DIR}"/"${SERVICE_NAMESPACE}"/root-cert.pem "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/
    $ cp -a "${WORK_DIR}"/"${SERVICE_NAMESPACE}"/selfSigned-workload-cert-chain.pem "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/cert-chain.pem
    {{< /text >}}

1. Generate a `cluster.env` configuration file that informs the virtual machine
   deployment which network CIDR to capture and redirect to the Kubernetes
   cluster:

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(echo '{"apiVersion":"v1","kind":"Service","metadata":{"name":"tst"},"spec":{"clusterIP":"1.1.1.1","ports":[{"port":443}]}}' | kubectl apply -f - 2>&1 | sed 's/.*valid IPs is //')
    $ touch "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/cluster.env
    $ echo ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR > "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/cluster.env
    {{< /text >}}

1. Optionally configure configure a select set of ports for exposure from the
   virtual machine. If you do not apply this optional step, all outbound traffic
   on all ports is sent to the Kubernetes cluster. You may wish to send some
   traffic on specific ports to other destinations. This example shows enabling
   ports `3306` and `8080` for capture by Istio virtual machine integration and
   transmission to Kubernetes. All other ports are sent over the default gateway
   of the virtual machine.

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/cluster.env
    {{< /text >}}

1. Add an IP address that represents Istiod. Replace `${INGRESS_HOST}` with the
    ingress gateway service of istiod. Revisit
    [Determining the ingress host and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) to set the environment variable `${INGRESS_HOST}`.

    {{< text bash >}}
    $ touch "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/hosts-addendum
    $ echo "${INGRESS_HOST} istiod.istio-system.svc" > "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/hosts-addendum
    {{< /text >}}

    {{< idea >}}
    A sophisticated option involves configuring DNS within the virtual
    machine to reference an external DNS server. This option is beyond
    the scope of this guide.
    {{< /idea >}}

## Configure the virtual machine

Run the following commands on the virtual machine you want to add to the Istio mesh:

1. Securely transfer the files from `"${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"`
    to the virtual machine.  How you choose to securely transfer those files should be done with consideration for
    your information security policies.

1. Update the cache of package updates for your `deb` packaged distro.

    {{< text bash >}}
    $ sudo apt -y update
    {{< /text >}}

1. Upgrade the `deb` packaged distro to ensure all latest security packages are applied.

    {{< text bash >}}
    $ sudo apt -y upgrade
    {{< /text >}}

1. Install the `deb` package containing the Istio virtual machine integration runtime.

    {{< text bash >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1. Install `root-cert.pem`, `key.pem` and `cert-chain.pem` within the directory `/etc/certs/`.

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp {root-cert.pem,cert-chain.pem,key.pem} /etc/certs
    {{< /text >}}

1. Install `cluster.env` within `/var/lib/istio/envoy/`.

    {{< text bash >}}
    $ sudo cp cluster.env /var/lib/istio/envoy
    {{< /text >}}

1. Add the istiod host to `/etc/hosts`.

    {{< text bash >}}
    $ sudo sh -c 'cat hosts-addendum >> /etc/hosts'
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
$ istioctl manifest generate -f "${WORK_DIR}"/vmintegration.yaml | kubectl delete -f -
{{< /text >}}

The control plane namespace (e.g., `istio-system`) is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

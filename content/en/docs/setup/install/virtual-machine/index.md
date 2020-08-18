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

1. Create a virtual machine
1. Set the environment variables `"${VM_NAME}"`, `"${WORK_DIR}"`,`"${CLUSTER_NAME}"` , `"${VM_NAMESPACE}"`,
，`"${SERVICE_ACCOUNT}"` your cluster name, and the service namespace. Ensure `"${WORK_DIR}"` is prefixed with `"${HOME}"`
    (e.g. `WORK_DIR="${HOME}"/vmintegration`).

    {{< text bash >}}
    $ VM_NAME="<the name of your vm instance you created>"
    $ CLUSTER_NAME="<the name of your cluster>"
    $ VM_NAMESPACE="<the name of your service namespace>"
    $ WORK_DIR="<a certificate working directory>"
    $ SERVICE_ACCOUNT="<name of the Kubernetes service account you want to use for your VM>"
    {{< /text >}}

1. Create the `"${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"` working directories.

    {{< text bash >}}
    $ mkdir -p "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"
    {{< /text >}}
    
## Install the Istio control plane

 Set the IstioOperator spec `values.global.meshExpansion.enabled: true`

1. Create namespace to install Istio.

    {{< text bash >}}
    $ kubectl create namespace istio-system
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

## Create Namespace 

1. Create Namespace that will host the virtual machine

    {{< text bash >}}
    $ kubectl create namespace "${VM_NAMESPACE}"
    {{< /text >}}

1. Create a serviceaccount for virtual machine

    {{< text bash >}}
    $ kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}" 
    {{< /text >}}

## Create files to transfer to the virtual machine

1. Create Kubernetes token in the example you can set the  

    {{< text bash >}}
    $ tokenexpiretime=3600
    $ echo '{"kind":"TokenRequest","apiVersion":"authentication.k8s.io/v1","spec":{"audiences":["istio-ca"],"expirationSeconds":'$tokenexpiretime'}}' | kubectl create --raw /api/v1/namespaces/$VM_NAMESPACE/serviceaccounts/$SERVICE_ACCOUNT/token -f - | jq -j '.status.token' > "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/istio-token
    {{< /text >}}

1. Get the root cert

    {{< text bash >}}
    $ kubectl -n "${VM_NAMESPACE}" get configmaps istio-ca-root-cert -o json | jq -j '."data"."root-cert.pem"' > "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/root-cert
    {{< /text >}}

1. Generate a `cluster.env` configuration file that informs the virtual machine
   deployment which network CIDR to capture and redirect to the Kubernetes
   cluster:

    {{< text bash >}}
    $ ISTIO_SERVICE_CIDR=$(echo '{"apiVersion":"v1","kind":"Service","metadata":{"name":"tst"},"spec":{"clusterIP":"1.1.1.1","ports":[{"port":443}]}}' | kubectl apply -f - 2>&1 | sed 's/.*valid IPs is //')
    $ touch "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/cluster.env
    $ echo ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR > "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/cluster.env
    {{< /text >}}

1. Optionally configure configure a select set of ports for exposure from the
   virtual machine. If you do not apply this optional step, all outbound traffic
   on all ports is sent to the Kubernetes cluster. You may wish to send some
   traffic on specific ports to other destinations. This example shows enabling
   ports `3306` and `8080` for capture by Istio virtual machine integration and
   transmission to Kubernetes. All other ports are sent over the default gateway
   of the virtual machine.

    {{< text bash >}}
    $ echo "ISTIO_INBOUND_PORTS=3306,8080" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/cluster.env
    {{< /text >}}

1. Add an IP address that represents Istiod. Replace `${INGRESS_HOST}` with the
    ingress gateway service of istiod. Revisit
    [Determining the ingress host and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) to set the environment variable `${INGRESS_HOST}`.

    {{< text bash >}}
    $ touch "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/hosts-addendum
    $ echo "${INGRESS_HOST} istiod.istio-system.svc" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/hosts-addendum
    {{< /text >}}

    {{< idea >}}
    A sophisticated option involves configuring DNS within the virtual
    machine to reference an external DNS server. This option is beyond
    the scope of this guide.
    {{< /idea >}}

1. Create `sidecar.env` to import required environment variable 

    {{< text bash >}}
    $ touch "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/sidecar.env
    $ echo "ISTIO_INBOUND_PORTS=*" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/sidecar.env
    $ echo "ISTIO_LOCAL_EXCLUDE_PORTS=15090,15021,15020" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/sidecar.env
    $ echo "PROV_CERT=/var/run/secrets/istio" >>"${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/sidecar.env
    $ echo "OUTPUT_CERTS=/var/run/secrets/istio" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"/sidecar.env
    {{< /text >}}
    
## Configure the virtual machine

Run the following commands on the virtual machine you want to add to the Istio mesh:

1. Securely transfer the files from `"${WORK_DIR}"/"${CLUSTER_NAME}"/"${VM_NAMESPACE}"`
    to the virtual machine.  How you choose to securely transfer those files should be done with consideration for
    your information security policies. For convenience in this guide, you should transfer all of the required files to `"${HOME}"` in the virtual machine

1. Update the cache of package updates for your `deb` packaged distro.

    {{< text bash >}}
    $ sudo apt -y update
    {{< /text >}}

1. Upgrade the `deb` packaged distro to ensure all latest security packages are applied.

    {{< text bash >}}
    $ sudo apt -y upgrade
    {{< /text >}}

1. Install the root cert to the `/var/run/secrets/istio`
    
    {{< text bash >}}
    $ sudo mkdir -p /var/run/secrets/istio
    $ sudo cp "${HOME}"/root-cert.pem /var/run/secrets/istio/root-cert.pem
    {{< /text >}}
    
1. Install the token to the `/var/run/secrets/tokens`

    {{< text bash >}}
    $ sudo  mkdir -p /var/run/secrets/tokens
    $ sudo cp "${HOME}"/istio-token /var/run/secrets/tokens/istio-token
    {{< /text >}}
    
1. Install the `deb` package containing the Istio virtual machine integration runtime.

    {{< text bash >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1. Install `cluster.env` within the directory `/var/lib/istio/envoy/`.

    {{< text bash >}}
    $ sudo cp "${HOME}"/cluster.env /var/lib/istio/envoy/cluster.env
    {{< /text >}}

1. Install `sidecar.env` within the directory `/var/lib/istio/envoy/`.

    {{< text bash >}}
    $ sudo cp "${HOME}"/sidecar.env /var/lib/istio/envoy/sidecar.env
    {{< /text >}}

1. Add the istiod host to `/etc/hosts`.

    {{< text bash >}}
    $ sudo sh -c 'cat $(eval echo ~$SUDO_USER)/hosts-addendum >> /etc/hosts'
    {{< /text >}}

1. Install the root certificate in the directory  `/etc/certs`

    {{< text bash >}}
    $ sudo cp "${HOME}"/root-cert.pem /var/run/secrets/istio/root-cert.pem
    {{< /text >}}

1. Transfer ownership of the files in `/etc/certs/` and `/var/lib/istio/envoy/` to the Istio proxy.

    {{< text bash >}}
    $ sudo mkdir -p /etc/istio/proxy
    $ sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy  /var/run/secrets
    {{< /text >}}

## Start Istio within the virtual machine.

1. start the Istio agent

    {{< text bash >}}
    $ sudo systemctl start istio
    {{< /text >}}
    
## Verify the Istio Work Successfully
1. check the log under  `/var/log/istio/istio.log`. you should see that some logs
    like this: resource:default pushed key/cert pair to proxy

## Uninstall
Stop the Istio running on VM

    {{< text bash >}}
    $ sudo systemctl stop istio
    {{< /text >}}

Remove existing Istio-sidecar package

    {{< text bash >}}
    $ sudo dpkg -r istio-sidecar
    $ dpkg -s istio-sidecar
    {{< /text >}}

To uninstall Istio, run the following command:

{{< text bash >}}
$ istioctl manifest generate -f "${WORK_DIR}"/vmintegration.yaml | kubectl delete -f -
{{< /text >}}

The control plane namespace (e.g., `istio-system`) is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

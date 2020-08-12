---
title: Virtual Machine Installation
description: Deploy istio and connect a workload running within a virtual machine to it.
weight: 40
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
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
1. Create a VM in one of the cloud provider
1. Set the environment variables `"${VM_NAME}"`, `"${WORK_DIR}"`,`"${CLUSTER_NAME}"` , `"${SERVICE_ACCOUNT}"`,
，`"${SERVICE_ACCOUNT}"` your cluster name, and the service namespace. Ensure `"${WORK_DIR}"` is prefixed with `"${HOME}"`
    (e.g. `WORK_DIR="${HOME}"/vmintegration`).

    {{< text bash >}}
    $ VM_NAME="<the name of your vm instance you created>"
    $ CLUSTER_NAME="<the name of your cluster>"
    $ SERVICE_NAMESPACE="<the name of your service namespace>"
    $ WORK_DIR="<a certificate working directory>"
    $ SERVICE_ACCOUNT="<name of the service account you want to create for k8s>"
    {{< /text >}}

1. Create the `"${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"` working directories.

    {{< text bash >}}
    $ mkdir -p "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"
    {{< /text >}}

## Install the Istio control plane

The Istio control plane must be installed with virtual machine integration enabled (`values.global.meshExpansion.enabled: true`).

1. Register the certificates needed for installation.

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

## Create Namespace and Setup policies for VM
1. Create Namespace that will host the VM

    {{< text bash >}}
    $ kubectl create namespace $SERVICE_NAMESPACE
    {{< /text >}}

1. Create a serviceaccount for VM

    {{< text bash >}}
    $kubectl create serviceaccount $SERVICE_ACCOUNT -n $SERVICE_NAMESPACE 
    {{< /text >}}

1. Get the external ip or internal ip of the VM and store to `"${VM_IP}"`

    {{< text bash >}}
    $ VM_IP="<the external ip or internal ip of the VM>"
    {{< /text >}}
    
1. Create a new service
    {{< text bash >}}
    $ cat <<EOF | kubectl -n $SERVICE_NAMESPACE apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: gce-vm
      labels:
        app: gce-vm
    spec:
      ports:
      - port: 7070
        name: grpc
      - port: 8090
        name: http
      selector:
        app: gce-vm
    EOF
    {{< /text >}}
1. Create workload entry

{{< text bash >}}
$ cat <<EOF | kubectl -n $namespace apply -f -
  apiVersion: networking.istio.io/v1beta1
  kind: WorkloadEntry
  metadata:
    name: $VM_NAME
    namespace: $SERVICE_NAMESPACE
  spec:
    address: $VM_IP
    labels:
      app: gce-vm
    serviceAccount: $SERVICE_ACCOUNT
  EOF
{{< /text >}}

## Create files to transfer to the virtual machine

1. Create K8s token
    in the example you can set the  
    {{< text bash >}}
    $ tokenexpiretime=3600
    $ echo '{"kind":"TokenRequest","apiVersion":"authentication.k8s.io/v1","spec":{"audiences":["istio-ca"],"expirationSeconds":'$tokenexpiretime'}}' | kubectl create --raw /api/v1/namespaces/$SERVICE_NAMESPACE/serviceaccounts/$SERVICE_ACCOUNT/token -f - | jq -j '.status.token' > "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/istio-token
    {{< /text >}}

1. Get the root cert

{{< text bash >}}
    $ kubectl -n $SERVICE_NAMESPACE get configmaps istio-ca-root-cert -o json | jq -j '."data"."root-cert.pem"' > "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/root-cert
{{< /text >}}

1. Generate a `cluster.env` configuration file that informs the virtual machine
   deployment which network CIDR to capture and redirect to the Kubernetes
   cluster:

    {{< text bash >}}
    $ export ISTIO_SERVICE_CIDR=$(echo '{"apiVersion":"v1","kind":"Service","metadata":{"name":"tst"},"spec":{"clusterIP":"1.1.1.1","ports":[{"port":443}]}}' | kubectl apply -f - 2>&1 | sed 's/.*valid IPs is //')
    $ touch "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/cluster.env
    $ echo ISTIO_SERVICE_CIDR=$ISTIO_SERVICE_CIDR > "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/cluster.env
    $ echo ISTIO_PILOT_PORT=15012 >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/cluster.env
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
    $ touch "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/hosts
    $ echo "${INGRESS_HOST} istiod.istio-system.svc" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/hosts
    $ echo "1.1.1.1 pod.${SERVICE_NAMESPACE}.svc.cluster.local" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/hosts
    $ echo "1.1.1.1 vm.${SERVICE_NAMESPACE}.svc.cluster.local" >> "${WORK_DIR}"/"${CLUSTER_NAME}"/"${SERVICE_NAMESPACE}"/hosts
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
    your information security policies. For convenience in this guide we think you transfer all the required files 
    under ${HOME}

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
        $ sudo cp ~/root-cert.pem /var/run/secrets/istio/root-cert.pem
    {{< /text >}}
    
1. Install the token to the `/var/run/secrets/tokens`
    {{< text bash >}}
        $ sudo  mkdir -p /var/run/secrets/tokens
        $ sudo cp ~/istio-token /var/run/secrets/tokens/istio-token
    {{< /text >}}
    
1. Install the `deb` package containing the Istio virtual machine integration runtime.

    {{< text bash >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

1. Install `cluster.env` within `/var/lib/istio/envoy/`.

    {{< text bash >}}
    $ sudo cp ~/cluster.env /var/lib/istio/envoy/cluster.env
    {{< /text >}}

1. Add the istiod host to `/etc/hosts`.

    {{< text bash >}}
    $ sudo cp ~/hosts /etc/hosts
    {{< /text >}}

1. Install the root cert to the `/etc/certs`
    
    {{< text bash >}}
        $ sudo cp ~/root-cert.pem /var/run/secrets/istio/root-cert.pem
    {{< /text >}}

1. Transfer ownership of the files in `/etc/certs/` and `/var/lib/istio/envoy/` to the Istio proxy.

    {{< text bash >}}
    $ sudo mkdir -p /etc/istio/proxy
    $ sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy  /var/run/secrets
    {{< /text >}}

1. Set the Environment variable for cert rotation cert received and rotated in `/var/run/secrets/istio` 
    {{< text bash >}}
    $ export ISTIO_INBOUND_PORTS="*"
    $ export ISTIO_LOCAL_EXCLUDE_PORTS="15090,15021,15020"
    $ export PROV_CERT="/var/run/secrets/istio"
    $ export OUTPUT_CERTS="/var/run/secrets/istio"
    {{< /text >}}

1. Start Istio within the virtual machine.

    {{< text bash >}}
    $ sudo -E /usr/local/bin/istio-start.sh
    {{< /text >}}

## Reload istio-sidecar.deb (when you made changes to istio-agent and want to test)
1. Remove existing istio-sidecar package
    {{< text bash >}}
        $ sudo dpkg -r istio-sidecar
        $ dpkg -s istio-sideca
    {{< /text >}}
    
1. Upload new istio-sidecar.deb to VM

1. Regenerate istio-token and upload to VM
    {{< text bash >}}
        $ sudo cp ~/istio-token /var/run/secrets/tokens/istio-token
    {{< /text >}}
    
1. Install new istio-sidecar.deb
    {{< text bash >}}
        $ sudo dpkg -i istio-sidecar.deb
        $ sudo chown -R istio-proxy /var/lib/istio /etc/certs
        $ export ISTIO_INBOUND_PORTS="*"
        $ export ISTIO_LOCAL_EXCLUDE_PORTS="15090,15021,15020"
        $ export PROV_CERT="/var/run/secrets/istio"
        $ export OUTPUT_CERTS="/var/run/secrets/istio"
    {{< /text >}}
1. Restart the istio 
    {{< text bash >}}
        $ sudo -E /usr/local/bin/istio-start.sh
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

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
This guide is tested and validated but note that VM support is still an alpha feature not recommended for production.
{{< /tip >}}

## Prerequisites

1. [Download the Istio release](/docs/setup/getting-started/#download)
1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/)
1. Check the requirements [for Pods and Services](/docs/ops/deployment/requirements/)
1. Virtual machines must have IP connectivity to the ingress gateway in the connecting mesh, and optionally every pod in the mesh via L3 networking if enhanced performance is desired.

## Prepare the guide environment

1. Create a virtual machine
1. Set the environment variables `VM_APP`, `WORK_DIR` , `VM_NAMESPACE`,
and `SERVICE_ACCOUNT`
    (e.g., `WORK_DIR="${HOME}/vmintegration"`):

    {{< text bash >}}
    $ VM_APP="<the name of the application this VM will run>"
    $ VM_NAMESPACE="<the name of your service namespace>"
    $ WORK_DIR="<a certificate working directory>"
    $ SERVICE_ACCOUNT="<name of the Kubernetes service account you want to use for your VM>"
    $ NETWORK="<this can be left blank for single-network installations>"
    {{< /text >}}

1. Create the working directory:

    {{< text bash >}}
    $ mkdir -p "${WORK_DIR}"
    {{< /text >}}

## Install the Istio control plane

Install Istio and expose the control plane so that your virtual machine can access it.

1. Install Istio.

    {{< tabset category-name="registration-mode" >}}

    {{< tab name="Default" category-value="default" >}}

    {{< text bash >}}
    $ istioctl install
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Automated WorkloadEntry Creation" category-value="autoreg" >}}

    {{< warning >}}
    This feature is actively in [development](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md) and is
    considered `pre-alpha`.
    {{< /warning >}}

    {{< text bash >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Deploy the east-west gateway:

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ --single-cluster | istioctl install -y -f -
    {{< /text >}}

{{< warning >}}
If the control-plane was installed with a revision, add the `--revision rev` flag to the `gen-eastwest-gateway.sh` command.
{{< /warning >}}

1. Expose the control plane using the provided sample configuration:

    {{< text bash >}}
    $ kubectl apply -f @samples/multicluster/expose-istiod.yaml@
    {{< /text >}}

## Configure the VM namespace

1. Create the namespace that will host the virtual machine:

    {{< text bash >}}
    $ kubectl create namespace "${VM_NAMESPACE}"
    {{< /text >}}

1. Create a serviceaccount for the virtual machine:

    {{< text bash >}}
    $ kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"
    {{< /text >}}

## Create files to transfer to the virtual machine

1. Create a template `WorkloadGroup` for the VM(s)

    {{< tabset category-name="registration-mode" >}}

    {{< tab name="Default" category-value="default" >}}

    {{< text bash >}}
    $ cat <<EOF > workloadgroup.yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: WorkloadGroup
    metadata:
      name: "${VM_APP}"
      namespace: "${VM_NAMESPACE}"
    spec:
      metadata:
        labels:
          app: "${VM_APP}"
      template:
        serviceAccount: "${SERVICE_ACCOUNT}"
        network: "${NETWORK}"
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Automated WorkloadEntry Creation" category-value="autoreg" >}}

    {{< warning >}}
    This feature is actively in [development](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md) and is
    considered `pre-alpha`.
    {{< /warning >}}

    1. Generate the `WorkloadGroup`:

    {{< text bash >}}
    $ cat <<EOF > workloadgroup.yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: WorkloadGroup
    metadata:
      name: "${VM_APP}"
      namespace: "${VM_NAMESPACE}"
    spec:
      metadata:
        labels:
          app: "${VM_APP}"
      template:
        serviceAccount: "${SERVICE_ACCOUNT}"
        network: "${NETWORK}"
    EOF
    {{< /text >}}

    1. Push the `WorkloadGroup` to the cluster:

    {{< text bash >}}
    $ kubectl --namespace ${VM_NAMESPACE} apply -f workloadgroup.yaml
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Use the `istioctl x workload entry` command to generate:
       * `cluster.env`: Contains metadata that identifies what namespace, service account, network CIDR and (optionally) what inbound ports to capture.
       * `istio-token`: A Kubernetes token used to get certs from the CA.
       * `mesh.yaml`: Provides additional Istio metadata including, network name, trust domain and other values.
       * `root-cert.pem`: The root certificate used to authenticate.
       * `hosts`: An addendum to `/etc/hosts` that the proxy will use to reach istiod for xDS.*

    {{< idea >}}
    A sophisticated option involves configuring DNS within the virtual
    machine to reference an external DNS server. This option is beyond
    the scope of this guide.
    {{< /idea >}}

    {{< tabset category-name="registration-mode" >}}

    {{< tab name="Default" category-value="default" >}}

    {{< text bash >}}
    $ istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}"
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Automated WorkloadEntry Creation" category-value="autoreg" >}}

    {{< warning >}}
    This feature is actively in [development](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md) and is
    considered `pre-alpha`.
    {{< /warning >}}

    {{< text bash >}}
    $ istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --autoregister
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

    {{< warning >}}
    When connecting a VM to a multicluster Istio mesh, you will need to add the `--clusterID` argument to
    the above command. Set the value to the name of the cluster corresponding to the `istioctl` context.
    {{< /warning >}}

## Configure the virtual machine

Run the following commands on the virtual machine you want to add to the Istio mesh:

1. Securely transfer the files from `"${WORK_DIR}"`
    to the virtual machine.  How you choose to securely transfer those files should be done with consideration for
    your information security policies. For convenience in this guide, transfer all of the required files to `"${HOME}"` in the virtual machine.

1. Install the root certificate at `/etc/certs`:

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp "${HOME}"/root-cert.pem /etc/certs/root-cert.pem
    {{< /text >}}

1. Install the token at `/var/run/secrets/tokens`:

    {{< text bash >}}
    $ sudo  mkdir -p /var/run/secrets/tokens
    $ sudo cp "${HOME}"/istio-token /var/run/secrets/tokens/istio-token
    {{< /text >}}

1. Install the package containing the Istio virtual machine integration runtime:

    {{< tabset category-name="vm-os" >}}

    {{< tab name="Debian" category-value="debian" >}}

    {{< text bash >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="CentOS" category-value="centos" >}}

    {{< text bash >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/rpm/istio-sidecar.rpm
    $ sudo rpm -i istio-sidecar.rpm
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Install `cluster.env` within the directory `/var/lib/istio/envoy/`:

    {{< text bash >}}
    $ sudo cp "${HOME}"/cluster.env /var/lib/istio/envoy/cluster.env
    {{< /text >}}

1. Install the [Mesh Config](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) to `/etc/istio/config/mesh`:

    {{< text bash >}}
    $ sudo cp "${HOME}"/mesh.yaml /etc/istio/config/mesh
    {{< /text >}}

1. Add the istiod host to `/etc/hosts`:

    {{< text bash >}}
    $ sudo sh -c 'cat $(eval echo ~$SUDO_USER)/hosts >> /etc/hosts'
    {{< /text >}}

1. Transfer ownership of the files in `/etc/certs/` and `/var/lib/istio/envoy/` to the Istio proxy:

    {{< text bash >}}
    $ sudo mkdir -p /etc/istio/proxy
    $ sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem
    {{< /text >}}

## Start Istio within the virtual machine

1. Start the Istio agent:

    {{< text bash >}}
    $ sudo systemctl start istio
    {{< /text >}}

## Verify Istio Works Successfully

1. Check the log in `/var/log/istio/istio.log`. You should see entries similar to the following:

    {{< text bash >}}
    $ 2020-08-21T01:32:17.748413Z info sds resource:default pushed key/cert pair to proxy
    $ 2020-08-21T01:32:20.270073Z info sds resource:ROOTCA new connection
    $ 2020-08-21T01:32:20.270142Z info sds Skipping waiting for gateway secret
    $ 2020-08-21T01:32:20.270279Z info cache adding watcher for file ./etc/certs/root-cert.pem
    $ 2020-08-21T01:32:20.270347Z info cache GenerateSecret from file ROOTCA
    $ 2020-08-21T01:32:20.270494Z info sds resource:ROOTCA pushed root cert to proxy
    $ 2020-08-21T01:32:20.270734Z info sds resource:default new connection
    $ 2020-08-21T01:32:20.270763Z info sds Skipping waiting for gateway secret
    $ 2020-08-21T01:32:20.695478Z info cache GenerateSecret default
    $ 2020-08-21T01:32:20.695595Z info sds resource:default pushed key/cert pair to proxy
    {{< /text >}}

1. Create a Namespace to deploy a Pod-based Service:

    {{< text bash >}}
    $ kubectl create namespace sample
    $ kubectl label namespace sample istio-injection=enabled
    {{< /text >}}

1. Deploy the `HelloWorld` Service:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@
    {{< /text >}}

1. Send requests from your Virtual Machine to the Service:

    {{< text bash >}}
    $ curl helloworld.sample.svc:5000/hello
    Hello version: v1, instance: helloworld-v1-578dd69f69-fxwwk
    {{< /text >}}

## Uninstall

Stop Istio on the virtual machine:

{{< text bash >}}
$ sudo systemctl stop istio
{{< /text >}}

Then, remove the Istio-sidecar package:

{{< tabset category-name="vm-os" >}}

{{< tab name="Debian" category-value="debian" >}}

{{< text bash >}}
$ sudo dpkg -r istio-sidecar
$ dpkg -s istio-sidecar
{{< /text >}}

{{< /tab >}}

{{< tab name="CentOS" category-value="centos" >}}

{{< text bash >}}
$ sudo rpm -e istio-sidecar
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

To uninstall Istio, run the following command:

{{< text bash >}}
$ kubectl delete -f @samples/multicluster/expose-istiod.yaml@
$ istioctl manifest generate | kubectl delete -f -
{{< /text >}}

The control plane namespace (e.g., `istio-system`) is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

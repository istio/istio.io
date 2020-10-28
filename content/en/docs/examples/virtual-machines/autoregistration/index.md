---
title: Automated Workload Entry Creation [experimental]
description: Learn how to use the experimental automated VM registration feature.
  Istio mesh.
weight: 20
keywords:
- kubernetes
- vms
- virtual-machines
owner: istio/wg-environments-maintainers
test: no
---

{{< warning >}}
This feature is actively in [development](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md) and is
considered `pre-alpha`.
{{< /warning >}}

Istio 1.8 introduces a new configuration resource, [Workload Group](/docs/reference/config/networking/workload-group/), that can be used to automate
the creation of [Workload Entries](/docs/reference/config/networking/workload-entry/).
This example shows how to use a `WorkloadGroup` to integrate a virtual machine, or a bare metal host into a
single network Istio mesh deployed on Kubernetes without manual `WorkloadEntry` creation. This approach requires L3 connectivity
between the virtual machine, and the Kubernetes cluster.

## Prerequisites

- One or more Kubernetes clusters with versions: {{< supported_kubernetes_versions >}}.

- Virtual machines must have L3 IP connectivity to the endpoints in the mesh.
  This typically requires a VPC or a VPN, as well as a container network that
  provides direct (without NAT or firewall deny) routing to the endpoints. The
  machine is not required to have access to the cluster IP addresses assigned by
  Kubernetes.

- Installation must be completed using [virtual machine installation](/docs/setup/install/virtual-machine) instructions.

## Prepare the guide environment

Set the environment variables `VM_NAMESPACE` and `SERVICE_ACCOUNT` (use the same values as during the installation guide):

{{< text bash >}}
$ VM_NAMESPACE="<the name of your service namespace>"
$ SERVICE_ACCOUNT="<name of the Kubernetes service account you want to use for your VM>"
{{< /text >}}

### Running services on the virtual machine

1. Setup an HTTP server on the virtual machine to serve HTTP traffic on port 8080:

    {{< text bash >}}
    $ python -m SimpleHTTPServer 8080
    {{< /text >}}

    {{< warning >}}
    You may have to open firewalls to be able to access the 8080 port on your virtual machine
    {{< /warning >}}

1. Add an associated Service to the mesh:

    {{< text bash >}}
    $ cat <<EOF | kubectl -n "${VM_NAMESPACE}" apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: auto-cloud-vm
      labels:
        app: auto-cloud-vm
    spec:
      ports:
      - port: 8080
        name: http
        targetPort: 8080
      selector:
        app: auto-cloud-vm
    EOF
    {{< /text >}}

## Configure VM for Auto-Registration

1. Create the auto-registration group.

    `WorkloadGroup`provides a template to automatically create a `WorkloadEntry`for each connected VM instance.

    {{< text bash >}}
    $ cat <<EOF | kubectl -n "${VM_NAMESPACE}" apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: WorkloadGroup
    metadata:
      name: auto-cloud-vm
    spec:
      template:
        serviceAccount: vm-sa
        labels:
          app: auto-cloud-vm
    EOF
    {{< /text >}}

1. The proxy must provide enough the name and namespace to find the `WorkloadGroup`on connection.

    While logged on to the Virtual Machine:

    {{< text bash >}}
    $ sudo echo "ISTIO_NAMESPACE=${VM_NAMESPACE}" >> /var/lib/istio/envoy/sidecar.env
    $ sudo echo "ISTIO_META_AUTO_REGISTER_GROUP=auto-cloud-vm" >> /var/lib/istio/envoy/sidecar.env
    {{< /text >}}

1. Reconnect with new configuration.

    {{< text bash >}}
    $ sudo systemctl restart istio
    {{< /text >}}

## Verify

1. If successful, a new `WorkloadEntry`should exist in your `${VM_NAMESPACE}`:

    {{< text bash >}}
    $ kubectl -n "${VM_NAMESPACE}" get workloadentry
    NAME                          AGE   ADDRESS
    auto-cloud-vm-10.128.15.202   11s   10.128.15.202
    {{< /text >}}

1. Deploy a pod running the `sleep` service in the Kubernetes cluster, and wait until it is ready:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl get pod
    NAME                             READY     STATUS    RESTARTS   AGE
    sleep-88ddbcfdd-rm42k            2/2       Running   0          1s
    ...
    {{< /text >}}

1. Send a request from the `sleep` service on the pod to the virtual machine:

    {{< text bash >}}
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl auto-cloud-vm.${VM_NAMESPACE}.svc.cluster.local:8080
    {{< /text >}}

    You will see output similar to this:

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
the configuration worked. Adding additional VMs will only require setting up the proxy, including configuring it with
the `WorkloadGroup`and Namespace.

## Cleanup

At this point, you can remove the virtual machine resources from the Kubernetes cluster in the `<vm-namespace>` namespace.
Removing the `WorkloadGroup`will not delete associated `WorkloadEntry`resources. Even without deleting the `WorkloadGroup`,
simply shutdown the `istio` service on the VM, or tear down the VM entirely. After a short grace period, the `WorkloadEntry`will be cleaned up
automatically.

---
title: Example Application using Virtual Machines in a Single Network Mesh
description: Learn how to add a service running on a virtual machine to your single-network
  Istio mesh.
weight: 20
keywords:
- kubernetes
- vms
- virtual-machines
aliases:
- /docs/setup/kubernetes/additional-setup/mesh-expansion/
- /docs/examples/mesh-expansion/single-network
- /docs/tasks/virtual-machines/single-network
owner: istio/wg-environments-maintainers
test: no
---

This example provides instructions to integrate a virtual machine or a bare metal host into a
single network Istio mesh deployed on Kubernetes. This approach requires L3 connectivity
between the virtual machine and the Kubernetes cluster.

## Prerequisites

- One or more Kubernetes clusters with versions: {{< supported_kubernetes_versions >}}.

- Virtual machines must have L3 IP connectivity to the endpoints in the mesh.
  This typically requires a VPC or a VPN, as well as a container network that
  provides direct (without NAT or firewall deny) routing to the endpoints. The
  machine is not required to have access to the cluster IP addresses assigned by
  Kubernetes.

- Installation must be completed using [virtual machine installation](/docs/setup/install/virtual-machine) instructions.

## Verify installation

After installation, the virtual machine can access services running in the Kubernetes cluster or in
other virtual machines. To verify the virtual machine connectivity, run the following command
(assuming you have a service named `httpbin` on the Kubernetes cluster:

{{< text bash >}}
$ curl -v localhost:15000/clusters | grep httpbin
{{< /text >}}

This shows endpoints for `httpbin`:

{{< text text >}}
outbound|8000||httpbin.default.svc.cluster.local::34.72.46.113:443::cx_active::1
outbound|8000||httpbin.default.svc.cluster.local::34.72.46.113:443::cx_connect_fail::0
outbound|8000||httpbin.default.svc.cluster.local::34.72.46.113:443::cx_total::1
outbound|8000||httpbin.default.svc.cluster.local::34.72.46.113:443::rq_active::0
{{< /text >}}

The IP `34.72.46.113` in this case is the pod IP address of the httpbin endpoint.

### Send requests from virtual machine workloads to Kubernetes services

You can send traffic to `httpbin.default.svc.cluster.local` and get a response from the server. You must configure DNS in `/etc/hosts` to map the `httpbin.default.svc.cluster.local` domain name to an IP, or the IP will not resolve. In this case, the IP should be an IP that is routed over the single network using L3 connectivity. You should use the IP of the service in the Kubernetes cluster.

{{< text bash >}}
$ curl -v httpbin.default.svc.cluster.local:8000/headers
{{< /text >}}

### Running services on the virtual machine

1. Setup an HTTP server on the virtual machine to serve HTTP traffic on port 8080:

    {{< text bash >}}
    $ python -m SimpleHTTPServer 8080
    {{< /text >}}

    {{< warning >}}
    You may have to open firewalls to be able to access the 8080 port on your virtual machine
    {{< /warning >}}

1. Add virtual machine services to the mesh

    Add a service to the Kubernetes cluster into a namespace (in this example, `<vm-namespace>`) where you prefer to keep resources (like `Service`, `ServiceEntry`, `WorkloadEntry`, `ServiceAccount`) with the virtual machine services:

    {{< text bash >}}
    $ cat <<EOF | kubectl -n <vm-namespace> apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: cloud-vm
      labels:
        app: cloud-vm
    spec:
      ports:
      - port: 8080
        name: http-vm
        targetPort: 8080
      selector:
        app: cloud-vm
    EOF
    {{< /text >}}

    Create a `WorkloadEntry` with the external IP of the virtual machine. Substitute `VM_IP` with the IP of your virtual machine:

    {{< text bash >}}
    $ cat <<EOF | kubectl -n <vm-namespace> apply -f -
    apiVersion: networking.istio.io/v1beta1
    kind: WorkloadEntry
    metadata:
      name: "cloud-vm"
      namespace: "<vm-namespace>"
    spec:
      address: "${VM_IP}"
      labels:
        app: cloud-vm
      serviceAccount: "<service-account>"
    EOF
    {{< /text >}}

1. Deploy a pod running the `sleep` service in the Kubernetes cluster, and wait until it is ready:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl get pod
    NAME                             READY     STATUS    RESTARTS   AGE
    sleep-88ddbcfdd-rm42k            2/2       Running   0          1s
    ...
    {{< /text >}}

1. Send a request from the `sleep` service on the pod to the virtual machine HTTP service:

    {{< text bash >}}
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl cloud-vm.${VM_NAMESPACE}.svc.cluster.local:8080
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
the configuration worked.

## Cleanup

At this point, you can remove the virtual machine resources from the Kubernetes cluster in the `<vm-namespace>` namespace.

## Troubleshooting

The following are some basic troubleshooting steps for common VM-related issues.

- When making requests from a VM to the cluster, ensure you don't run the requests as `root` or
  `istio-proxy` user. By default, Istio excludes both users from interception.

- Verify the machine can reach the IP of the all workloads running in the cluster. For example:

    {{< text bash >}}
    $ kubectl get endpoints productpage -o jsonpath='{.subsets[0].addresses[0].ip}'
    10.52.39.13
    {{< /text >}}

    {{< text bash >}}
    $ curl 10.52.39.13:9080
    html output
    {{< /text >}}

- Check the status of the Istio Agent and sidecar:

    {{< text bash >}}
    $ sudo systemctl status istio
    {{< /text >}}

- Check that the processes are running. The following is an example of the processes you should see on the VM if you run
  `ps`, filtered for `istio`:

    {{< text bash >}}
    $ ps aux | grep istio
    root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=vm exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
    istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
    istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.vm-vm.svc.cluster.local
    {{< /text >}}

- Check the Envoy access and error logs for failures:

    {{< text bash >}}
    $ tail /var/log/istio/istio.log
    $ tail /var/log/istio/istio.err.log
    {{< /text >}}

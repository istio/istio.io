---
title: Examples of using virtual machine integration with Istio
description: Send and receive messages, use Bookinfo application with a MySQL service running on a virtual
  machine within your mesh.
weight: 60
keywords:
- virtual-machine
- vms
aliases:
- /docs/examples/integrating-vms/
- /docs/examples/mesh-expansion/bookinfo-expanded
- /docs/examples/vm-bookinfo
---

## Send requests from VM workloads to Kubernetes services

After setup, the machine can access services running in the Kubernetes cluster
or on other VMs.

The following example shows accessing a service running in the Kubernetes cluster from a VM using
`/etc/hosts/`, in this case using a service from the [Bookinfo example](/docs/examples/bookinfo/).

1.  First, on the cluster admin machine get the virtual IP address (`clusterIP`) for the service:

    {{< text bash >}}
    $ kubectl get svc productpage -o jsonpath='{.spec.clusterIP}'
    10.55.246.247
    {{< /text >}}

1.  Then on the added VM, add the service name and address to its `etc/hosts`
    file. You can then connect to the cluster service from the VM, as in the
    example below:

    {{< text bash >}}
$ echo "10.55.246.247 productpage.default.svc.cluster.local" | sudo tee -a /etc/hosts
$ curl -v productpage.default.svc.cluster.local:9080
< HTTP/1.1 200 OK
< content-type: text/html; charset=utf-8
< content-length: 1836
< server: envoy
... html content ...
    {{< /text >}}

The `server: envoy` header indicates that the sidecar intercepted the traffic.

## Running services on the added VM

1. Setup an HTTP server on the VM instance to serve HTTP traffic on port 8080:

    {{< text bash >}}
    $ gcloud compute ssh ${GCE_NAME}
    $ python -m SimpleHTTPServer 8080
    {{< /text >}}

1. Determine the VM instance's IP address. For example, find the IP address
    of the GCE instance with the following commands:

    {{< text bash >}}
    $ export GCE_IP=$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances describe ${GCE_NAME})
    $ echo ${GCE_IP}
    {{< /text >}}

1. Add VM services to the mesh

    {{< text bash >}}
    $ istioctl experimental add-to-mesh external-service vmhttp ${VM_IP} http:8080 -n ${SERVICE_NAMESPACE}
    {{< /text >}}

    {{< tip >}}
    Ensure you have added the `istioctl` client to your path, as described in the [download page](/docs/setup/getting-started/#download).
    {{< /tip >}}

1. Deploy a pod running the `sleep` service in the Kubernetes cluster, and wait until it is ready:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl get pod
    NAME                             READY     STATUS    RESTARTS   AGE
    sleep-88ddbcfdd-rm42k            2/2       Running   0          1s
    ...
    {{< /text >}}

1. Send a request from the `sleep` service on the pod to the VM's HTTP service:

    {{< text bash >}}
    $ kubectl exec -it sleep-88ddbcfdd-rm42k -c sleep -- curl vmhttp.${SERVICE_NAMESPACE}.svc.cluster.local:8080
    {{< /text >}}

    You should see something similar to the output below.

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

Run the following commands to remove the expansion VM from the mesh's abstract
model.

{{< text bash >}}
$ istioctl experimental remove-from-mesh -n ${SERVICE_NAMESPACE} vmhttp
Kubernetes Service "vmhttp.vm" has been deleted for external service "vmhttp"
Service Entry "mesh-expansion-vmhttp" has been deleted for external service "vmhttp"
{{< /text >}}

## Troubleshooting

The following are some basic troubleshooting steps for common VM-related issues.

-    When making requests from a VM to the cluster, ensure you don't run the requests as `root` or
    `istio-proxy` user. By default, Istio excludes both users from interception.

-    Verify the machine can reach the IP of the all workloads running in the cluster. For example:

    {{< text bash >}}
    $ kubectl get endpoints productpage -o jsonpath='{.subsets[0].addresses[0].ip}'
    10.52.39.13
    {{< /text >}}

    {{< text bash >}}
    $ curl 10.52.39.13:9080
    html output
    {{< /text >}}

-    Check the status of the Istio Agent and sidecar:

    {{< text bash >}}
    $ sudo systemctl status istio
    {{< /text >}}

-    Check that the processes are running. The following is an example of the processes you should see on the VM if you run
     `ps`, filtered for `istio`:

    {{< text bash >}}
    $ ps aux | grep istio
    root      6955  0.0  0.0  49344  3048 ?        Ss   21:32   0:00 su -s /bin/bash -c INSTANCE_IP=10.150.0.5 POD_NAME=demo-vm-1 POD_NAMESPACE=vm exec /usr/local/bin/pilot-agent proxy > /var/log/istio/istio.log istio-proxy
    istio-p+  7016  0.0  0.1 215172 12096 ?        Ssl  21:32   0:00 /usr/local/bin/pilot-agent proxy
    istio-p+  7094  4.0  0.3  69540 24800 ?        Sl   21:32   0:37 /usr/local/bin/envoy -c /etc/istio/proxy/envoy-rev1.json --restart-epoch 1 --drain-time-s 2 --parent-shutdown-time-s 3 --service-cluster istio-proxy --service-node sidecar~10.150.0.5~demo-vm-1.vm-vm.svc.cluster.local
    {{< /text >}}

-    Check the Envoy access and error logs:

    {{< text bash >}}
    $ tail /var/log/istio/istio.log
    $ tail /var/log/istio/istio.err.log
    {{< /text >}}
This example deploys the Bookinfo application across Kubernetes with one
service running on a virtual machine (VM), and illustrates how to control
this infrastructure as a single mesh.

{{< warning >}}
This example is still under development and only tested on Google Cloud Platform.
On IBM Cloud or other platforms where overlay network of Pods is isolated from VM network,
VMs cannot initiate any direct communication to Kubernetes Pods even when using Istio.
{{< /warning >}}

## Overview

{{< image width="80%" link="./vm-bookinfo.svg" caption="Bookinfo running on VMs" >}}

<!-- source of the drawing
https://docs.google.com/drawings/d/1G1592HlOVgtbsIqxJnmMzvy6ejIdhajCosxF1LbvspI/edit
 -->

## Before you begin

- Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/getting-started/).

- Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application (in the `bookinfo` namespace).

- Create a VM named 'vm-1' in the same project as the Istio cluster, and [join the mesh](/docs/examples/virtual-machines/single-network/).

## Running MySQL on the VM

We will first install MySQL on the VM, and configure it as a backend for the ratings service.

On the VM:

{{< text bash >}}
$ sudo apt-get update && sudo apt-get install -y mariadb-server
$ sudo mysql
# Grant access to root
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
quit;
{{< /text >}}

{{< text bash >}}
$ sudo systemctl restart mysql
{{< /text >}}

You can find details of configuring MySQL at [Mysql](https://mariadb.com/kb/en/library/download/).

On the VM add ratings database to mysql.

{{< text bash >}}
$ curl -q {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | mysql -u root -ppassword
{{< /text >}}

To make it easy to visually inspect the difference in the output of the Bookinfo application, you can change the ratings that are generated by using the
following commands to inspect the ratings:

{{< text bash >}}
$ mysql -u root -password test -e "select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      5 |
|        2 |      4 |
+----------+--------+
{{< /text >}}

and to change the ratings

{{< text bash >}}
$ mysql -u root -ppassword test -e  "update ratings set rating=1 where reviewid=1;select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      1 |
|        2 |      4 |
+----------+--------+
 {{< /text >}}

## Find out the IP address of the VM that will be used to add it to the mesh

On the VM:

{{< text bash >}}
$ hostname -I
{{< /text >}}

## Registering the mysql service with the mesh

On a host with access to [`istioctl`](/docs/reference/commands/istioctl) commands, register the VM and mysql db service

{{< text bash >}}
$ istioctl register -n vm mysqldb <ip-address-of-vm> 3306
I1108 20:17:54.256699   40419 register.go:43] Registering for service 'mysqldb' ip '10.150.0.5', ports list [{3306 mysql}]
I1108 20:17:54.256815   40419 register.go:48] 0 labels ([]) and 1 annotations ([alpha.istio.io/kubernetes-serviceaccounts=default])
W1108 20:17:54.573068   40419 register.go:123] Got 'services "mysqldb" not found' looking up svc 'mysqldb' in namespace 'vm', attempting to create it
W1108 20:17:54.816122   40419 register.go:138] Got 'endpoints "mysqldb" not found' looking up endpoints for 'mysqldb' in namespace 'vm', attempting to create them
I1108 20:17:54.886657   40419 register.go:180] No pre existing exact matching ports list found, created new subset {[{10.150.0.5  <nil> nil}] [] [{mysql 3306 }]}
I1108 20:17:54.959744   40419 register.go:191] Successfully updated mysqldb, now with 1 endpoints
{{< /text >}}

Note that the 'mysqldb' virtual machine does not need and should not have special Kubernetes privileges.

## Using the mysql service

The ratings service in Bookinfo will use the DB on the machine. To verify that it works, create version 2 of the ratings service that uses the mysql db on the VM. Then specify route rules that force the review service to use the ratings version 2.

{{< text bash >}}
$ istioctl kube-inject -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml@ | kubectl apply -n bookinfo -f -
{{< /text >}}

Create route rules that will force Bookinfo to use the ratings back end:

{{< text bash >}}
$ kubectl apply -n bookinfo -f @samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml@
{{< /text >}}

You can verify the output of the Bookinfo application is showing 1 star from Reviewer1 and 4 stars from Reviewer2 or change the ratings on your VM and see the
results.

You can also find some troubleshooting and other information in the [RawVM MySQL]({{< github_blob >}}/samples/rawvm/README.md) document in the meantime.

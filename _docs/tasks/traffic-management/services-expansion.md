---
title: Accessing Services in Mesh Extensions
overview: This task shows you how to use services provided by VM

order: 10

draft: true
layout: docs
type: markdown
redirect_from: "/docs/tasks/extension_services.html"
---
{% include home.html %}

This task shows you how to configure services running in a VM that joined the cluster.

Current task was tested on GCP - WIP on adding specific info for other clusters.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](({{home}}/docs/setup/).

* Deploy the [BookInfo]({{home}}/docs/samples/bookinfo.html) sample application.

* Create a VM named 'db' in the same project as Istio cluster, and [Join the Mesh]({{home}}/docs/setup/kubernetes/mesh-expansion.html).

## Running mysql on the VM

We will first install mysql on the VM, and configure it as a backend for the ratings service.

On the VM:
```bash
  db$ sudo apt-get update && apt-get install ...
  [ copy from the test script ]
```

## Registering the mysql service with the mesh

 ### Machine admin
First step is to configure the VM sidecar, by adding the service port and restarting the sidecar.

```bash

  db$ sudo echo "ISTIO_INBOUND_PORTS=..." > /var/lib/istio/envoy/sidecar.env
  db$ sudo chown istio-proxy /var/lib/istio/envoy/sidecar.env
  db$ sudo systemctl restart istio

 # Or
  db$ sudo istio-pilot vi /var/lib/istio/envoy/sidecar.env
  # add mysql port to the "ISTIO_INBOUND_PORTS" config

  ```

  ###  Cluster admin

  If you previously run the mysql bookinfo on kubernetes, you need to remove the k8s mysql service:

  ```bash
  admin$ kubectl delete service mysql
  ```

  Run istioctl to configure the service:

  ```bash
  admin$ istioctl register mysql PORT IP
  ```

  Note that the 'db' machine does not need and should not have special kubernetes priviledges.

## Registering the mongodb service with the mesh

 In progress...

## USing the mysql service

The ratings service in bookinfo will use the DB on the machine. To verify it works, you can
modify the ratings value on the database.

```bash
  db$ ...
```

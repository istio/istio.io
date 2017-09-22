---
title: Intelligent Routing
overview: This sample demonstrates how to use various traffic management capabilities of Istio service mesh running on Kubernetes.

order: 20

layout: docs
type: markdown
draft: false
---
{% include home.html %}

This sample demonstrates how to use various traffic management capabilities
of Istio service mesh running on Kubernetes.

## Before you begin
* Describe installation options.

* Install Istio control plane in a Kubernetes cluster by following the quick start instructions in the
[Installation guide]({{home}}/docs/setup/install-kubernetes.html).

## Overview

Placeholder.

## Application Setup

1. Steps

## Tasks

1. [Request routing]({{home}}/docs/tasks/request-routing.html).

1. [Fault injection]({{home}}/docs/tasks/fault-injection.html).

## Cleanup

When you're finished experimenting with the BookInfo sample, you can
uninstall it as follows in a Kubernetes environment:

1. Delete the routing rules and terminate the application pods

   ```bash
   samples/bookinfo/kube/cleanup.sh
   ```

1. Confirm shutdown

   ```bash
   istioctl get route-rules   #-- there should be no more routing rules
   kubectl get pods           #-- the BookInfo pods should be deleted
   ```

If you are using the Docker Compose version of the demo, run the following
command to clean up:

  ```bash
  docker-compose -f samples/bookinfo/consul/docker-compose.yaml down
  ```


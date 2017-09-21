---
title: Istio with Consul
overview: This sample deploys the Bookinfo application in a simple Docker Compose environment using Consul as the service registry, and demonstrates various features of the Istio service mesh on non-kubernetes platforms.

order: 60

layout: docs
type: markdown
draft: false
---
{% include home.html %}

This sample deploys the Bookinfo application in a simple Docker Compose environment using Consul as the service registry, and demonstrates various features of the Istio service mesh on non-kubernetes platforms.

## Before you begin
* Setup Istio by following the instructions in the [Installation guide]({{home}}/docs/setup/install-kubernetes.html).
  You will need `kubectl` and Steps 1-4 from `Installation step` only for this Task.

* Install [Docker](https://docs.docker.com/engine/installation/#cloud) and 
  [Docker-Compose](https://docs.docker.com/compose/install/)

## Overview

This sample deploys the [BookInfo]({{home}}/docs/samples/bookinfo.html) application. The Consul platform 
adapter uses Consul Server to help Istio monitor service instances running in the underlying platform. 
When a service instance is brought up in docker, the [Registrator](http://gliderlabs.github.io/registrator/latest/) 
automatically registers the service in Consul.

Note that Istio pilot agent is running inside each app container so as to coordinate Envoy and the service mesh.

## Application Setup

1. First step is to generate a configuration file which will be used by `istioctl` and Istio Discovery

    ```bash
    kubectl config set-cluster local --server=http://172.28.0.13:8080
    kubectl config set-context local --cluster=local
    kubectl config use-context local
    ```
    
1. Change directory to the root of the Istio installation directory.

1. Bring up the application containers in docker:

    ```bash
    docker-compose -f samples/bookinfo/consul/docker-compose.yaml up -d
    ```
    
1. Confirm all docker containers are running:

   ```bash
   docker ps -a
   ```

    If the `discovery` service is `Exited` you may need to re-run the command from the previous step to resolve a 
    timing issue.
    
1. View the Bookinfo Webpage.

    Open a web browser and enter `localhost:9081/productpage`.  If you refresh the page several times, you 
    should see different versions of reviews shown in productpage presented in a round robin style 
    (red stars, black stars, no stars). If the webpage is not displaying properly, please repeat the previous
    to verify all containers are running.

## Tasks

1. [Request routing]({{home}}/docs/tasks/request-routing.html).

## Cleaning up

Remove all docker containers:

  ```bash
  docker-compose -f samples/bookinfo/consul/docker-compose.yaml down
  ```

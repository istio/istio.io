---
title: Istio with Consul
overview: This sample deploys the Bookinfo application in a simple Docker Compose environment using Consul as the service registry, and demonstrates various features of the Istio service mesh on non-kubernetes platforms.

order: 60

layout: docs
type: markdown
draft: false
---
{% include home.html %}

This sample deploys the Bookinfo application in a simple Docker Compose
environment using Consul as the service registry, and demonstrates various
features of the Istio service mesh on non-kubernetes platforms.

## Before you begin

* Install [Docker](https://docs.docker.com/engine/installation/#cloud) and 
  [Docker-Compose](https://docs.docker.com/compose/install/)

## Overview

For the purposes of illustration, this sample deploys the Istio control
plane and the [BookInfo]({{home}}/docs/samples/bookinfo.html) application
in a simple Docker Compose based setup. Since there is no concept of pods
in a Docker setup, the Istio sidecar runs in the same container as the
application.  We will use
[Registrator](http://gliderlabs.github.io/registrator/latest/) to
automatically register instances of services in the Consul service registry.

## Setup

1. Go to the [Istio release](https://github.com/istio/istio/releases) page,
   to download the installation file corresponding to your OS. Alternatively,
   run the following command to download and extract the latest stable release
   automatically (on MacOS and Ubuntu).

   ```bash
   curl -L https://git.io/getIstio | sh -
    ```

1. Extract the installation file, and change directory to the location
   where the files were extracted. The following instructions are relative
   to this installation directory. The installation directory contains:
    * Sample applications in `samples/`
    * The `istioctl` client binary in the `bin/` directory. `istioctl` is used for creating routing rules and policies.
    * The `istio.VERSION` configuration file.

1. Add the `istioctl` client to your PATH.
   For example, run the following commands on a Linux or MacOS system:

   ```bash
   export PATH=$PWD/bin:$PATH
   ```

1. Generate a configuration file which will be used by `istioctl` and Istio Pilot

    ```bash
    istioctl context-create --api-server http://172.28.0.13:8080
    ```

1. Change directory to the root of the Istio installation directory.

1. Bring up the Istio control plane and the application containers:

    ```bash
    docker-compose -f samples/bookinfo/consul/docker-compose.yaml up -d
    ```
    
1. Confirm that all docker containers are running:

   ```bash
   docker ps -a
   ```

   > If the `Istio-Pilot` container terminates, re-run the command from the previous step.
    
1. View the Bookinfo web page at `http://localhost:9081/productpage`. If
    you refresh the page several times, you should see different versions
    of reviews shown in productpage presented in a round robin style (red
    stars, black stars, no stars).

## Tasks

1. [Request routing]({{home}}/docs/tasks/request-routing.html).

## Cleaning up

Remove all docker containers:

  ```bash
  docker-compose -f samples/bookinfo/consul/docker-compose.yaml down
  ```

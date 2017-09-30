---
title: Quick Start on Docker
overview: Quick Start instructions to setup the Istio service mesh with Docker Compose.

order: 10

layout: docs
type: markdown
---

{% include home.html %}

Quick Start instructions to install and configure Istio in a Docker Compose setup.


## Prerequisites

* [Docker](https://docs.docker.com/engine/installation/#cloud)
* [Docker-Compose](https://docs.docker.com/compose/install/)

## Installation steps

1. Go to the [Istio release](https://github.com/istio/istio/releases) page to download the
   installation file corresponding to your OS. If you are using a MacOS or Linux system, you can also
   run the following command to download and extract the latest release automatically:
   ```bash
   curl -L https://git.io/getLatestIstio | sh -
   ```

1. Extract the installation file and change the directory to the file location. The
   installation directory contains:
    * Sample applications in `samples/`
    * The `istioctl` client binary in the `bin/` directory. `istioctl` is used for creating routing rules and policies.
    * The `istio.VERSION` configuration file

1. Add the `istioctl` client to your PATH.
   For example, run the following command on a MacOS or Linux system:

   ```bash
   export PATH=$PWD/bin:$PATH
   ```

1. Generate a configuration file which will be used by `istioctl` and Istio Pilot

    ```bash
    istioctl context-create --api-server http://172.28.0.13:8080
    ```

1. Change directory to the root of the Istio installation directory.

1. Bring up the Istio control plane containers:

    ```bash
    docker-compose -f install/consul/istio.yaml up -d
    ```

1. Confirm that all docker containers are running:

   ```bash
   docker ps -a
   ```

   > If the `Istio-Pilot` container terminates, re-run the command from the previous step.
    

## Deploy your application

You can now deploy your own application or one of the sample applications provided with the
installation like [BookInfo]({{home}}/docs/guides/bookinfo.html).

> Note 1: Since there is no concept of pods in a Docker setup, the Istio
> sidecar runs in the same container as the application.  We will use 
> [Registrator](http://gliderlabs.github.io/registrator/latest/) to
> automatically register instances of services in the Consul service
> registry.

> Note 2: the application must use HTTP/1.1 or HTTP/2.0 protocol for all its HTTP traffic because HTTP/1.0 is not supported.

```bash
docker-compose -f <your-app-spec>.yaml up -d)
```

## Uninstalling

1. Uninstall Istio core components by removing the docker containers:

```bash
docker-compose -f install/consul/istio.yaml down
```

## What's next

* See the sample [BookInfo]({{home}}/docs/guides/bookinfo.html) application.

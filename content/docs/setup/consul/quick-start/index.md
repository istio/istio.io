---
title: Quick Start on Docker
description: Quick Start instructions to setup the Istio service mesh with Docker Compose.
weight: 10
keywords: [consul]
---

Quick Start instructions to install and configure Istio networking in a Docker Compose setup.

## Prerequisites

* [Docker](https://docs.docker.com/engine/installation/)
* [Docker Compose](https://docs.docker.com/compose/install/)

## Installation steps

1.  Go to the [Istio release](https://github.com/istio/istio/releases) page to download the
    installation file corresponding to your OS. If you are using a macOS or Linux system, you can also
    run the following command to download and extract the latest release automatically:

    {{< text bash >}}
    $ curl -L https://git.io/getLatestIstio | sh -
    {{< /text >}}

1.  Extract the installation file and change the directory to the file location. The
installation directory contains:

    * Sample applications in `samples/`
    * The `istioctl` client binary in the `bin/` directory. `istioctl` is used for some debug and diagnostics tasks.
    * The `istio.VERSION` configuration file

1.  Add the `istioctl` client to your PATH.
For example, run the following command on a macOS or Linux system:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

1. Install `kubectl` using [these instructions](https://kubernetes.io/docs/tasks/tools/install-kubectl).

`kubectl` is used to create, read, modify, and delete Istio API resources.

1.  For Linux users, configure the `DOCKER_GATEWAY` environment variable

    {{< text bash >}}
    $ export DOCKER_GATEWAY=172.28.0.1:
    {{< /text >}}

1. Change directory to the root of the Istio installation directory.

1.  Bring up the Istio networking control plane containers:

    {{< text bash >}}
    $ docker-compose -f install/consul/istio.yaml up -d
    {{< /text >}}

    > {{< warning_icon >}} The Consul install only configures Istio Pilot. To use Istio Mixer (policy enforcement and telemetry reporting) or Istio Galley, further installation steps
    > will be necessary. Those steps are beyond the scope of this guide.

1.  Confirm that all docker containers are running:

    {{< text bash >}}
    $ docker ps -a
    {{< /text >}}

    > If the Istio Pilot container terminates, ensure that you ran the `kubectl config` commands below and re-run the command from the previous step.

1.  Configure `kubectl` to use mapped local port for the API server:

    {{< text bash >}}
    $ kubectl config set-context istio --cluster=istio
    $ kubectl config set-cluster istio --server=http://localhost:8080
    $ kubectl config use-context istio
    {{< /text >}}

## Deploy your application

You can now deploy your own application or one of the sample applications provided with the
installation like [Bookinfo](/docs/examples/bookinfo/).

> Since there is no concept of pods in a Docker setup, the Istio
> sidecar runs in the same container as the application.  We will
> use [Registrator](https://gliderlabs.github.io/registrator/latest/) to
> automatically register instances of services in the Consul service
> registry.
>
> The application must use HTTP/1.1 or HTTP/2.0 protocol for all its HTTP traffic because HTTP/1.0 is not supported.

{{< text bash >}}
$ docker-compose -f <your-app-spec>.yaml up -d
{{< /text >}}

## Uninstalling

Uninstall Istio core components by removing the docker containers:

{{< text bash >}}
$ docker-compose -f install/consul/istio.yaml down
{{< /text >}}

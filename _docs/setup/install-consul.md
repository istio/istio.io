---
title: Istio Quick Start - Consul
overview: Quick Start instructions to setup the Istio service mesh in Consul-based infrastructure.

order: 30

layout: docs
type: markdown
---

This task shows how to install Istio in a non-kubernetes environment, where
Consul handles service registration. Unlike Kubernetes installation, there
is no one-stop installation script since there are several combinations of
the container orchestration platforms with Consul. For the purposes of
illustration, we focus on a simple Docker-based cluster with Consul.

_This document is under construction._

## Before you begin

* Setup Istio by following the instructions in the [Installation guide](./install-kubernetes.html).
  You will need `kubectl` and Steps 1-4 from `Installation step` only for this Task.

* Install [Docker](https://docs.docker.com/engine/installation/#cloud) and 
  [Docker-Compose](https://docs.docker.com/compose/install/)

## Overview

This sample deploys the [BookInfo]({{home}}/docs/samples/bookinfo.html) application. The Consul platform 
adapter uses Consul Server to help Istio monitor service instances running in the underlying platform. 
When a service instance is brought up in docker, the [Registrator](http://gliderlabs.github.io/registrator/latest/) 
automatically registers the service in Consul.

Note that Istio pilot agent is running inside each app container so as to coordinate Envoy and the service mesh.

## Start the Application

1. First step is to generate a configuration file which will be used by `istioctl` and Istio Discovery

    ```bash
    kubectl config set-cluster local --server=http://172.28.0.13:8080
    kubectl config set-context local --cluster=local
    kubectl config use-context local
    ```
    
1. Change directory to the root of the Istio installation directory.

1. Bring up the application containers in docker:

    ```bash
    docker-compose -f samples/apps/bookinfo/consul/docker-compose.yaml up -d
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
    
1. Create Route Rules

    * NOTE: Mac users will have to run the following commands first prior to creating a rule:

        ```bash
        kubectl config set-cluster mac --server=http://localhost:8080
        kubectl config set-context mac --cluster=mac
        kubectl config use-context mac
        ```

    Create a rule to display no stars by default:

    ```bash
    istioctl create -f samples/apps/bookinfo/consul/consul-reviews-v1.yaml
    ```
    
    Modify the previous rule to display red stars by default:

    ```bash
    istioctl replace -f samples/apps/bookinfo/consul/consul-reviews-v3.yaml
    ```

    Create a rule for a specific user named `jason`:

    ```bash
    istioctl create -f samples/apps/bookinfo/consul/consul-content-rule.yaml
    ```
    
    This will display black stars - but only if you login as user `jason` (no password), otherwise only red 
    stars will be shown.

## Cleaning up

Remove all docker containers:

  ```bash
  docker-compose -f samples/apps/bookinfo/consul/docker-compose.yaml down
  ```

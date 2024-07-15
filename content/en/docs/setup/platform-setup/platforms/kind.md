---
title: kind
description: Instructions to set up kind for Istio.
weight: 30
skip_seealso: true
keywords: [platform-setup,kubernetes,kind]
owner: istio/wg-environments-maintainers
test: no
---

[kind](https://kind.sigs.k8s.io/) is a tool for running local Kubernetes clusters using Docker container `nodes`.
kind was primarily designed for testing Kubernetes itself, but may be used for local development or CI.
Follow these instructions to prepare a kind cluster for Istio installation.

## Prerequisites

- Please use the latest Go version.
- To use kind, you will also need to [install docker](https://docs.docker.com/install/).
- Install the latest version of [kind](https://kind.sigs.k8s.io/docs/user/quick-start/).
- Increase Docker's [memory limit](/docs/setup/platform-setup/docker/).

## Installation steps

1.  Create a cluster with the following command:

    {{< text bash >}}
    $ kind create cluster --name istio-testing
    {{< /text >}}

    `--name` is used to assign a specific name to the cluster. By default, the cluster will be given the name "kind".

1.  To see the list of kind clusters, use the following command:

    {{< text bash >}}
    $ kind get clusters
    istio-testing
    {{< /text >}}

1.  To list the local Kubernetes contexts, use the following command.

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME                 CLUSTER              AUTHINFO             NAMESPACE
    *         kind-istio-testing   kind-istio-testing   kind-istio-testing
              minikube             minikube             minikube
    {{< /text >}}

    {{< tip >}}
    `kind` is prefixed to the context and cluster names, for example: `kind-istio-testing`
    {{< /tip >}}

1.  If you run multiple clusters, you need to choose which cluster `kubectl` talks to. You can set a default cluster
    for `kubectl` by setting the current context in the [Kubernetes kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) file. Additionally you can run following command
    to set the current context for `kubectl`.

    {{< text bash >}}
    $ kubectl config use-context kind-istio-testing
    Switched to context "kind-istio-testing".
    {{< /text >}}

    Once you are done setting up a kind cluster, you can proceed to [install Istio](/docs/setup/getting-started/#download)
    on it.

1.  When you are done experimenting and you want to delete the existing cluster, use the following command:

    {{< text bash >}}
    $ kind delete cluster --name istio-testing
    Deleting cluster "istio-testing" ...
    {{< /text >}}

## Setup MetalLB for kind

kind does not have any built-in way to provide IP addresses to your `Loadbalancer` service types, to ensure IP address assignments to `Gateway` Services please consult [this guide](https://kind.sigs.k8s.io/docs/user/loadbalancer/) for more information.

## Setup Dashboard UI for kind

kind does not have a built-in Dashboard UI like minikube. But you can still setup Dashboard, a web-based Kubernetes UI, to view your cluster.
Follow these instructions to set up Dashboard for kind.

1.  To deploy Dashboard, run the following command:

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    {{< /text >}}

1.  Verify that Dashboard is deployed and running.

    {{< text bash >}}
    $ kubectl get pod -n kubernetes-dashboard
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-76585494d8-zdb66   1/1     Running   0          39s
    kubernetes-dashboard-b7ffbc8cb-zl8zg         1/1     Running   0          39s
    {{< /text >}}

1.  Create a `ServiceAccount` and `ClusterRoleBinding` to provide admin access to the newly created cluster.

    {{< text bash >}}
    $ kubectl create serviceaccount -n kubernetes-dashboard admin-user
    $ kubectl create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
    {{< /text >}}

1.  To log in to your Dashboard, you need a Bearer Token. Use the following command to store the token in a variable.

    {{< text bash >}}
    $ token=$(kubectl -n kubernetes-dashboard create token admin-user)
    {{< /text >}}

    Display the token using the `echo` command and copy it to use for logging in to your Dashboard.

    {{< text bash >}}
    $ echo $token
    {{< /text >}}

1.  You can access your Dashboard using the kubectl command-line tool by running the following command:

    {{< text bash >}}
    $ kubectl proxy
    Starting to serve on 127.0.0.1:8001
    {{< /text >}}

    Click [Kubernetes Dashboard](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/) to
    view your deployments and services.

    {{< warning >}}
    You have to save your token somewhere, otherwise you have to run step number 4 everytime you need a token to log in to your Dashboard.
    {{< /warning >}}

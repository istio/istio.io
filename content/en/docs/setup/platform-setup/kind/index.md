---
title: kind
description: Instructions to setup kind for Istio.
weight: 21
skip_seealso: true
keywords: [platform-setup,kubernetes,kind]
---

[kind](https://kind.sigs.k8s.io/) is a tool for running local Kubernetes clusters using Docker container `nodes`.
kind was primarily designed for testing Kubernetes itself, but may be used for local development or CI.
Follow these instructions to prepare kind for Istio installation.

## Prerequisites

- Please use latest Go version, ideally Go 1.13 or greater.
- To use kind, you will also need to [install docker](https://docs.docker.com/install/).
- Install the latest version of [kind](https://kind.sigs.k8s.io/docs/user/quick-start/).

## Installation steps

1.  Create cluster with the following command:

    {{< text bash >}}
    $ kind create cluster --name istio-testing
    {{< /text >}}

    `--name` is used to assign specific name to the cluster. By default, the cluster will be given the name `kind`.

1.  When you want to see the list of clusters, use following command:

    {{< text bash >}}
    $ kind get clusters
    kind-istio-testing
    {{< /text >}}

    {{< tip >}}
    `kind` is automatically prefixed in cluster name `kind-istio-testing`
    {{< /tip >}}

1.  In order to interact with a specific cluster, you only need to specify the cluster name as a context in kubectl:

    {{< text bash >}}
    $ kubectl cluster-info --context kind-istio-testing
    Kubernetes master is running at https://127.0.0.1:32773
    KubeDNS is running at https://127.0.0.1:32773/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
    {{< /text >}}

1.  In case you already have another local cluster, you must set kind as current cluster in order to use it.
    View local cluster configuration using following command

    {{< text bash >}}
    $ kubectl config view
    {{< /text >}}

    Make sure that the `current-context` is set to `kind-istio-testing`. If it is set to another cluster like minikube,
    You can set kind as a current cluster using the following command.

    {{< text bash >}}
    $ kubectl config use-context kind-istio-testing
    kubectl config use-context kind-istio-testing
    {{< /text >}}

1.  When you are done experimenting and you want to delete existing cluster, use the following command:

    {{< text bash >}}
    $ kind delete cluster --name istio-testing
    {{< /text >}}

## Setup Dashboard UI for kind

kind does not have in built dashboard UI like minikube. But you can still setup and view your cluster.
Follow these instruction to setup dashboard UI for kind.

1.  The dashboard UI is not deployed by default. To deploy it, run the following command:

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
    {{< /text >}}

1.  Verify that the dashboard is deployed and running.

    {{< text bash >}}
    $ kubectl get pod -n kubernetes-dashboard
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-76585494d8-zdb66   1/1     Running   0          39s
    kubernetes-dashboard-b7ffbc8cb-zl8zg         1/1     Running   0          39s
    {{< /text >}}

1.  Create `ClusterRoleBinding` to provide admin access to the newly created cluster.

    {{< text bash >}}
    $ kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
    {{< /text >}}

1.  In order to login to the dashboard UI you need a token. Use following command to store token in variable.

    {{< text bash >}}
    $ token=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 -d)
    {{< /text >}}

    Display token using the echo command and copy it so you can use it to login to dashboard.

    {{< text bash >}}
    $ echo $token
    {{< /text >}}

1.  You can access dashboard using the kubectl command-line tool by running the following command:

    {{< text bash >}}
    $ kubectl proxy
    Starting to serve on 127.0.0.1:8001
    {{< /text >}}

    Kubectl will make dashboard available at [localhost:8001](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/).

    {{< warning >}}
    You have to save your token somewhere, otherwise you have to run step number 4 everytime you need a token to login to your dashboard.
    {{< /warning >}}


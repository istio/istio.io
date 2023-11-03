---
title: k3d
description: Instructions to set up k3d for Istio.
weight: 28
skip_seealso: true
keywords: [platform-setup,kubernetes,k3d,k3s]
owner: istio/wg-environments-maintainers
test: no
---

k3d is a lightweight wrapper to run [k3s](https://github.com/rancher/k3s) (Rancher Lab’s minimal Kubernetes distribution) in docker.
k3d makes it very easy to create single- and multi-node k3s clusters in docker, e.g. for local development on Kubernetes.

## Prerequisites

- To use k3d, you will also need to [install docker](https://docs.docker.com/install/).
- Install the latest version of [k3d](https://k3d.io/v5.4.7/#installation).
- To interact with the Kubernetes cluster [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- (Optional) [Helm](https://helm.sh/docs/intro/install/) is the package manager for Kubernetes

## Installation

1.  Create a cluster and disable `Traefik` with the following command:

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

1.  To see the list of k3d clusters, use the following command:

    {{< text bash >}}
    $ k3d cluster list
    k3s-default
    {{< /text >}}

1.  To list the local Kubernetes contexts, use the following command.

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME                 CLUSTER              AUTHINFO             NAMESPACE
    *         k3d-k3s-default      k3d-k3s-default      k3d-k3s-default
    {{< /text >}}

    {{< tip >}}
    `k3d-` is prefixed to the context and cluster names, for example: `k3d-k3s-default`
    {{< /tip >}}

1.  If you run multiple clusters, you need to choose which cluster `kubectl` talks to. You can set a default cluster
    for `kubectl` by setting the current context in the [Kubernetes kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) file. Additionally you can run following command
    to set the current context for `kubectl`.

    {{< text bash >}}
    $ kubectl config use-context k3d-k3s-default
    Switched to context "k3d-k3s-default".
    {{< /text >}}

## Set up Istio for k3d

1.  Once you are done setting up a k3d cluster, you can proceed to [install Istio with Helm 3](/docs/setup/install/helm/) on it.

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ helm install istio-base istio/base -n istio-system --wait
    $ helm install istiod istio/istiod -n istio-system --wait
    {{< /text >}}

1.  (Optional) Install an ingress gateway:

    {{< text bash >}}
    $ kubectl label namespace istio-system istio-injection=enabled
    $ helm install istio-ingressgateway istio/gateway -n istio-system --wait
    {{< /text >}}

## Set up Dashboard UI for k3d

k3d does not have a built-in Dashboard UI like minikube. But you can still set up Dashboard, a web based Kubernetes UI, to view your cluster.
Follow these instructions to set up Dashboard for k3d.

1.  To deploy Dashboard, run the following command:

    {{< text bash >}}
    $ GITHUB_URL=https://github.com/kubernetes/dashboard/releases
    $ VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml
    {{< /text >}}

1.  Verify that Dashboard is deployed and running.

    {{< text bash >}}
    $ kubectl get pod -n kubernetes-dashboard
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-8c47d4b5d-dd2ks    1/1     Running   0          25s
    kubernetes-dashboard-67bd8fc546-4xfmm        1/1     Running   0          25s
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

## Uninstall

1.  When you are done experimenting and you want to delete the existing cluster, use the following command:

    {{< text bash >}}
    $ k3d cluster delete k3s-default
    Deleting cluster "k3s-default" ...
    {{< /text >}}

---
title: Kubernetes Gardener
description: Instructions to set up a Gardener cluster for Istio.
weight: 35
aliases:
    - /docs/setup/kubernetes/platform-setup/gardener/
skip_seealso: true
keywords: [platform-setup,kubernetes,gardener,sap]
owner: istio/wg-environments-maintainers
test: no
---

## Bootstrapping Gardener

To set up your own [Gardener](https://gardener.cloud) for your organization's Kubernetes-as-a-Service needs, follow the
[documentation](https://github.com/gardener/gardener/blob/master/docs/README.md).
For testing purposes, you can set up [Gardener on your laptop](https://github.com/gardener/gardener/blob/master/docs/development/getting_started_locally.md) by checking out the source code repository and simply running `make kind-up gardener-up` (the easiest developer way of checking out Gardener!).

Alternatively, [`23 Technologies GmbH`](https://23technologies.cloud/) offers a fully-managed Gardener service that conveniently works with all supported cloud providers and comes with a free trial: [`Okeanos`](https://okeanos.dev/). Similarly, cloud providers such as [`STACKIT`](https://stackit.de/), [`B'Nerd`](https://bnerd.com/), [`MetalStack`](https://metalstack.cloud/), and many others run Gardener as their Kubernetes Engine.

To learn more about the inception of this open source project, read [Gardener Project Update](https://kubernetes.io/blog/2019/12/02/gardener-project-update/) and [Gardener - The Kubernetes Botanist](https://kubernetes.io/blog/2018/05/17/gardener/) on [`kubernetes.io`](https://kubernetes.io/blog).

[Gardener yourself a Shoot with Istio, custom Domains, and Certificates](https://gardener.cloud/docs/extensions/others/gardener-extension-shoot-cert-service/docs/tutorial-custom-domain-with-istio/) is a detailed tutorial for the end user of Gardener.

### Install and configure `kubectl`

1.  If you already have `kubectl` CLI, run `kubectl version --short` to check
    the version. You need a current version that at least matches your Kubernetes
    cluster version you want to order. If your `kubectl` is older, follow the
    next step to install a newer version.

1.  [Install the `kubectl` CLI](https://kubernetes.io/docs/tasks/tools/).

### Access Gardener

1.  Create a project in the Gardener dashboard. This will essentially create a
    Kubernetes namespace with the name `garden-<my-project>`.

1.  [Configure access to your Gardener project](https://gardener.cloud/docs/dashboard/usage/gardener-api/)
    using a kubeconfig.

    {{< tip >}}
    You can skip this step if you intend to create and interact with your cluster using the Gardener dashboard and the embedded webterminal; this step is only needed for programmatic access.
    {{< /tip >}}

    If you are not the Gardener Administrator already, you can create a technical user in the Gardener dashboard:
    go to the "Members" section and add a service account. You can then download the kubeconfig for your project.
    Make sure you `export KUBECONFIG=garden-my-project.yaml` in your shell.
    ![Download kubeconfig for Gardener](https://raw.githubusercontent.com/gardener/dashboard/master/docs/images/01-add-service-account.png "downloading the kubeconfig using a service account")

### Creating a Kubernetes cluster

You can create your cluster using the `kubectl` cli by providing a cluster
specification yaml file. You can find an example for GCP
[here](https://github.com/gardener/gardener/blob/master/example/90-shoot.yaml).
Make sure the namespace matches that of your project. Then apply the
prepared so-called "shoot" cluster manifest with `kubectl`:

{{< text bash >}}
$ kubectl apply --filename my-cluster.yaml
{{< /text >}}

An easier alternative is to create the cluster following the cluster creation
wizard in the Gardener dashboard:
![shoot creation](https://raw.githubusercontent.com/gardener/dashboard/master/docs/images/dashboard-demo.gif "shoot creation via the dashboard")

### Configure `kubectl` for your cluster

You can now download the kubeconfig for your freshly created cluster in the
Gardener dashboard or via cli as follows:

{{< text bash >}}
$ kubectl --namespace shoot--my-project--my-cluster get secret kubecfg --output jsonpath={.data.kubeconfig} | base64 --decode > my-cluster.yaml
{{< /text >}}

This kubeconfig file has full administrator access to you cluster.
For any activities with the payload cluster be sure you have `export KUBECONFIG=my-cluster.yaml` set.

## Cleaning up

Use the Gardener dashboard to delete your cluster, or execute the following with
`kubectl` pointing to your `garden-my-project.yaml` kubeconfig:

{{< text bash >}}
$ kubectl --kubeconfig garden-my-project.yaml --namespace garden--my-project annotate shoot my-cluster confirmation.garden.sapcloud.io/deletion=true
$ kubectl --kubeconfig garden-my-project.yaml --namespace garden--my-project delete shoot my-cluster
{{< /text >}}

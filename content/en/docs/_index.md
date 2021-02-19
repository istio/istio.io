---
title: Quick start
skipTitle: true
linktitle: Documentation
description: Learn how to deploy, use, and operate Istio.
weight: 1
skip_list: true
sidebar_multicard: false
test: n/a
---

# Quick start

This guide lets you quickly evaluate Istio. If you are already familiar with
Istio or interested in installing other configuration profiles or
advanced [deployment models](/docs/ops/deployment/deployment-models/), refer to our
[which Istio installation method should I use?](/faq/setup/#install-method-selection)
FAQ page.

These steps require you to have a {{< gloss >}}cluster{{< /gloss >}} running a
compatible version of Kubernetes ({{< supported_kubernetes_versions >}}). You can use any supported platform, for
example [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) or
others specified by the
[platform-specific setup instructions](/docs/setup/platform-setup/).

Follow these steps to get started with Istio:

1. [Download and install Istio](#download)
1. [Deploy the sample application](#bookinfo)
1. [Open the application to outside traffic](#ip)
1. [View the dashboard](#dashboard)

## Download Istio {#download}

1.  Go to the [Istio release]({{< istio_release_url >}}) page to
    download the installation file for your OS, or download and
    extract the latest release automatically (Linux or macOS):

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

    {{< tip >}}
    The command above downloads the latest release (numerically) of Istio.
    You can pass variables on the command line to download a specific version
    or to override the processor architecture.
    For example, to download Istio 1.6.8 for the x86_64 architecture,
    run:

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.8 TARGET_ARCH=x86_64 sh -
    {{< /text >}}

    {{< /tip >}}

1.  Move to the Istio package directory. For example, if the package is
    `istio-{{< istio_full_version >}}`:

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    The installation directory contains:

    - Sample applications in `samples/`
    - The [`istioctl`](/docs/reference/commands/istioctl) client binary in the
      `bin/` directory.

1.  Add the `istioctl` client to your path (Linux or macOS):

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Deploy the sample application {#bookinfo}

1.  Deploy the [`Bookinfo` sample application](/docs/examples/bookinfo/):

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

1.  The application will start. As each pod becomes ready, the Istio sidecar will be
    deployed along with it.

    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.212      <none>        9080/TCP   29s
    kubernetes    ClusterIP   10.0.0.1        <none>        443/TCP    25m
    productpage   ClusterIP   10.0.0.57       <none>        9080/TCP   28s
    ratings       ClusterIP   10.0.0.33       <none>        9080/TCP   29s
    reviews       ClusterIP   10.0.0.28       <none>        9080/TCP   29s
    {{< /text >}}

    and

    {{< text bash >}}
    $ kubectl get pods
    NAME                              READY   STATUS    RESTARTS   AGE
    details-v1-558b8b4b76-2llld       2/2     Running   0          2m41s
    productpage-v1-6987489c74-lpkgl   2/2     Running   0          2m40s
    ratings-v1-7dc98c7588-vzftc       2/2     Running   0          2m41s
    reviews-v1-7f99cc4496-gdxfn       2/2     Running   0          2m41s
    reviews-v2-7d79d5bd5d-8zzqd       2/2     Running   0          2m41s
    reviews-v3-7dbcdcbc56-m8dph       2/2     Running   0          2m41s
    {{< /text >}}

    {{< tip >}}
    Re-run the previous command and wait until all pods report READY `2/2` and
    STATUS `Running` before you go to the next step. This might take a few minutes
    depending on your platform.
    {{< /tip >}}

1.  Verify everything is working correctly up to this point. Run this command to
    see if the app is running inside the cluster and serving HTML pages by
    checking for the page title in the response:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -s productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## View the dashboard {#dashboard}

Istio integrates with [several](/docs/ops/integrations) different telemetry applications. These can help you gain
an understanding of the structure of your service mesh, display the topology of the mesh, and analyze the health of your mesh.

Use the following instructions to deploy the [Kiali](/docs/ops/integrations/kiali/) dashboard, along with [Prometheus](/docs/ops/integrations/prometheus/), [Grafana](/docs/ops/integrations/grafana), and [Jaeger](/docs/ops/integrations/jaeger/).

1.  Install Kiali and wait for it to be deployed.

    {{< text bash >}}
    $ kubectl apply -f samples/addons
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

    {{< tip >}}
    If there are errors trying to install the addons, try running the command again. There may
    be some timing issues which will be resolved when the command is run again.
    {{< /tip >}}

1.  Access the Kiali dashboard.

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  In the left navigation menu, select _Graph_ and in the _Namespace_ drop down, select _default_.

    The Kiali dashboard shows an overview of your mesh with the relationships
    between the services in the `Bookinfo` sample application. It also provides
    filters to visualize the traffic flow.

## Uninstall

To delete the `Bookinfo` sample application and its configuration, see
[`Bookinfo` cleanup](/docs/examples/bookinfo/#cleanup).

The Istio uninstall deletes the RBAC permissions and all resources hierarchically
under the `istio-system` namespace. It is safe to ignore errors for non-existent
resources because they may have been deleted hierarchically.

{{< text bash >}}
$ kubectl delete -f @samples/addons@
$ istioctl manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -
{{< /text >}}

The `istio-system` namespace is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

The label to instruct Istio to automatically inject Envoy sidecar proxies is not removed by default.
If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}
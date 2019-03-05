---
title: Install Istio on a Kubernetes Cluster
description: Instructions to install the Istio service mesh in a Kubernetes cluster.
weight: 55
keywords: [kubernetes]
aliases:
    - /docs/setup/kubernetes/quick-start/
---

Follow these instructions to quickly get started evaluating Istio in a Kubernetes cluster on any platform.
These instructions install a precofigured Istio `demo profile` using basic Kubernetes commands,
without needing to download or install [helm](https://github.com/helm/helm).

{{< tip >}}
To install Istio for production use, we recommend using the
[Helm Installation guide](/docs/setup/kubernetes/install/helm/) instead,
which provides many more options for selecting and managing the Istio configuration.
This permits customization of Istio to operator specific requirements.
{{< /tip >}}

## Prerequisites

1. [Download the Istio release](/docs/setup/kubernetes/download-release/).

1. [Kubernetes platform setup](/docs/setup/kubernetes/platform-setup/):

  * [Alibaba Cloud](/docs/setup/kubernetes/platform-setup/alicloud/)
  * [Amazon Web Services (AWS) with Kops](/docs/setup/kubernetes/platform-setup/aws/)
  * [Azure](/docs/setup/kubernetes/platform-setup/azure/)
  * [Docker For Desktop](/docs/setup/kubernetes/platform-setup/docker/)
  * [Google Container Engine (GKE)](/docs/setup/kubernetes/platform-setup/gke/)
  * [IBM Cloud](/docs/setup/kubernetes/platform-setup/ibm/)
  * [Minikube](/docs/setup/kubernetes/platform-setup/minikube/)
  * [OpenShift Origin](/docs/setup/kubernetes/platform-setup/openshift/)
  * [Oracle Cloud Infrastructure (OKE)](/docs/setup/kubernetes/platform-setup/oci/)

    {{< tip >}}
    Istio {{< istio_version >}} has been tested with these Kubernetes releases: {{< supported_kubernetes_versions >}}.
    {{< /tip >}}

1. Check the [Requirements for Pods and Services](/docs/setup/kubernetes/additional-setup/requirements//).

## Installation steps

1. Install all the Istio
    [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
    (CRDs) using `kubectl apply`, and wait a few seconds for the CRDs to be committed in the Kubernetes API-server:

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. Install one of the following variants of the `demo profile`:

{{< tabset cookie-name="profile" >}}

{{% tab name="permissive mTLS" cookie-value="permissive" %}}
In this variant, all services accept both plain text and
mutual TLS traffic. Clients, will send plain text traffic unless they are configured for
[mutual migration](/docs/tasks/security/mtls-migration/#configure-clients-to-send-mutual-tls-traffic).
Visit our [mutual TLS permissive mode page](/docs/concepts/security/#permissive-mode)
for more information.

Choose this variant for:

* Clusters with existing applications,
* Applications where services with an Istio sidecar need to be able to
  communicate with other non-Istio Kubernetes services,
* Applications that use
  [liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/),
* Headless services, or
* `StatefulSets`

Run the following command to install this variant:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo.yaml
{{< /text >}}
{{% /tab %}}

{{% tab name="strict mTLS" cookie-value="strict" %}}
This variant will enforce
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) between all clients and servers.

Use this variant only on a fresh Kubernetes cluster where all workloads will be Istio-enabled.
All newly deployed workloads will have Istio sidecars installed.

Run the following command to install this variant:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}
{{% /tab %}}

{{< /tabset >}}

## Verifying the installation

1.  To ensure the following Kubernetes services are deployed: `istio-citadel`,
    `istio-engressgateway`, `istio-galley`, `istio-ingress`, `istio-ingressgateway`,
    `istio-pilot`, `istio-policy`, `istio-statsd-prom-bridge`, `istio-telemetry`,
    `prometheus`, and `istio-sidecar-injector`.
     Verify they all have an appropriate `CLUSTER-IP`:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    {{< /text >}}

    {{< tip >}}
    If your cluster is running in an environment that does not
    support an external load balancer (e.g., minikube), the
    `EXTERNAL-IP` of `istio-ingressgateway` will
    say `<pending>`. You will need to access it using the service's
    `NodePort`, or use port-forwarding instead.
    {{< /tip >}}

1.  Ensure the corresponding Kubernetes pods are deployed and all containers: `istio-citadel-*`,
    `istio-egressgateway-*`, `istio-galley-*`, `istio-ingressgateway-*`, `istio-pilot-*`,
    `istio-policy-*`, `istio-telemetry-*`, `prometheus-*`, and
    `istio-sidecar-injector-*`, have a `STATUS` of `Running`:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    {{< /text >}}

## Deploy your application

You can now deploy your own application or one of the sample applications
provided with the installation like [Bookinfo](/docs/examples/bookinfo/).

{{< warning >}}
The application must use either the HTTP/1.1 or HTTP/2.0 protocols for all its HTTP
traffic; HTTP/1.0 is not supported.
{{< /warning >}}

When you deploy your application using `kubectl apply`,
the [Istio-sidecar-injector](/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection)
will automatically inject Envoy containers into your
application pods if they are started in namespaces labeled with `istio-injection=enabled`:

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

In namespaces without the `istio-injection` label, you can use
[`istioctl kube-inject`](/docs/reference/commands/istioctl/#istioctl-kube-inject)
to manually inject Envoy containers in your application pods before deploying
them:

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

## Uninstall

The uninstall deletes the RBAC permissions, the `istio-system` namespace, and
all resources hierarchically under it. It is safe to ignore errors for
non-existent resources because they may have been deleted hierarchically.


* Uninstall the `demo profile` corresponding to the variant you installed:

{{< tabset cookie-name="profile" >}}

{{% tab name="permissive mTLS" cookie-value="permissive" %}}
{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo.yaml
{{< /text >}}
{{% /tab %}}

{{% tab name="strict mTLS" cookie-value="strict" %}}
{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}
{{% /tab %}}

{{< /tabset >}}

* If desired, delete the Istio CRDs:

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete -f $i; done
    {{< /text >}}

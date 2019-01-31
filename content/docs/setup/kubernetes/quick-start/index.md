---
title: Quick Start with Kubernetes
description: Instructions to setup the Istio service mesh in a Kubernetes cluster.
weight: 55
keywords: [kubernetes]
---

{{< tip >}}
Istio {{< istio_version >}} has been tested with these Kubernetes releases: {{< supported_kubernetes_versions >}}.
{{< /tip >}}

To install and configure Istio in a Kubernetes cluster, follow these instructions:

## Prerequisites

1. [Download the Istio release](/docs/setup/kubernetes/download-release/).

1. [Kubernetes platform setup](/docs/setup/kubernetes/platform-setup/):
  * [Alibaba Cloud](/docs/setup/kubernetes/platform-setup/alicloud/)
  * [Amazon Web Services (AWS) with Kops](/docs/setup/kubernetes/platform-setup/aws/)
  * [Azure](/docs/setup/kubernetes/platform-setup/azure/)
  * [Docker For Desktop](/docs/setup/kubernetes/platform-setup/docker-for-desktop/)
  * [Google Container Engine (GKE)](/docs/setup/kubernetes/platform-setup/gke/)
  * [IBM Cloud](/docs/setup/kubernetes/platform-setup/ibm/)
  * [Minikube](/docs/setup/kubernetes/platform-setup/minikube/)
  * [OpenShift Origin](/docs/setup/kubernetes/platform-setup/openshift/)
  * [Oracle Cloud Infrastructure (OKE)](/docs/setup/kubernetes/platform-setup/oci/)

1. Check the [Requirements for Pods and Services](/docs/setup/kubernetes/spec-requirements/).

## Installation steps

1. Install Istio's [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
via `kubectl apply`, and wait a few seconds for the CRDs to be committed in Kubernetes API server:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

1. To install Istio's core components you can choose any of the following four
**mutually exclusive** options described below. However, for a production setup of Istio,
we recommend installing with the
[Helm Chart](/docs/setup/kubernetes/helm-install/), to use all the
configuration options. This permits customization of Istio to operator specific requirements.

### Option 1: Install Istio with mutual TLS enabled and set to use permissive mode between sidecars

Visit our
[mutual TLS permissive mode page](/docs/concepts/security/#permissive-mode)
for more information.

Choose this option for:

* Clusters with existing applications,
* Applications where services with an Istio sidecar need to be able to
  communicate with other non-Istio Kubernetes services,
* Applications that use
  [liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/),
* Headless services, or
* `StatefulSets`

To install Istio with mutual TLS enabled and set to use permissive mode
between sidecars:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo.yaml
{{< /text >}}

In this option, all services, as servers, can accept both plain text and
mutual TLS traffic. However, all services, as clients, will send plain
text traffic.
Visit [mutual migration](/docs/tasks/security/mtls-migration/#configure-clients-to-send-mutual-tls-traffic)
for how to configure clients behavior.

### Option 2: Install Istio with default mutual TLS authentication

Use this option only on a fresh Kubernetes cluster where newly deployed
workloads are guaranteed to have Istio sidecars installed.

To Install Istio and enforce [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication)
between sidecars by default:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}

### Option 3: Render Kubernetes manifest with Helm and deploy with `kubectl`

Follow our setup instructions to
[render the Kubernetes manifest with Helm and deploy with `kubectl`](/docs/setup/kubernetes/helm-install/#option-1-install-with-helm-via-helm-template).

### Option 4: Use Helm and Tiller to manage the Istio deployment

Follow our instructions on how to
[use Helm and Tiller to manage the Istio deployment](/docs/setup/kubernetes/helm-install/#option-2-install-with-helm-and-tiller-via-helm-install).

## Verifying the installation

1.  To ensure the following Kubernetes services are deployed: `istio-citadel`,
    `istio-engressgateway`, `istio-galley`, `istio-ingress`, `istio-ingressgateway`,
    `istio-pilot`, `istio-policy`, `istio-statsd-prom-bridge`, `istio-telemetry`,
    `prometheus`, and optionally, `istio-sidecar-injector`, verify they all have
    an appropriate `CLUSTER-IP`:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    {{< /text >}}

    {{< tip >}}
    If your cluster is running in an environment that does not
    support an external load balancer (e.g., minikube), the
    `EXTERNAL-IP` of `istio-ingress` and `istio-ingressgateway` will
    say `<pending>`. You will need to access it using the service's
    `NodePort`, or use port-forwarding instead.
    {{< /tip >}}

1.  Ensure the corresponding Kubernetes pods are deployed and all containers: `istio-citadel-*`,
    `istio-engressgateway-*`, `istio-galley-*`, `istio-ingress-*`, `istio-ingressgateway-*`,
    `istio-pilot-*`, `istio-policy-*`, `istio-statsd-prom-bridge-*`, `istio-telemetry-*`,
    `prometheus-*`, and, optionally, `istio-sidecar-injector-*`, have a `STATUS` of `Running`:

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

If you started the
[Istio-sidecar-injector](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection),
you can deploy the application directly using `kubectl apply`.

The Istio-Sidecar-injector will automatically inject Envoy containers into your
application pods. The injector assumes the application pods are running in
namespaces labeled with `istio-injection=enabled`

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

If you don't have the Istio-sidecar-injector installed, you must use
[`istioctl kube-inject`](/docs/reference/commands/istioctl/#istioctl-kube-inject)
to manually inject Envoy containers in your application pods before deploying
them:

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

## Uninstall Istio core components

The uninstall deletes the RBAC permissions, the `istio-system` namespace, and
all resources hierarchically under it. It is safe to ignore errors for
non-existent resources because they may have been deleted hierarchically.

* If you installed Istio with `istio-demo.yaml`:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio-demo.yaml
    {{< /text >}}

* If you installed Istio with `istio-demo-auth.yaml`:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

* If you installed Istio with Helm, follow the [uninstall Istio with Helm](/docs/setup/kubernetes/helm-install/#uninstall) steps.

* If desired, delete the CRDs:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

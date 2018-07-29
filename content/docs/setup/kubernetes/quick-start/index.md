---
title: Quick Start with Kubernetes
description: Instructions to setup the Istio service mesh in a Kubernetes cluster.
weight: 5
keywords: [kubernetes]
---

To install and configure Istio in a Kubernetes cluster, follow these instructions:

## Prerequisites

1. [Download the Istio release](/docs/setup/kubernetes/download-release/).

1. [Kubernetes platform setup](/docs/setup/kubernetes/platform-setup/):
  * [Minikube](/docs/setup/kubernetes/platform-setup/minikube/)
  * [Google Container Engine (GKE)](/docs/setup/kubernetes/platform-setup/gke/)
  * [IBM Cloud](/docs/setup/kubernetes/platform-setup/ibm/)
  * [OpenShift Origin](/docs/setup/kubernetes/platform-setup/openshift/)
  * [Amazon Web Services (AWS) with Kops](/docs/setup/kubernetes/platform-setup/aws/)
  * [Azure](/docs/setup/kubernetes/platform-setup/azure/)

1. Check the [Requirements for Pods and Services](/docs/setup/kubernetes/spec-requirements/).

## Installation steps

1. Install Istio's [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
via `kubectl apply`, and wait a few seconds for the CRDs to be committed in the kube-apiserver:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
    {{< /text >}}

1. To install Istio's core components you can choose any of the following four
**mutually exclusive** options described below. However, for a production setup of Istio,
we recommend installing with the
[Helm Chart](/docs/setup/kubernetes/helm-install/), to use all the
configuration options. This permits customization of Istio to operator specific requirements.

### Option 1: Install Istio without mutual TLS authentication between sidecars

Visit our
[mutual TLS authentication between sidecars concept page](/docs/concepts/security/#mutual-tls-authentication)
for more information.

Choose this option for:

* Clusters with existing applications,
* Applications where services with an Istio sidecar need to be able to
  communicate with other non-Istio Kubernetes services,
* Applications that use
  [liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/),
* Headless services, or
* `StatefulSets`

To install Istio without mutual TLS authentication between sidecars:

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo.yaml
{{< /text >}}

### Option 2: Install Istio with default mutual TLS authentication

Use this option only on a fresh kubernetes cluster where newly deployed
workloads are guaranteed to have Istio sidecars installed.

To Install Istio and enforce mutual TLS authentication between sidecars by
default:

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

1.  Ensure the following Kubernetes services are deployed: `istio-pilot`,
    `istio-ingressgateway`, `istio-policy`, `istio-telemetry`, `prometheus`,
    `istio-galley`, and, optionally, `istio-sidecar-injector`.

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                                                               AGE
    istio-citadel              ClusterIP      10.47.247.12    <none>            8060/TCP,9093/TCP                                                     7m
    istio-egressgateway        ClusterIP      10.47.243.117   <none>            80/TCP,443/TCP                                                        7m
    istio-galley               ClusterIP      10.47.254.90    <none>            443/TCP                                                               7m
    istio-ingress              LoadBalancer   10.47.244.111   35.194.55.10      80:32000/TCP,443:30814/TCP                                            7m
    istio-ingressgateway       LoadBalancer   10.47.241.20    130.211.167.230   80:31380/TCP,443:31390/TCP,31400:31400/TCP                            7m
    istio-pilot                ClusterIP      10.47.250.56    <none>            15003/TCP,15005/TCP,15007/TCP,15010/TCP,15011/TCP,8080/TCP,9093/TCP   7m
    istio-policy               ClusterIP      10.47.245.228   <none>            9091/TCP,15004/TCP,9093/TCP                                           7m
    istio-sidecar-injector     ClusterIP      10.47.245.22    <none>            443/TCP                                                               7m
    istio-statsd-prom-bridge   ClusterIP      10.47.252.184   <none>            9102/TCP,9125/UDP                                                     7m
    istio-telemetry            ClusterIP      10.47.250.107   <none>            9091/TCP,15004/TCP,9093/TCP,42422/TCP                                 7m
    prometheus                 ClusterIP      10.47.253.148   <none>            9090/TCP                                                              7m
    {{< /text >}}

    > If your cluster is running in an environment that does not
    > support an external load balancer (e.g., minikube), the
    > `EXTERNAL-IP` of `istio-ingress` and `istio-ingressgateway` will
    > say `<pending>`. You will need to access it using the service
    > NodePort, or use port-forwarding instead.

1.  Ensure the corresponding Kubernetes pods are deployed and all containers
    are up and running: `istio-pilot-*`, `istio-ingressgateway-*`,
    `istio-egressgateway-*`, `istio-policy-*`, `istio-telemetry-*`,
    `istio-citadel-*`, `prometheus-*`, `istio-galley-*`, and, optionally,
    `istio-sidecar-injector-*`.

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                       READY     STATUS        RESTARTS   AGE
    istio-citadel-75c88f897f-zfw8b             1/1       Running       0          1m
    istio-egressgateway-7d8479c7-khjvk         1/1       Running       0          1m
    istio-galley-6c749ff56d-k97n2              1/1       Running       0          1m
    istio-ingress-7f5898d74d-t8wrr             1/1       Running       0          1m
    istio-ingressgateway-7754ff47dc-qkrch      1/1       Running       0          1m
    istio-policy-74df458f5b-jrz9q              2/2       Running       0          1m
    istio-sidecar-injector-645c89bc64-v5n4l    1/1       Running       0          1m
    istio-statsd-prom-bridge-949999c4c-xjz25   1/1       Running       0          1m
    istio-telemetry-676f9b55b-k9nkl            2/2       Running       0          1m
    prometheus-86cb6dd77c-hwvqd                1/1       Running       0          1m
    {{< /text >}}

## Deploy your application

You can now deploy your own application or one of the sample applications
provided with the installation like [Bookinfo](/docs/examples/bookinfo/).

> Note: The application must use HTTP/1.1 or HTTP/2.0 protocol for all its HTTP
> traffic because HTTP/1.0 is not supported.

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

* If you installed Istio with Helm, follow the [uninstall Istio with
Helm](/docs/setup/kubernetes/helm-install/#uninstall) steps.

* If desired, delete the CRDs using kubectl:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
    {{< /text >}}

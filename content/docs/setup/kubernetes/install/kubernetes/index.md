---
title: Quick Start Evaluation Install
description: Instructions to install and configure an Istio mesh in a Kubernetes cluster for evaluation.
weight: 10
keywords: [kubernetes]
aliases:
    - /docs/setup/kubernetes/quick-start/
---

Follow this path to quickly evaluate Istio in a Kubernetes cluster on any platform.
This path installs a preconfigured Istio **demo profile** using basic Kubernetes commands
without needing to download or install [Helm](https://github.com/helm/helm).

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
When using the mTLS permissive mode, all services accept both plain text and
mutual TLS traffic. Clients send plain text traffic unless configured for
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

1.  Ensure the following Kubernetes services are deployed and verify they all have an appropriate `CLUSTER-IP`:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                                                                      AGE
    istio-citadel            ClusterIP      172.21.113.238   <none>          8060/TCP,15014/TCP                                                                                                           8d
    istio-egressgateway      ClusterIP      172.21.32.42     <none>          80/TCP,443/TCP,15443/TCP                                                                                                     8d
    istio-galley             ClusterIP      172.21.137.255   <none>          443/TCP,15014/TCP,9901/TCP                                                                                                   8d
    istio-ingressgateway     LoadBalancer   172.21.229.108   158.85.108.37   80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:31324/TCP,15030:31752/TCP,15031:30314/TCP,15032:30953/TCP,15443:30550/TCP   8d
    istio-pilot              ClusterIP      172.21.100.28    <none>          15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                       8d
    istio-policy             ClusterIP      172.21.83.199    <none>          9091/TCP,15004/TCP,15014/TCP                                                                                                 8d
    istio-sidecar-injector   ClusterIP      172.21.198.98    <none>          443/TCP                                                                                                                      8d
    istio-telemetry          ClusterIP      172.21.84.130    <none>          9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                       8d
    prometheus               ClusterIP      172.21.140.237   <none>          9090/TCP                                                                                                                     8d
    {{< /text >}}

    {{< tip >}}
    If your cluster is running in an environment that does not
    support an external load balancer (e.g., minikube), the
    `EXTERNAL-IP` of `istio-ingressgateway` will say
    `<pending>`. To access the gateway, use the service's
    `NodePort`, or use port-forwarding instead.
    {{< /tip >}}

1.  Ensure corresponding Kubernetes pods are deployed and have a `STATUS` of `Running`:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                      READY     STATUS      RESTARTS   AGE
    istio-citadel-5c4f467b9c-m8lhb            1/1       Running     0          8d
    istio-cleanup-secrets-1.1.0-rc.0-msbk7    0/1       Completed   0          8d
    istio-egressgateway-fbfb4865d-rv2f4       1/1       Running     0          8d
    istio-galley-7799878d-hnphl               1/1       Running     0          8d
    istio-ingressgateway-7cf9598b9c-s797z     1/1       Running     0          8d
    istio-pilot-698687d96d-76j5m              2/2       Running     0          8d
    istio-policy-55758d8898-sd7b8             2/2       Running     3          8d
    istio-sidecar-injector-5948ffdfc8-wz69v   1/1       Running     0          8d
    istio-telemetry-67d8545b68-wgkmg          2/2       Running     3          8d
    prometheus-c8d8657bf-gwsc7                1/1       Running     0          8d
    {{< /text >}}

## Deploy your application

You can now deploy your own application or one of the sample applications
provided with the installation like [Bookinfo](/docs/examples/bookinfo/).

{{< warning >}}
The application must use either the HTTP/1.1 or HTTP/2.0 protocols for all its HTTP
traffic; HTTP/1.0 is not supported.
{{< /warning >}}

When you deploy your application using `kubectl apply`,
the [Istio sidecar injector](/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection)
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

* Uninstall the `demo profile` corresponding to the mTLS mode you enabled:

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

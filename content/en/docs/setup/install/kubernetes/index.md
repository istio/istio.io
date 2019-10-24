---
title: Quick Start Evaluation Install
description: Instructions to install Istio in a Kubernetes cluster for evaluation.
weight: 10
keywords: [kubernetes]
aliases:
    - /docs/setup/kubernetes/quick-start/
    - /docs/setup/kubernetes/install/kubernetes/
---

This guide installs Istio's built-in **demo** [configuration profile](/docs/setup/additional-setup/config-profiles/)
using basic Kubernetes commands without needing to download or install
[Helm](https://github.com/helm/helm). This installation lets you quickly
evaluate Istio in a Kubernetes cluster on any platform.

{{< warning >}}
The demo configuration profile is not suitable for performance evaluation. It
is designed to showcase Istio functionality with high levels of tracing and
access logging.
{{< /warning >}}

To install Istio for production use, we recommend using the
[Helm Installation guide](/docs/setup/install/helm/)
instead, which provides many more options for selecting and managing the Istio
configuration. This permits customization of Istio to operator specific
requirements.

## Prerequisites

1. [Download the Istio release](/docs/setup/#downloading-the-release).

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/setup/additional-setup/requirements/).

## Installation steps

1. Install all the Istio
    [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
    (CRDs) using `kubectl apply`, and wait a few seconds for the CRDs to be committed in the Kubernetes API-server:

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. Install the **demo** profile:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo.yaml
    {{< /text >}}

## Verifying the installation

1.  Ensure the following Kubernetes services are deployed and verify they all have an appropriate `CLUSTER-IP` except the `jaeger-agent` service:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                                                                                      AGE
    grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP                                                                                                                                     2m
    istio-citadel            ClusterIP      172.21.177.222   <none>          8060/TCP,15014/TCP                                                                                                                           2m
    istio-egressgateway      ClusterIP      172.21.113.24    <none>          80/TCP,443/TCP,15443/TCP                                                                                                                     2m
    istio-galley             ClusterIP      172.21.132.247   <none>          443/TCP,15014/TCP,9901/TCP                                                                                                                   2m
    istio-ingressgateway     LoadBalancer   172.21.144.254   52.116.22.242   15020:31831/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:30318/TCP,15030:32645/TCP,15031:31933/TCP,15032:31188/TCP,15443:30838/TCP   2m
    istio-pilot              ClusterIP      172.21.105.205   <none>          15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                                       2m
    istio-policy             ClusterIP      172.21.14.236    <none>          9091/TCP,15004/TCP,15014/TCP                                                                                                                 2m
    istio-sidecar-injector   ClusterIP      172.21.155.47    <none>          443/TCP,15014/TCP                                                                                                                            2m
    istio-telemetry          ClusterIP      172.21.196.79    <none>          9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                                       2m
    jaeger-agent             ClusterIP      None             <none>          5775/UDP,6831/UDP,6832/UDP                                                                                                                   2m
    jaeger-collector         ClusterIP      172.21.135.51    <none>          14267/TCP,14268/TCP                                                                                                                          2m
    jaeger-query             ClusterIP      172.21.26.187    <none>          16686/TCP                                                                                                                                    2m
    kiali                    ClusterIP      172.21.155.201   <none>          20001/TCP                                                                                                                                    2m
    prometheus               ClusterIP      172.21.63.159    <none>          9090/TCP                                                                                                                                     2m
    tracing                  ClusterIP      172.21.2.245     <none>          80/TCP                                                                                                                                       2m
    zipkin                   ClusterIP      172.21.182.245   <none>          9411/TCP                                                                                                                                     2m
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
    NAME                                                           READY   STATUS      RESTARTS   AGE
    grafana-f8467cc6-rbjlg                                         1/1     Running     0          1m
    istio-citadel-78df5b548f-g5cpw                                 1/1     Running     0          1m
    istio-cleanup-secrets-release-1.1-20190308-09-16-8s2mp         0/1     Completed   0          2m
    istio-egressgateway-78569df5c4-zwtb5                           1/1     Running     0          1m
    istio-galley-74d5f764fc-q7nrk                                  1/1     Running     0          1m
    istio-grafana-post-install-release-1.1-20190308-09-16-2p7m5    0/1     Completed   0          2m
    istio-ingressgateway-7ddcfd665c-dmtqz                          1/1     Running     0          1m
    istio-pilot-f479bbf5c-qwr28                                    2/2     Running     0          1m
    istio-policy-6fccc5c868-xhblv                                  2/2     Running     2          1m
    istio-security-post-install-release-1.1-20190308-09-16-bmfs4   0/1     Completed   0          2m
    istio-sidecar-injector-78499d85b8-x44m6                        1/1     Running     0          1m
    istio-telemetry-78b96c6cb6-ldm9q                               2/2     Running     2          1m
    istio-tracing-69b5f778b7-s2zvw                                 1/1     Running     0          1m
    kiali-99f7467dc-6rvwp                                          1/1     Running     0          1m
    prometheus-67cdb66cbb-9w2hm                                    1/1     Running     0          1m
    {{< /text >}}

## Deploy your application

You can now deploy your own application or one of the sample applications
provided with the installation like [Bookinfo](/docs/examples/bookinfo/).

{{< warning >}}
The application must use either the HTTP/1.1 or HTTP/2.0 protocols for all its HTTP
traffic; HTTP/1.0 is not supported.
{{< /warning >}}

When you deploy your application using `kubectl apply`,
the [Istio sidecar injector](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
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

* Uninstall the **demo** profile:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio-demo.yaml
    {{< /text >}}

* If desired, delete the Istio CRDs:

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete -f $i; done
    {{< /text >}}

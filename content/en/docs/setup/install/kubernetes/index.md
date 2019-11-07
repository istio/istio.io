---
title: Quick Start Evaluation Install
description: Instructions to install Istio in a Kubernetes cluster for evaluation.
weight: 5
keywords: [kubernetes]
aliases:
    - /docs/setup/kubernetes/quick-start/
    - /docs/setup/kubernetes/install/kubernetes/
---

This guide installs Istio's built-in `demo` [configuration profile](/docs/setup/additional-setup/config-profiles/).
This installation lets you quickly evaluate Istio in a Kubernetes cluster on any platform.

{{< warning >}}
The demo configuration profile is not suitable for performance evaluation. It
is designed to showcase Istio functionality with high levels of tracing and
access logging. To install Istio for production use, we recommend using the
[Installing with {{< istioctl >}} guide](/docs/setup/install/istioctl/) instead.
{{< /warning >}}

## Prerequisites

1. [Download the Istio release](/docs/setup/#downloading-the-release).

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

## Install the demo profile

{{< text bash >}}
$ istioctl manifest apply --set profile=demo
{{< /text >}}

## Verifying the installation

1.  Ensure the following Kubernetes services are deployed and verify they all have an appropriate `CLUSTER-IP`:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                                                                                                                      AGE
    grafana                  ClusterIP      172.21.225.124   <none>           3000/TCP                                                                                                                     11m
    istio-citadel            ClusterIP      172.21.245.143   <none>           8060/TCP,15014/TCP                                                                                                           11m
    istio-egressgateway      ClusterIP      172.21.220.216   <none>           80/TCP,443/TCP,15443/TCP                                                                                                     11m
    istio-galley             ClusterIP      172.21.38.66     <none>           443/TCP,15014/TCP,9901/TCP,15019/TCP                                                                                         11m
    istio-ingressgateway     LoadBalancer   172.21.57.24     169.63.141.134   15020:32716/TCP,80:30983/TCP,443:32755/TCP,15029:32209/TCP,15030:32018/TCP,15031:31484/TCP,15032:32151/TCP,15443:31958/TCP   11m
    istio-pilot              ClusterIP      172.21.67.234    <none>           15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                       11m
    istio-policy             ClusterIP      172.21.83.196    <none>           9091/TCP,15004/TCP,15014/TCP                                                                                                 11m
    istio-sidecar-injector   ClusterIP      172.21.172.14    <none>           443/TCP                                                                                                                      11m
    istio-telemetry          ClusterIP      172.21.68.4      <none>           9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                       11m
    jaeger-collector         ClusterIP      172.21.247.191   <none>           14267/TCP,14268/TCP,14250/TCP                                                                                                11m
    jaeger-query             ClusterIP      172.21.178.229   <none>           16686/TCP                                                                                                                    11m
    kiali                    ClusterIP      172.21.140.220   <none>           20001/TCP                                                                                                                    11m
    prometheus               ClusterIP      172.21.122.131   <none>           9090/TCP                                                                                                                     11m
    tracing                  ClusterIP      172.21.135.38    <none>           9411/TCP                                                                                                                     11m
    zipkin                   ClusterIP      172.21.165.252   <none>           9411/TCP                                                                                                                     11m
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
    istio-egressgateway-78569df5c4-zwtb5                           1/1     Running     0          1m
    istio-galley-74d5f764fc-q7nrk                                  1/1     Running     0          1m
    istio-ingressgateway-7ddcfd665c-dmtqz                          1/1     Running     0          1m
    istio-pilot-f479bbf5c-qwr28                                    1/1     Running     0          1m
    istio-policy-6fccc5c868-xhblv                                  1/1     Running     2          1m
    istio-sidecar-injector-78499d85b8-x44m6                        1/1     Running     0          1m
    istio-telemetry-78b96c6cb6-ldm9q                               1/1     Running     2          1m
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

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}

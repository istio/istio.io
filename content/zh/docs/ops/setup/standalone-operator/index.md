---
title: Standalone Operator Quick Start Evaluation Install [Experimental]
description: Instructions to install Istio in a Kubernetes cluster for evaluation.
weight: 11
keywords: [kubernetes, operator]
aliases:
---

This guide installs Istio using the standalone Istio operator. The only dependencies
required are a supported Kubernetes cluster and the `kubectl` command. This
installation method lets you quickly evaluate Istio in a Kubernetes cluster on
any platform using a variety of profiles.

To install Istio for production use, we recommend using the [Helm Installation guide](/docs/setup/install/helm/)
instead, which is a stable feature.

## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/setup/additional-setup/requirements/).

## Installation steps

1. Install Istio using the operator with the demo profile:

    {{< text bash >}}
    $ kubectl apply -f https://preliminary.istio.io/operator.yaml
    {{< /text >}}

{{< warning >}}
This profile is only for demo usage and should not be used in production.
{{< /warning >}}

1. (Optionally) change profiles from the demo profile to one of the following profiles:

{{< tabset cookie-name="profile" >}}

{{< tab name="demo" cookie-value="permissive" >}}
When using the [permissive mutual TLS mode](/docs/concepts/security/#permissive-mode), all services accept both plaintext and
mutual TLS traffic. Clients send plaintext traffic unless configured for
[mutual TLS migration](/docs/tasks/security/authentication/mtls-migration/). This profile is installed during the first step.

Choose this profile for:

* Clusters with existing applications, or
* Applications where services with an Istio sidecar need to be able to
  communicate with other non-Istio Kubernetes services

Run the following command to switch to this profile:

{{< text bash >}}
$ kubectl apply -f https://preliminary.istio.io/operator-profile-demo.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="SDS" cookie-value="sds" >}}
This profile enables
[Secret Discovery Service](/docs/tasks/security/citadel-config/auth-sds) between all clients and servers.

Use this profile to enhance startup performance of services in the Kubernetes cluster. Additionally
improve security as Kubernetes secrets that contain known
[risks](https://kubernetes.io/docs/concepts/configuration/secret/#risks) are not used.

Run the following command to switch to this profile:

{{< text bash >}}
$ kubectl apply -f https://preliminary.istio.io/operator-profile-sds.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="default" cookie-value="default" >}}
This profile enables Istio's default settings which contains recommended
production settings. Run the following command to switch to this profile:

{{< text bash >}}
$ kubectl apply -f https://preliminary.istio.io/operator-profile-default.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="minimal" cookie-value="minimal" >}}
This profile deploys a Istio's minimum components to function.

Run the following command to switch to this profile:

{{< text bash >}}
$ kubectl apply -f https://preliminary.istio.io/operator-profile-minimal.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Verifying the installation

{{< warning >}}
This document is a work in progress. Expect verification steps for each of the profiles to
vary from these verification steps. Inconsistencies will be resolved prior to the publishing of
Istio 1.4. Until that time, these verification steps only apply to the `profile-istio-demo.yaml` profile.
{{< /warning >}}

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

Delete the Istio Operator and Istio deployment:

{{< text bash >}}
$ kubectl -n istio-operator get IstioControlPlane example-istiocontrolplane -o=json | jq '.metadata.finalizers = null' | kubectl delete -f -
$ kubectl delete ns istio-operator --grace-period=0 --force
$ kubectl delete ns istio-system --grace-period=0 --force
{{< /text >}}


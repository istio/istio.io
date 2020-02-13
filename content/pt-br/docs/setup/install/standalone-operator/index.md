---
title: Standalone Operator Install [Experimental]
description: Instructions to install Istio in a Kubernetes cluster using the Istio operator.
weight: 25
keywords: [kubernetes, operator]
aliases:
---

{{< boilerplate experimental-feature-warning >}}

This guide installs Istio using the standalone Istio
[operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
The only dependencies required are a supported Kubernetes cluster and the `kubectl` command.

To install Istio for production use, we recommend [installing with {{< istioctl >}}](/pt-br/docs/setup/install/istioctl/)
instead.

## Prerequisites

1. Perform any necessary [platform-specific setup](/pt-br/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/pt-br/docs/ops/deployment/requirements/).

1. Deploy the Istio operator:

    {{< text bash >}}
    $ kubectl apply -f https://istio.io/operator.yaml
    {{< /text >}}

    This command runs the operator by creating the following resources in the `istio-operator` namespace:

    - The operator custom resource definition
    - The operator controller deployment
    - A service to access operator metrics
    - Necessary Istio operator RBAC rules

## Install

To install the Istio `demo` [configuration profile](/pt-br/docs/setup/additional-setup/config-profiles/)
using the operator, run the following command:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
{{< /text >}}

The controller will detect the `IstioControlPlane` resource and then install the Istio
components corresponding to the specified (`demo`) configuration.

{{< tip >}}
The Istio operator controller begins the process of installing Istio within 90 seconds of
the creation of the `IstioControlPlane` resource. The Istio installation completes within 120
seconds.
{{< /tip >}}

You can confirm the Istio control plane services have been deployed with the following commands:

{{< text bash >}}
$ kubectl get svc -n istio-system
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                                                                      AGE
grafana                  ClusterIP      10.106.149.76    <none>          3000/TCP                                                                                                                     2m
istio-citadel            ClusterIP      10.111.189.16    <none>          8060/TCP,15014/TCP                                                                                                           2m
istio-egressgateway      ClusterIP      10.97.119.223    <none>          80/TCP,443/TCP,15443/TCP                                                                                                     2m
istio-galley             ClusterIP      10.106.200.132   <none>          443/TCP,15014/TCP,9901/TCP,15019/TCP                                                                                         2m
istio-ingressgateway     LoadBalancer   10.107.91.133    192.168.7.130   15020:30729/TCP,80:32583/TCP,443:30117/TCP,15029:30696/TCP,15030:31442/TCP,15031:30091/TCP,15032:31346/TCP,15443:30067/TCP   2m
istio-pilot              ClusterIP      10.109.79.164    <none>          15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                       2m
istio-policy             ClusterIP      10.105.198.243   <none>          9091/TCP,15004/TCP,15014/TCP                                                                                                 2m
istio-sidecar-injector   ClusterIP      10.107.11.188    <none>          443/TCP                                                                                                                      2m
istio-telemetry          ClusterIP      10.104.68.42     <none>          9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                       2m
jaeger-agent             ClusterIP      None             <none>          5775/UDP,6831/UDP,6832/UDP                                                                                                   2m
jaeger-collector         ClusterIP      10.109.110.61    <none>          14267/TCP,14268/TCP,14250/TCP                                                                                                2m
jaeger-query             ClusterIP      10.97.1.46       <none>          16686/TCP                                                                                                                    2m
kiali                    ClusterIP      10.99.4.200      <none>          20001/TCP                                                                                                                    2m
prometheus               ClusterIP      10.99.185.175    <none>          9090/TCP                                                                                                                     2m
tracing                  ClusterIP      10.104.66.2      <none>          9411/TCP                                                                                                                     2m
zipkin                   ClusterIP      10.99.242.51     <none>          9411/TCP                                                                                                                     2m
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                      READY   STATUS    RESTARTS   AGE
grafana-5f798469fd-72hk6                  1/1     Running   0          1m
istio-citadel-7dfd85d968-q2h5t            1/1     Running   0          1m
istio-egressgateway-7f9b4f8b6b-nr889      1/1     Running   0          1m
istio-galley-7474b7b86-jgc6h              1/1     Running   0          1m
istio-ingressgateway-5d97687586-9v4sw     1/1     Running   0          1m
istio-pilot-76dcbf686c-2z98w              1/1     Running   0          1m
istio-policy-7f7f7758c5-h5x8z             1/1     Running   3          1m
istio-sidecar-injector-7795bb5888-l5w6g   1/1     Running   0          1m
istio-telemetry-7f5bfccf69-ld65r          1/1     Running   2          1m
istio-tracing-cd67ddf8-w97mg              1/1     Running   0          1m
kiali-7964898d8c-9gfs4                    1/1     Running   0          1m
prometheus-586d4445c7-ctxlg               1/1     Running   0          1m
{{< /text >}}

## Update

Now, with the controller running, you can change the Istio configuration by editing or replacing
the `IstioControlPlane` resource. The controller will detect the change and respond by updating
the Istio installation correspondingly.

For example, you can switch the installation to the `default`
profile with the following command:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: default
EOF
{{< /text >}}

You can also enable or disable specific features or components.
For example, to disable the telemetry feature:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: default
  telemetry:
    enabled: false
EOF
{{< /text >}}

Refer to the [`IstioControlPlane` API](/pt-br/docs/reference/config/istio.operator.v1alpha12.pb/)
for the complete set of configuration settings.

## Uninstall

Delete the Istio operator and Istio deployment:

{{< text bash >}}
$ kubectl -n istio-operator get IstioControlPlane example-istiocontrolplane -o=json | jq '.metadata.finalizers = null' | kubectl delete -f -
$ kubectl delete ns istio-operator --grace-period=0 --force
$ kubectl delete ns istio-system --grace-period=0 --force
{{< /text >}}

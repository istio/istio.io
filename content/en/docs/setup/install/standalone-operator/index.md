---
title: Standalone Operator Install
description: Instructions to install Istio in a Kubernetes cluster using the Istio operator.
weight: 25
keywords: [kubernetes, operator]
aliases:
---

This guide installs Istio using the standalone Istio
[operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
The only dependencies required are a supported Kubernetes cluster, the `kubectl` and the `istioctl` command at the release version.

To install Istio for production use, we recommend [installing with {{< istioctl >}}](/docs/setup/install/istioctl/)
instead.

## Prerequisites

1. Perform any necessary [platform-specific setup](/docs/setup/platform-setup/).

1. Check the [Requirements for Pods and Services](/docs/ops/deployment/requirements/).

1. Deploy the Istio operator:

    {{< text bash >}}
    $ istioctl operator init
    {{< /text >}}

    This command runs the operator by creating the following resources in the `istio-operator` namespace:

    - The operator custom resource definition
    - The operator controller deployment
    - A service to access operator metrics
    - Necessary Istio operator RBAC rules

## Install

To install the Istio `demo` [configuration profile](/docs/setup/additional-setup/config-profiles/)
using the operator, run the following command:

{{< text bash >}}
$ kubectl create ns istio-system
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
{{< /text >}}

The controller will detect the `IstioOperator` resource and then install the Istio
components corresponding to the specified (`demo`) configuration.

{{< tip >}}
The Istio operator controller begins the process of installing Istio within 90 seconds of
the creation of the `IstioOperator` resource. The Istio installation completes within 120
seconds.
{{< /tip >}}

You can confirm the Istio control plane services have been deployed with the following commands:

{{< text bash >}}
$ kubectl get svc -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                                                                                                      AGE
grafana                     ClusterIP      10.47.246.242   <none>         3000/TCP                                                                                                                     64m
istio-egressgateway         ClusterIP      10.47.244.203   <none>         80/TCP,443/TCP,15443/TCP                                                                                                     64m
istio-ingressgateway        LoadBalancer   10.47.247.221   34.69.50.226   15020:31649/TCP,80:30012/TCP,443:31723/TCP,15029:31857/TCP,15030:31621/TCP,15031:31290/TCP,15032:30334/TCP,15443:31754/TCP   64m
istio-pilot                 ClusterIP      10.47.247.195   <none>         15010/TCP,15011/TCP,15012/TCP,8080/TCP,15014/TCP,443/TCP                                                                     64m
istio-policy                ClusterIP      10.47.241.120   <none>         9091/TCP,15004/TCP,15014/TCP                                                                                                 64m
istiod                      ClusterIP      10.47.247.6     <none>         15012/TCP,443/TCP                                                                                                            64m
jaeger-agent                ClusterIP      None            <none>         5775/UDP,6831/UDP,6832/UDP                                                                                                   64m
jaeger-collector            ClusterIP      10.47.244.102   <none>         14267/TCP,14268/TCP,14250/TCP                                                                                                64m
jaeger-collector-headless   ClusterIP      None            <none>         14250/TCP                                                                                                                    64m
jaeger-query                ClusterIP      10.47.253.168   <none>         16686/TCP                                                                                                                    64m
kiali                       ClusterIP      10.47.246.119   <none>         20001/TCP                                                                                                                    64m
prometheus                  ClusterIP      10.47.240.52    <none>         9090/TCP                                                                                                                     64m
tracing                     ClusterIP      10.47.251.85    <none>         80/TCP                                                                                                                       64m
zipkin                      ClusterIP      10.47.244.132   <none>         9411/TCP                                                                                                                     64m                                                                                                         2m
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
grafana-78bc994d79-gwkfd                1/1     Running   0          63m
istio-egressgateway-5fc6f84745-8f98z    1/1     Running   0          63m
istio-ingressgateway-5b89fc6c98-vkwb5   1/1     Running   0          63m
istio-policy-55d767c454-jggkz           2/2     Running   8          63m
istio-tracing-c7b59f68f-dgqb8           1/1     Running   0          63m
istiod-5448f74684-gmd5w                 1/1     Running   0          52m
kiali-fb5f485fb-2l4r6                   1/1     Running   0          63m
prometheus-7b8875c479-7zsnf             1/1     Running   0          63m
{{< /text >}}

## Update

Now, with the controller running, you can change the Istio configuration by editing or replacing
the `IstioOperator` resource. The controller will detect the change and respond by updating
the Istio installation correspondingly.

For example, you can switch the installation to the `default`
profile with the following command:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
EOF
{{< /text >}}

You can also enable or disable components and modify resource settings.
For example, to enable the `Grafana` component and increase pilot memory requests:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
  components:
    grafana:
      enabled: true
  pilot:
    k8s:
      resources:
        requests:
          memory: 3072Mi
EOF
{{< /text >}}

You can observe the changes that the controller makes in the cluster in response to `IstioOperator` CR updates by
checking the operator controller logs:

{{< text bash >}}
$ kubectl logs -f -n istio-operator $(kubectl get pods -n istio-operator -lname=istio-operator -o jsonpath='{.items[0].metadata.name}')
{{< /text >}}

Refer to the [`IstioOperator` API](https://github.com/istio/api/blob/release-1.5/operator/v1alpha1/operator.proto/)
for the complete set of configuration settings.

## Uninstall

Delete the Istio deployment:

{{< text bash >}}
$ kubectl delete istiooperators.install.istio.io -n istio-system example-istiocontrolplane
{{< /text >}}

Wait until Istio is uninstalled - this may take some time.
Delete the Istio operator:

{{< text bash >}}
$ kubectl delete ns istio-operator --grace-period=0 --force
{{< /text >}}

Note that deleting the operator before Istio is fully removed may result in leftover Istio resources.
To clean up anything not removed by the operator:

{{< text bash >}}
$ istioctl manifest generate | kubectl delete -f -
$ kubectl delete ns istio-system --grace-period=0 --force
 {{< /text >}}

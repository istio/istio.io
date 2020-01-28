---
title: Getting Started
description: Try Istio’s features quickly and easily.
weight: 5
aliases:
    - /docs/setup/kubernetes/getting-started/
    - /docs/setup/kubernetes/
    - /docs/setup/kubernetes/install/kubernetes/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes]
---

This guide is intended for users who are new to Istio and lets you quickly evaluate Istio by installing the
`demo` [configuration profile](/docs/setup/additional-setup/config-profiles/).

If you are already familiar with Istio or interested in installing other configuration profiles
or a more advanced [deployment model](/docs/ops/deployment/deployment-models/),
follow the [installing with {{< istioctl >}} instructions](/docs/setup/install/istioctl) instead.

{{< warning >}}
The demo configuration profile is not suitable for performance evaluation. It
is designed to showcase Istio functionality with high levels of tracing and
access logging.
{{< /warning >}}

1. [Set up your platform](#platform)
1. [Download the release](#download)
1. [Install Istio](#install)
1. [Enable automatic sidecar injection](#enable-injection)
1. [Deploy the Bookinfo sample application](#Bookinfo)

## Set up your platform {#platform}

Before you can install Istio, you need a {{< gloss >}}cluster{{< /gloss >}} running a compatible version of Kubernetes.
Istio {{< istio_version >}} has been tested with Kubernetes releases {{< supported_kubernetes_versions >}}.

Create a cluster by selecting the appropriate [platform-specific setup instructions](/docs/setup/platform-setup/).

Some platforms provide a {{< gloss >}}managed control plane{{< /gloss >}} which you can use instead of
installing Istio manually. If this is the case with your selected platform, and you choose to use it,
you will be finished installing Istio after creating the cluster, so you can skip the following instructions.
For more information, see your platform service provider's documentation.

## Download and install Istio {#download}

Download the Istio release which includes installation files, samples, and the
[{{< istioctl >}}](/docs/reference/commands/istioctl/) command line utility.

1.  Go to the [Istio release]({{< istio_release_url >}}) page to
    download the installation file corresponding to your OS. Alternatively, on a macOS or
    Linux system, you can run the following command to download and
    extract the latest release automatically:

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

1.  Move to the Istio package directory. For example, if the package is
    `istio-{{< istio_full_version >}}`:

    {{< text bash >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    The installation directory contains:

    - Installation YAML files for Kubernetes in `install/kubernetes`
    - Sample applications in `samples/`
    - The [`istioctl`](/docs/reference/commands/istioctl) client binary in the `bin/` directory. `istioctl` is
      used when manually injecting Envoy as a sidecar proxy.

1.  Add the `istioctl` client to your path, on a macOS or
    Linux system:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

1. You can optionally enable the [auto-completion option](/docs/ops/diagnostic-tools/istioctl#enabling-auto-completion) when working with a bash or ZSH console.

## Install Istio {#install}

Follow these steps to install Istio using the `demo` configuration profile on your chosen platform.

1. Install the `demo` profile

    {{< text bash >}}
    $ istioctl manifest apply --set profile=demo
    {{< /text >}}

1. Verify the installation by ensuring the following Kubernetes services are deployed and verify they all
    have an appropriate `CLUSTER-IP` except the `jaeger-agent` service:

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
    If your cluster runs in an environment that does not
    support an external load balancer (e.g., minikube), the
    `EXTERNAL-IP` of `istio-ingressgateway` will display
    `<pending>`. To access the gateway, use the service's
    `NodePort`, or use port-forwarding instead.
    {{< /tip >}}

    Also ensure corresponding Kubernetes pods are deployed and have a `STATUS` of `Running`:

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

## Enable automatic sidecar injection {#enable-injection}

A benefit of Istio is automatic sidecar injection, which allows your applications to work in the service mesh without modification. To take advantage of this feature, enable sidecar injection by adding the `istio-injection=enabled` label to the Kubernetes namespaces in which you plan to deploy your applications. For more information, see [Istio sidecar injector](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection).

{{< warning >}}
The application must use either the HTTP/1.1 or HTTP/2.0 protocols for all its HTTP
traffic; HTTP/1.0 is not supported.
{{< /warning >}}

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
{{< /text >}}

Alternatively, you can manually inject Envoy containers in your application pods before deploying them, using
[`istioctl kube-inject`](/docs/reference/commands/istioctl/#istioctl-kube-inject):

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

## Deploy the Bookinfo sample application {#Bookinfo}

If you have an application ready to go, deploy it:

{{< text bash >}}
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

Alternatively,
[deploy the Bookinfo sample](/docs/examples/bookinfo/)
to evaluate Istio's features for traffic routing,
fault injection, rate limiting, etc. Then, explore the various
[Istio tasks](/docs/tasks/) that interest you.

## Next evaluation steps

After installing Istio and deploying an application,
see the following topics to explore more Istio features:

- [Request routing](/docs/tasks/traffic-management/request-routing/)
- [Fault injection](/docs/tasks/traffic-management/fault-injection/)
- [Traffic shifting](/docs/tasks/traffic-management/traffic-shifting/)
- [Querying metrics](/docs/tasks/observability/metrics/querying-metrics/)
- [Visualizing metrics](/docs/tasks/observability/metrics/using-istio-dashboard/)
- [Collecting logs](/docs/tasks/observability/logs/collecting-logs/)
- [Rate limiting](/docs/tasks/policy-enforcement/rate-limiting/)
- [Ingress gateways](/docs/tasks/traffic-management/ingress/ingress-control/)
- [Accessing external services](/docs/tasks/traffic-management/egress/egress-control/)
- [Visualizing your mesh](/docs/tasks/observability/kiali/)

## Prepare for production deployment

Before you install and customize Istio for production use,
see the following topics:

- [Deployment models](/docs/ops/deployment/deployment-models/)
- [Deployment best practices](/docs/ops/best-practices/deployment/)
- [Pod requirements](/docs/ops/deployment/requirements/)
- [General installation instructions](/docs/setup/)

## Engage with the community

We invite you to join our [community](/about/community/join/)
and share your feedback and suggestions to improve Istio.

## Uninstall Istio {#uninstall}

The uninstall deletes the `istio-system` namespace and the resources in it,
including any associated RBAC permissions. The uninstall command might generate errors
about non-existent resources, which you can ignore:

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}

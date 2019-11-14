---
title: Getting Started
description: Download, install, and learn how to evaluate and try Istio’s basic features quickly.
weight: 5
aliases:
    - /docs/setup/kubernetes/getting-started/
    - /docs/setup/kubernetes/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes]
---

To get started with Istio, just follow these steps:

- [Set up your platform](#platform)
- [Download the Istio release](#download)
- [Install Istio](#install)

## Set up your platform {#platform}

Before you can install Istio, you need a {{< gloss >}}cluster{{< /gloss >}} running a compatible version of Kubernetes.
Istio {{< istio_version >}} has been tested with Kubernetes releases {{< supported_kubernetes_versions >}}.

- Create a cluster by selecting the appropriate [platform-specific setup instructions](/docs/setup/platform-setup/).

Some platforms provide a {{< gloss >}}managed control plane{{< /gloss >}} which you can use instead of
installing Istio manually. If this is the case with your selected platform, and you choose to use it,
you will be finished installing Istio after creating the cluster, so you can skip the following instructions.
Refer to your platform service provider for further details and instructions.

## Download the release {#download}

Download the Istio release which includes installation files, samples, and the
[{{< istioctl >}}](/docs/reference/commands/istioctl/) command line utility.

1.  Go to the [Istio release]({{< istio_release_url >}}) page to
    download the installation file corresponding to your OS. Alternatively, on a macOS or
    Linux system, you can run the following command to download and
    extract the latest release automatically:

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_full_version >}} sh -
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

These instructions assume you are new to Istio, providing streamlined instruction to
install Istio's built-in `demo` [configuration profile](/docs/setup/additional-setup/config-profiles/).
This installation lets you quickly get started evaluating Istio.
If you are already familiar with Istio or interested in installing other configuration profiles
or a more advanced [deployment model](/docs/ops/prep/deployment-models/),
follow the [installing with {{< istioctl >}} instructions](/docs/setup/install/istioctl) instead.

{{< warning >}}
The demo configuration profile is not suitable for performance evaluation. It
is designed to showcase Istio functionality with high levels of tracing and
access logging.
{{< /warning >}}

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
    If your cluster is running in an environment that does not
    support an external load balancer (e.g., minikube), the
    `EXTERNAL-IP` of `istio-ingressgateway` will say
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

## Next steps

With Istio installed, you can now deploy your own application or one of the sample applications
provided with the installation.

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

If you are not sure where to begin,
[deploy the Bookinfo sample](/docs/examples/bookinfo/#deploying-the-application)
which will allow you to evaluate Istio's features for traffic routing, fault injection, rate
limiting, etc. Then explore the various [Istio tasks](/docs/tasks/) that interest you.

The following tasks are a good place for beginners to start:

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

Before you install and customize Istio to fit your platform and intended use,
check out the following resources:

- [Deployment models](/docs/ops/prep/deployment-models/)
- [Deployment best practices](/docs/ops/prep/deployment/)
- [Pod requirements](/docs/ops/prep/requirements/)
- [General installation instructions](/docs/setup/)

Once you have a deployment that suits your needs, the next step is to deploy
your own applications.

As you continue to use Istio, we look forward to hearing from you and welcoming
you to our [community](/about/community/join/).

## Uninstall

The uninstall deletes the RBAC permissions, the `istio-system` namespace, and
all resources hierarchically under it. It is safe to ignore errors for
non-existent resources because they may have been deleted hierarchically.

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}

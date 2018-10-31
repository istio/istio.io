---
title: Control Egress Traffic
description: Describes how to configure Istio to route traffic from services in the mesh to external services.
weight: 40
aliases:
    - /docs/tasks/egress.html
keywords: [traffic-management,egress]
---

By default, Istio-enabled services are unable to access URLs outside of the cluster because the pod uses
iptables to transparently redirect all outbound traffic to the sidecar proxy,
which only handles intra-cluster destinations.

This task describes how to configure Istio to expose external services to Istio-enabled clients.
You'll learn how to enable access to external services by defining
[`ServiceEntry`](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) configurations,
or alternatively, to bypass the Istio proxy for a specific range of IPs.

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Start the [sleep]({{< github_tree >}}/samples/sleep) sample
    which you use as a test source for external calls.

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), deploy the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    Otherwise, you have to manually inject the sidecar before deploying the `sleep` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    Note that any pod that you can `exec` and `curl` from will do for the procedures below.

*   Set the `SOURCE_POD` environment variable to the deployed `sleep` pod:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Configuring Istio external services

Using Istio `ServiceEntry` configurations, you can access any publicly accessible service
from within your Istio cluster. This task shows you how to access an external HTTP service,
[httpbin.org](http://httpbin.org), as well as an external HTTPS service,
[www.google.com](https://www.google.com).

### Configuring an external HTTP service

1.  Create a `ServiceEntry` to allow access to an external HTTP service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-ext
    spec:
      hosts:
      - httpbin.org
      ports:
      - number: 80
        name: http
        protocol: HTTP
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Exec into the `sleep service` source pod:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep bash
    {{< /text >}}

1.  Make a request to the external HTTP service:

    {{< text bash >}}
    $ curl http://httpbin.org/headers
    {{< /text >}}

### Configuring an external HTTPS service

1.  Create a `ServiceEntry` to allow access to an external HTTPS service.
    For TLS protocols, including HTTPS, a `VirtualService` is required in addition to the `ServiceEntry`.
    Without it, exactly what service or services are exposed by the `ServiceEntry` is undefined.
    The `VirtualService` must include a `tls` rule with `sni_hosts` in the `match` clause to enable SNI routing.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: google
    spec:
      hosts:
      - www.google.com
      ports:
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
      location: MESH_EXTERNAL
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: google
    spec:
      hosts:
      - www.google.com
      tls:
      - match:
        - port: 443
          sni_hosts:
          - www.google.com
        route:
        - destination:
            host: www.google.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Exec into the `sleep service` source pod:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep bash
    {{< /text >}}

1.  Make a request to the external HTTPS service:

    {{< text bash >}}
    $ curl https://www.google.com
    {{< /text >}}

### Setting route rules on an external service

Similar to inter-cluster requests, Istio
[routing rules](/docs/concepts/traffic-management/#rule-configuration)
can also be set for external services that are accessed using `ServiceEntry` configurations.
In this example, you set a timeout rule on calls to the `httpbin.org` service.

1.  From inside the pod being used as the test source, make a _curl_ request to the `/delay` endpoint of the httpbin.org external service:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep bash
    $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
    200

    real    0m5.024s
    user    0m0.003s
    sys     0m0.003s
    {{< /text >}}

    The request should return 200 (OK) in approximately 5 seconds.

1.  Exit the source pod and use `kubectl` to set a 3s timeout on calls to the `httpbin.org` external service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin-ext
    spec:
      hosts:
        - httpbin.org
      http:
      - timeout: 3s
        route:
          - destination:
              host: httpbin.org
            weight: 100
    EOF
    {{< /text >}}

1.  Wait a few seconds, then make the _curl_ request again:

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep bash
    $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
    504

    real    0m3.149s
    user    0m0.004s
    sys     0m0.004s
    {{< /text >}}

    This time a 504 (Gateway Timeout) appears after 3 seconds.
    Although httpbin.org was waiting 5 seconds, Istio cut off the request at 3 seconds.

## Calling external services directly

If you want to completely bypass Istio for a specific IP range,
you can configure the Envoy sidecars to prevent them from
[intercepting](/docs/concepts/traffic-management/#communication-between-services)
the external requests. This can be done by setting the `global.proxy.includeIPRanges` variable of
[Helm](/docs/reference/config/installation-options/) and updating the `ConfigMap` _istio-sidecar-injector_ by using `kubectl apply`. After _istio-sidecar-injector_ is updated, the value of `global.proxy.includeIPRanges` will affect all the future deployments of the application pods.

The simplest way to use the `global.proxy.includeIPRanges` variable is to pass it the IP range(s)
used for internal cluster services, thereby excluding external IPs from being redirected
to the sidecar proxy.
The values used for internal IP range(s), however, depends on where your cluster is running.
For example, with Minikube the range is 10.0.0.1&#47;24, so you would update your `ConfigMap` _istio-sidecar-injector_ like this:

{{< text bash >}}
$ helm template install/kubernetes/helm/istio <the flags you used to install Istio> --set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -
{{< /text >}}

Note that you should use the same Helm command you used [to install Istio](/docs/setup/kubernetes/helm-install),
in particular, the same value of the `--namespace` flag. In addition to the flags you used to install Istio, add `--set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml`.

Redeploy the `sleep` application as described in the [Before you begin](/docs/tasks/traffic-management/egress/#before-you-begin) section.

### Set the value of `global.proxy.includeIPRanges`

Set the value of `global.proxy.includeIPRanges` according to your cluster provider.

#### IBM Cloud Private

1.  Get your `service_cluster_ip_range` from IBM Cloud Private configuration file under `cluster/config.yaml`:

    {{< text bash >}}
    $ cat cluster/config.yaml | grep service_cluster_ip_range
    {{< /text >}}

    The following is a sample output:

    {{< text plain >}}
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  Use `--set global.proxy.includeIPRanges="10.0.0.1/24"`

#### IBM Cloud Kubernetes Service

Use `--set global.proxy.includeIPRanges="172.30.0.0/16\,172.20.0.0/16\,10.10.10.0/24"`

#### Google Container Engine (GKE)

The ranges are not fixed, so you will need to run the `gcloud container clusters describe` command to determine the ranges to use. For example:

{{< text bash >}}
$ gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
{{< /text >}}

Use `--set global.proxy.includeIPRanges="10.4.0.0/14\,10.7.240.0/20"`

#### Azure Container Service(ACS)

Use `--set global.proxy.includeIPRanges="10.244.0.0/16\,10.240.0.0/16`

#### Minikube

Use `--set global.proxy.includeIPRanges="10.0.0.1/24"`

#### Docker For Desktop

Use `--set global.proxy.includeIPRanges="10.96.0.0/12"`

#### Bare Metal

Use the value of your `service-cluster-ip-range`.  It's not fixed, but the default value is 10.96.0.0/12.  To determine your actual value:

{{< text bash >}}
$ kubectl describe pod kube-apiserver -n kube-system | grep 'service-cluster-ip-range'
      --service-cluster-ip-range=10.96.0.0/12
{{< /text >}}

### Access the external services

After updating the `ConfigMap` _istio-sidecar-injector_ and redeploying the `sleep` application,
the Istio sidecar will only intercept and manage internal requests
within the cluster. Any external request bypasses the sidecar and goes straight to its intended destination. For example:

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl exec -it $SOURCE_POD -c sleep curl http://httpbin.org/headers
{{< /text >}}

## Understanding what happened

In this task you looked at two ways to call external services from an Istio mesh:

1. Using a `ServiceEntry` (recommended).

1. Configuring the Istio sidecar to exclude external IPs from its remapped IP table.

The first approach, using `ServiceEntry`, lets
you use all of the same Istio service mesh features for calls to services inside or outside
of the cluster. You saw this by setting a timeout rule for calls to an external service.

The second approach bypasses the Istio sidecar proxy, giving your services direct access to any
external URL. However, configuring the proxy this way does require
cluster provider specific knowledge and configuration.

## Cleanup

1.  Remove the rules:

    {{< text bash >}}
    $ kubectl delete serviceentry httpbin-ext google
    $ kubectl delete virtualservice httpbin-ext google
    {{< /text >}}

1.  Shutdown the [sleep]({{< github_tree >}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Update the `ConfigMap` _istio-sidecar-injector_ to redirect all outbound traffic to the sidecar proxies:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio <the flags you used to install Istio> -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -
    {{< /text >}}

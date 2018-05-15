---
title: Control Egress Traffic
description: Describes how to configure Istio to route traffic from services in the mesh to external services.

weight: 40

redirect_from: /docs/tasks/egress.html
---
{% include home.html %}

By default, Istio-enabled services are unable to access URLs outside of the cluster because
iptables is used in the pod to transparently redirect all outbound traffic to the sidecar proxy,
which only handles intra-cluster destinations.

This task describes how to configure Istio to expose external services to Istio-enabled clients.
You'll learn how to enable access to external services using egress rules,
or alternatively, to simply bypass the Istio proxy for a specific range of IPs.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).

* Start the [sleep](https://github.com/istio/istio/tree/master/samples/sleep) sample
  which will be used as a test source for external calls.

  ```command
  $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
  ```

  Note that any pod that you can `exec` and `curl` from would do.

## Using Istio egress rules

Using Istio egress rules, you can access any publicly accessible service
from within your Istio cluster. In this task we will use
[httpbin.org](https://httpbin.org) and [www.google.com](https://www.google.com) as examples.

### Configuring the external services

1. Create an egress rule to allow access to an external HTTP service:

   ```bash
   cat <<EOF | istioctl create -f -
   apiVersion: config.istio.io/v1alpha2
   kind: EgressRule
   metadata:
     name: httpbin-egress-rule
   spec:
     destination:
       service: httpbin.org
     ports:
       - port: 80
         protocol: http
   EOF
   ```

1. Create an egress rule to allow access to an external HTTPS service:

   ```bash
   cat <<EOF | istioctl create -f -
   apiVersion: config.istio.io/v1alpha2
   kind: EgressRule
   metadata:
     name: google-egress-rule
   spec:
     destination:
       service: www.google.com
     ports:
       - port: 443
         protocol: https
   EOF
   ```

### Make requests to the external services

1. Exec into the pod being used as the test source. For example,
   if you are using the sleep service, run the following commands:

   ```command
   $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
   $ kubectl exec -it $SOURCE_POD -c sleep bash
   ```

1. Make a request to the external HTTP service:

   ```command
   $ curl http://httpbin.org/headers
   ```

1. Make a request to the external HTTPS service.
   External services of type HTTPS must be accessed over HTTP with the port specified in the request:

   ```command
   $ curl http://www.google.com:443
   ```

### Setting route rules on an external service

Similar to inter-cluster requests, Istio
[routing rules]({{home}}/docs/concepts/traffic-management/rules-configuration.html)
can also be set for external services that are accessed using egress rules.
To illustrate we will use [istioctl]({{home}}/docs/reference/commands/istioctl.html)
to set a timeout rule on calls to the httpbin.org service.

1. From inside the pod being used as the test source, invoke the `/delay` endpoint of the httpbin.org external service:

   ```command
   $ kubectl exec -it $SOURCE_POD -c sleep bash
   $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
   200

   real    0m5.024s
   user    0m0.003s
   sys     0m0.003s
   ```

   The request should return 200 (OK) in approximately 5 seconds.

1. Exit the source pod and use `istioctl` to set a 3s timeout on calls to the httpbin.org external service:

   ```bash
   cat <<EOF | istioctl create -f -
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: httpbin-timeout-rule
   spec:
     destination:
       service: httpbin.org
     http_req_timeout:
       simple_timeout:
         timeout: 3s
   EOF
   ```

1. Wait a few seconds, then issue the _curl_ request again:

   ```command
   $ kubectl exec -it $SOURCE_POD -c sleep bash
   $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
   504

   real    0m3.149s
   user    0m0.004s
   sys     0m0.004s
   ```

   This time a 504 (Gateway Timeout) appears after 3 seconds.
   Although httpbin.org was waiting 5 seconds, Istio cut off the request at 3 seconds.

## Calling external services directly

The Istio egress rules currently only supports HTTP/HTTPS requests.
If you want to access services with other protocols (e.g., mongodb://host/database),
or if you want to completely bypass Istio for a specific IP range,
you will need to configure the source service's Envoy sidecar to prevent it from
[intercepting]({{home}}/docs/concepts/traffic-management/request-routing.html#communication-between-services)
the external requests. This can be done using the `--includeIPRanges` option of
[istioctl kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl kube-inject)
when starting the service.

The simplest way to use the `--includeIPRanges` option is to pass it the IP range(s)
used for internal cluster services, thereby excluding external IPs from being redirected
to the sidecar proxy.
The values used for internal IP range(s), however, depends on where your cluster is running.
For example, with Minikube the range is 10.0.0.1/24, so you would start the sleep service like this:

```command
$ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml --includeIPRanges=10.0.0.1/24)
```

On IBM Cloud Private, use:

1. Get your `service_cluster_ip_range` from IBM Cloud Private configuration file under `cluster/config.yaml`.

   ```command
   $ cat cluster/config.yaml | grep service_cluster_ip_range
   service_cluster_ip_range: 10.0.0.1/24
   ```

1. Inject the `service_cluster_ip_range` to your application profile via `--includeIPRanges` to limit Istio's traffic interception to the service cluster IP range.

   ```command
   $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml --includeIPRanges=10.0.0.1/24)
   ```

On IBM Cloud Container Service, use:

```command
$ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16,10.10.10.0/24)
```

On Google Container Engine (GKE) the ranges are not fixed, so you will
need to run the `gcloud container clusters describe` command to determine the ranges to use. For example:

```command
$ gcloud container clusters describe <cluster_name> --zone <zone> | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
```

```command
$ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml --includeIPRanges=10.4.0.0/14,10.7.240.0/20)
```

On Azure Container Service(ACS), use:

```command
$ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml --includeIPRanges=10.244.0.0/16,10.240.0.0/16)
```

After starting your service this way, the Istio sidecar will only intercept and manage internal requests
within the cluster. Any external request will simply bypass the sidecar and go straight to its intended
destination.

```command
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl exec -it $SOURCE_POD -c sleep curl http://httpbin.org/headers
```

## Understanding what happened

In this task we looked at two ways to call external services from within an Istio cluster:

1. Using an egress rule (recommended)

1. Configuring the Istio sidecar to exclude external IPs from its remapped IP table

The first approach (egress rule) currently only supports HTTP(S) requests, but allows
you to use all of the same Istio service mesh features for calls to services within or outside
of the cluster. We demonstrated this by setting a timeout rule for calls to an external service.

The second approach bypasses the Istio sidecar proxy, giving your services direct access to any
external URL. However, configuring the proxy this way does require
cloud provider specific knowledge and configuration.

## Cleanup

1. Remove the rules.

   ```command
   $ istioctl delete egressrule httpbin-egress-rule google-egress-rule
   $ istioctl delete routerule httpbin-timeout-rule
   ```

1. Shutdown the [sleep](https://github.com/istio/istio/tree/master/samples/sleep) service.

   ```command
   $ kubectl delete -f samples/sleep/sleep.yaml
   ```

## Egress Rules and Access Control

Note that Istio Egress Rules are **not a security feature**. They enable access to external (out of the service mesh) services. It is up to the user to deploy appropriate security mechanisms such as firewalls to prevent unauthorized access to the external services. We are working on adding access control support for the external services.

## What's next

* Read more about [egress rules]({{home}}/docs/concepts/traffic-management/rules-configuration.html#egress-rules).

* Learn how to setup
  [timeouts]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#httptimeout),
  [retries]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#httpretry),
  and [circuit breakers]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#circuitbreaker) for egress traffic.

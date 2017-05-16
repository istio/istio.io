---
title: Enabling Egress Traffic
overview: Describes how to configure Istio to route traffic from services in the mesh to external services.

order: 40

layout: docs
type: markdown
---
{% include home.html %}

By default, Istio-enabled services are unable to access URLs outside of the cluster because
iptables is used in the pod to transparently redirect all outbound traffic to the sidecar proxy,
which only handles intra-cluster destinations.
  
This task describes how to configure Istio to expose external services to Istio-enabled clients.
You'll learn how to configure an external service and make requests to it via the Istio egress
service or, alternatively, to simply enable direct calls to an external service.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](./installing-istio.html).

* Start the [sleep](https://github.com/istio/istio/tree/master/samples/apps/sleep) sample
  which will be used as a test source for external calls.
  
  ```bash
  kubectl apply -f <(istioctl kube-inject -f samples/apps/sleep/sleep.yaml)
  ```

  Note that any pod that you can `exec` and `curl` from would do.

## Using the Istio Egress service

Using the Istio Egress service, you can access any publicly accessible service
from within your Istio cluster. In this task we will use 
[httpbin.org](http://httpbin.org) and [www.google.com](www.google.com) as examples.

### Configuring the external services

1. Register an external HTTP service:

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: v1
   kind: Service
   metadata:
    name: externalbin
   spec:
    type: ExternalName
    externalName: httpbin.org
    ports:
    - port: 80
      # important to set protocol name
      name: http
   EOF
   ```

2. Register an external HTTPS service:

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: v1
   kind: Service
   metadata:
    name: securegoogle
   spec:
    type: ExternalName
    externalName: www.google.com
    ports:
    - port: 443
      # important to set protocol name
      name: https
   EOF
   ```
   
The `metadata.name` field is the url your internal apps will use when calling the external service.
The `spec.externalName` is the DNS name of the external service.
Egress Envoy expects external services to be listening on either port `80` for
HTTP or port `443` for HTTPS.

### Make requests to the external services

1. Exec into the pod being used as the test source. For example,
   if you are using the sleep service, run the following commands:
   
   ```bash
   export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
   kubectl exec -it $SOURCE_POD -c sleep bash
   ```

2. Make a request to an external service using the `name` from the Service spec
   above followed by the path to the desired API endpoint:

   ```bash
   curl http://externalbin/headers
   ```

3. For external services of type HTTPS, the port must be specified in the request.
   App clients should make the request over HTTP since the Egress Envoy will initiate HTTPS 
   with the external service:

   ```bash
   curl http://securegoogle:443
   ```

## Calling external services directly

The Istio Egress service currently only supports HTTP/HTTPS requests.
If you want to access services with other protocols (e.g., mongodb://host/database), 
or if you simply don't want to use the
Egress proxy, you will need to configure the source service's Envoy sidecar to prevent it from 
[intercepting]({{home}}/docs/concepts/traffic-management/request-routing.html#communication-between-services)
the external requests. This can be done using the `--includeIPRanges` option of
[istioctl kube-inject]({{home}}/docs/reference/commands/istioctl.html#istioctl-kube-inject)
when starting the service.

The simplest way to use the `--includeIPRanges` option is to pass it the IP range(s)
used for internal cluster services, thereby excluding external IPs from being redirected
to the sidecar proxy.
The values used for internal IP range(s), however, depends on where your cluster is running. 
For example, with Minikube the range is 10.0.0.1/24, so you would start the sleep service like this:

```bash
kubectl apply -f <(istioctl kube-inject -f samples/apps/sleep/sleep.yaml --includeIPRanges=10.0.0.1/24)
```

On IBM Bluemix, use:

```bash
kubectl apply -f <(istioctl kube-inject -f samples/apps/sleep/sleep.yaml --includeIPRanges=172.30.0.0/16,172.20.0.0/16)
```

On Google Container Engine (GKE) the ranges are not fixed, so you will
need to run the `gcloud container clusters describe` command to determine the ranges to use. For example:

```bash
gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
```
```
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
```
```bash
kubectl apply -f <(istioctl kube-inject -f samples/apps/sleep/sleep.yaml --includeIPRanges=10.4.0.0/14,10.7.240.0/20)
```

After starting your service this way, the Istio sidecar will only intercept and manage internal requests
within the cluster. Any external request will simply bypass the sidecar and go straight to its intended
destination.

```bash
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
kubectl exec -it $SOURCE_POD -c sleep curl http://httpbin.org/headers
```

## Understanding what happened

In this task we looked at two ways to call external services from within an Istio cluster:

1. Using the Istio egress service (recommended)

2. Configuring the Istio sidecar to exclude external IPs from its remapped IP table

The first approach (Egress service) currently only supports HTTP(S) requests, but allows
you to use all of the same Istio service mesh features for calls to services within or outside 
of the cluster.

The second approach bypasses the Istio sidecar proxy, giving your services direct access to any
external URL. However, configuring the proxy this way does require
cloud provider specific knowledge and configuration.


## Cleanup

1. Remove the external services.
    
   ```bash
   kubectl delete service externalbin securegoogle 
   ```

1. Shutdown the [sleep](https://github.com/istio/istio/tree/master/samples/apps/sleep) service.

   ```
   kubectl delete -f samples/apps/sleep/sleep.yaml
   ```


## What's next

* Read more about the [egress service]({{home}}/docs/concepts/traffic-management/request-routing.html#ingress-and-egress-envoys).

* Learn how to use Istio's [request routing](./request-routing.html) features.

---
title: Accessing a Service with Egress Envoy
overview: Describes how to configure Istio to expose an external service to a Kubernetes cluster.

order: 10

layout: docs
type: markdown
---


This task describes how to configure Istio to expose an external service to a Kubernetes cluster. You'll learn how
to create an Egress Envoy, define an external service and make requests to the service from within the cluster.


## Before you begin

This task assumes you have deployed Istio on Kubernetes.  If you have not done so, please first complete
the [Installation Steps](/docs/tasks/installing-istio.html).

This task also assumes you have a publicly accessible service to call from within the cluster
(or [httpbin.org](http://httpbin.org) can be used as an example).

### Setup the environment

Create the external service definition for your external service or use one of the samples below.  The `metadata.name`
field is the url your internal apps will use when calling the external service.  The `spec.externalName` should be the
DNS name for the external service.  Egress Envoy expects external services to be listening on either port `80` for
HTTP or port `443` for HTTPS.

HTTP Example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: httpbin
spec:
  type: ExternalName
  externalName: httpbin.org
  ports:
  - port: 80
```

HTTPS Example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: securegoogle
spec:
  type: ExternalName
  externalName: www.google.com
  ports:
  - port: 443
```

Deploy your app(s) using the [istioctl kube-inject](/docs/reference/commands/istioctl/istioctl_kube-inject.html) command.
You can use your own app, or try one of the example apps from [demos](https://github.com/istio/istio/tree/master/demos)
directory. Each app directory contains an associated README.md providing more details.

```bash
kubectl apply -f <(istioctl kube-inject -f {resource.yaml})
```


### Make a request to the external service

Make a request to the external service using the `name` from the Service spec above followed by the path to the
desired API endpoint.

```bash
kubectl exec -it {APP_POD_NAME} curl http://httpbin/headers
.. response ..
```

For external services of type HTTPS, the port must be specified in the request.  App clients should make the request
over HTTP since the Egress Envoy will initiate HTTPS with the external service:

```bash
kubectl exec -it {APP_POD_NAME} curl http://securegoogle:443
.. response ..
```

## Understanding ...

/Here's an interesting thing to know about the steps you just did.

## What's next

* See how to make requests to services inside a cluster by using the [Ingress Controller](/docs/tasks/ingress.html).

---
title: Accessing a Service with Egress
headline: Accessing a Service with Egress
sidenav: doc-side-tasks-nav.html
bodyclass: docs
layout: docs
type: markdown
---


This task describes how to configure Istio to expose an external service to a Kubernetes cluster. You'll learn how 
to create an Egress proxy, define an external service and make requests to the service from within the cluster.


## Doing ...

## Before you begin

This task assumes you have deployed Istio on Kubernetes.  If you have not done so, please first complete
the [Installation Steps]({{site.bareurl}}/docs/tasks/istio-installation.html).

This task also assumes you have a publicly accessible service to call from within the cluster 
(or [httpbin.org](http://httpbin.org) can be used as an example). 

### Setup the environment

Create the Istio Egress proxy.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: istio-egress
spec:
  ports:
  - port: 80
    name: "80"
  selector:
    app: istio-egress
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: istio-egress
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: istio-egress
    spec:
      containers:
      - name: proxy
        image: docker.io/istio/proxy:2017-04-13-01.05.21
        imagePullPolicy: Always
        args: ["proxy", "egress", "-v", "2"]
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
```

Create the external service definition for you external service or use one of the samples below.  The `metadata.name` 
field is the url your internal apps will use when calling the external service.  The `spec.ExternalName` should be the 
DNS name for the external service.  Egress proxy expects external services to be listening on either port `80` for 
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
    name: http
```

HTTPS Example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: httpsgoogle
spec:
  type: ExternalName
  externalName: www.google.com
  ports:
  - port: 443
    name: https
```

Deploy your app(s) using the [istioctl kube-inject]({{site.bareurl}}/docs/reference/istioctl.html#kube-inject) command.
You can use your own app, or try one of the example apps from [demos](https://github.com/istio/istio/tree/master/demos) 
directory. Each app directory contains an associated README.md providing more details.

```bash
kubectl apply -f <(istioctl kube-inject -f {resource.yaml})
```


### Make a request to the external service

Make a request to the external service using the `name` from the Service spec above followed by the path to the 
desired API endpoint.

```bash
$ kubectl exec -it {APP_POD_NAME} curl httpbin/headers
.. response ..
```

For external services of type HTTPS, the port must be specified in the request:

```bash
$ kubectl exec -it {APP_POD_NAME} curl httpsgoogle:443
.. response ..
```

## Understanding ...

Here's an interesting thing to know about the steps you just did.

## What's next
* See how to make requests to services inside a cluster by using the [Ingress Controller]({{site.bareurl}}/docs/tasks/ingress.html).
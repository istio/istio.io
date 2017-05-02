---
title: Configuring Ingress with Envoy
overview: This task describes how to configure Ingress in Kubernetes with Envoy

order: 30

layout: docs
type: markdown
---

This task describes how to configure Istio to expose a service in a Kubernetes cluster.
You'll learn how to create an Ingress controller, define a Ingress Resource and make requests to the service.

In a Kubernetes environment, Istio uses [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) to configure ingress behavior.   


## Before you begin

This task assumes you have deployed Istio on Kubernetes.  If you have not done so, please first complete
the [Installation Steps]({{site.bareurl}}/docs/tasks/istio-installation.html).

## Configuring Ingress

### Setup the environment
Create an example service.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: HelloWorld
  labels:
    app: HelloWorld
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: HelloWorld
---
apiVersion: extensions/v1beta1
kind: Deployment
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: app
        image: <image name>
        imagePullPolicy: Always
        ports:
        - containerPort: 80
```

Create an Ingress Resource. See [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) for more information.

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: istio-ingress
  annotations:
    kubernetes.io/ingress.class: "istio"
spec:
  rules:
  - http:
      paths:
      - path: /hello
        backend:
          serviceName: helloworld
          servicePort: 80
```

### Make a request to the service

Get the Ingress controller IP.

```bash
$ kubectl get ingress istio-ingress
NAME      HOSTS     ADDRESS          PORTS     AGE
ingress   *         192.168.99.100   80        2m
```

Make a request to the HelloWorld service using the Ingress controller IP and the path configured in the Ingress Resource.

```bash
$ curl http://192.168.99.100:80/hello
.. response ..
```

## Understanding ...

Here's an interesting thing to know about the steps you just did.

## What's next
* Learn more about [this](...).
* See this [related task](...).
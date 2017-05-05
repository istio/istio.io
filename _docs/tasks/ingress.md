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
the [Installation Steps](./installing-istio.html).

## Configuring Ingress

The following sections describe how to create 

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
        image: <echo server image name>
        imagePullPolicy: Always
        ports:
        - containerPort: 80
```

### Generate keys
If necessary, a private key and certificate can be created for testing using [OpenSSL](https://www.openssl.org/).
```
openssl req -newkey rsa:2048 -nodes -keyout cert.key -x509 -days -out='cert.crt' -subj '/C=US/ST=Seattle/O=Example/CN=secure.example.io'
```

### Create the secret
Create the secret using `kubectl`.
```bash
kubectl create secret generic ingress-secret --from-file=tls.key=cert.key --from-file=tls.crt=cert.crt
```

### Create Ingress Resources
See [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) for more information.

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: istio-ingress
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  rules:
  - http:
      paths:
      - path: /hello
        backend:
          serviceName: helloworld
          servicePort: 80
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: secured-ingress
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  tls:
    - secretName: ingress-secret
  rules:
  - http:
      paths:
      - path: /hello
        backend:
          serviceName: helloworld
          servicePort: 80
```

### Make requests to the services

Get the Ingress controller IP.

```bash
kubectl get ingress istio-ingress
NAME      HOSTS     ADDRESS          PORTS     AGE
ingress   *         192.168.99.100   80        2m
```

Make a requests to the HelloWorld service using the Ingress controller IP and the path configured in the Ingress Resources.

```bash
curl http://192.168.99.100:80/hello
.. response ..
$ curl -k https://192.168.99.100:80/hello
.. response ..
```

## Understanding ...

Here's an interesting thing to know about the steps you just did.

## What's next
* Learn more about [this](...).
* See this [related task](...).
---
title: InvalidApplicationUID
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a workload is running as User ID (UID) `1337`. Application pods should not run as user ID (UID) `1337` because the istio-proxy container runs as UID `1337`. Running your application containers using the same UID would result in conflicts with its `iptables` configurations.

{{< warning >}}
User ID (UID) `1337` is reserved for the sidecar proxy.
{{< /warning >}}

## An example

Consider a `Deployment` with `securityContext.runAsUser` running either at Pod level or at container level using UID `1337`:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-con-sec-uid
  labels:
    app: helloworld
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helloworld
      version: v1
  template:
    metadata:
      labels:
        app: helloworld
        version: v1
    spec:
      securityContext:
        runAsUser: 1337
      containers:
      - name: helloworld
        image: docker.io/istio/examples-helloworld-v1
        securityContext:
          runAsUser: 1337
        resources:
          requests:
            cpu: "100m"
        imagePullPolicy: IfNotPresent #Always
        ports:
        - containerPort: 5000
{{< /text >}}

## How to resolve

Because the User ID (UID) `1337` is reserved for the sidecar proxy, you can use a different User ID (UID) such as `1338` for your workload.

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-con-sec-uid
  labels:
    app: helloworld
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helloworld
      version: v1
  template:
    metadata:
      labels:
        app: helloworld
        version: v1
    spec:
      securityContext:
        runAsUser: 1338
      containers:
      - name: helloworld
        image: docker.io/istio/examples-helloworld-v1
        securityContext:
          runAsUser: 1338
        resources:
          requests:
            cpu: "100m"
        imagePullPolicy: IfNotPresent #Always
        ports:
        - containerPort: 5000
{{< /text >}}

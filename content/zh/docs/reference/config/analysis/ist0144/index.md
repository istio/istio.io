---
title: InvalidApplicationUID
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当工作负载以 User ID (UID) `1337` 运行时，会出现此消息。应用程序的 Pod 不应该以
User ID (UID) `1337` 运行，因为 istio-proxy 容器默认以 UID `1337` 运行。
当使用相同的 UID 运行您的容器应用时，将导致它的 `iptables` 配置冲突。

{{< warning >}}
User ID (UID) `1337` 保留用于 Sidecar Proxy。
{{< /warning >}}

## 示例 {#an-example}

探讨设置为 `securityContext.runAsUser` 的 `Deployment` 如何使用 UID `1337`
在 Pod 级别或容器级别运行：

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

## 如何修复 {#how-to-resolve}

由于 User ID (UID) `1337` 是为 Sidecar 代理保留的，所以您可以为您的工作负载使用除了
`1337` 以外的 User ID (UID)，例如 `1338`。

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

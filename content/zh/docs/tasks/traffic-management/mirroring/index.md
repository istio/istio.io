---
title: 镜像
description: 此任务演示了 Istio 的流量镜像/影子功能。
weight: 60
keywords: [traffic-management,mirroring]
owner: istio/wg-networking-maintainers
test: yes
---

此任务演示了 Istio 的流量镜像功能。

流量镜像，也称为影子流量，是一种以尽可能低的风险允许负责功能特性的团队改动生产环境的强大理念。
镜像会将实时流量的副本发送到镜像服务。镜像流量发生在主服务的关键请求路径之外。

在此任务中，首先把流量全部路由到测试服务的 `v1` 版本。然后，执行规则将一部分流量镜像到 `v2` 版本。

{{< boilerplate gateway-api-support >}}

## 开始之前 {#before-you-begin}

1. 按照[安装指南](/zh/docs/setup/)设置 Istio。
1. 首先部署已启用访问日志记录的两个版本的 [httpbin]({{< github_tree >}}/samples/httpbin) 服务：

    1. 部署 `httpbin-v1`：

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: httpbin-v1
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: httpbin
              version: v1
          template:
            metadata:
              labels:
                app: httpbin
                version: v1
            spec:
              containers:
              - image: docker.io/kennethreitz/httpbin
                imagePullPolicy: IfNotPresent
                name: httpbin
                command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
                ports:
                - containerPort: 80
        EOF
        {{< /text >}}

    1. 部署 `httpbin-v2`：

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: httpbin-v2
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: httpbin
              version: v2
          template:
            metadata:
              labels:
                app: httpbin
                version: v2
            spec:
              containers:
              - image: docker.io/kennethreitz/httpbin
                imagePullPolicy: IfNotPresent
                name: httpbin
                command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
                ports:
                - containerPort: 80
        EOF
        {{< /text >}}

    1. 部署 `httpbin` Kubernetes Service：

        {{< text bash >}}
        $ kubectl create -f - <<EOF
        apiVersion: v1
        kind: Service
        metadata:
          name: httpbin
          labels:
            app: httpbin
        spec:
          ports:
          - name: http
            port: 8000
            targetPort: 80
          selector:
            app: httpbin
        EOF
        {{< /text >}}

1. 部署用于向 `httpbin` 服务发送请求的 `curl` 工作负载：

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: curl
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: curl
      template:
        metadata:
          labels:
            app: curl
        spec:
          containers:
          - name: curl
            image: curlimages/curl
            command: ["/bin/curl","3650d"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

## 创建一个默认路由策略 {#creating-a-default-routing-policy}

默认情况下，Kubernetes 在 `httpbin` 服务的两个版本之间进行负载均衡。
在此步骤中，您将更改该行为，把所有流量都路由到 `v1` 版本。

1. 创建一个默认路由规则，将所有流量路由到服务的 `v1` 版本：

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio API" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
        - httpbin
      http:
      - route:
        - destination:
            host: httpbin
            subset: v1
          weight: 100
    ---
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: httpbin
    spec:
      host: httpbin
      subsets:
      - name: v1
        labels:
          version: v1
      - name: v2
        labels:
          version: v2
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin-v1
    spec:
      ports:
      - port: 80
        name: http
      selector:
        app: httpbin
        version: v1
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin-v2
    spec:
      ports:
      - port: 80
        name: http
      selector:
        app: httpbin
        version: v2
    ---
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: httpbin
    spec:
      parentRefs:
      - group: ""
        kind: Service
        name: httpbin
        port: 8000
      rules:
      - backendRefs:
        - name: httpbin-v1
          port: 80
    EOF
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 现在所有流量都指向 `httpbin:v1` 服务，并向此服务发送请求：

    {{< text bash json >}}
    $ kubectl exec deploy/curl -c curl -- curl -sS http://httpbin:8000/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Parentspanid": "57784f8bff90ae0b",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "3289ae7257c3f159",
        "X-B3-Traceid": "b56eebd279a76f0b57784f8bff90ae0b",
        "X-Envoy-Attempt-Count": "1",
        "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/default;Hash=20afebed6da091c850264cc751b8c9306abac02993f80bdb76282237422bd098;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default"
      }
    }
    {{< /text >}}

1. 查看 `httpbin-v1` 和 `httpbin-v2` 这 2 个 Pod 的日志。
   您应可以看到 `v1` 版本的访问日志条目，而 `v2` 版本没有日志：

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v1 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v2 -c httpbin
    <none>
    {{< /text >}}

## 将流量镜像发送至 `httpbin-v2` {#mirroring-traffic-to-httpbin-v2}

1. 修改路由规则，将流量镜像发送至 `httpbin-v2`：

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio API" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
        - httpbin
      http:
      - route:
        - destination:
            host: httpbin
            subset: v1
          weight: 100
        mirror:
          host: httpbin
          subset: v2
        mirrorPercentage:
          value: 100.0
    EOF
    {{< /text >}}

    这个路由规则发送 100% 流量到 `v1` 版本。
    最后一节表示您将 100% 的相同流量镜像（即也发送）到 `httpbin:v2` 服务。
    当流量被镜像时，请求将被发送到镜像服务中，并在 `headers` 中的 `Host/Authority` 属性值上追加 `-shadow`。
    例如 `cluster-1` 变为 `cluster-1-shadow`。

    此外，重点注意这些被镜像的流量是“即发即弃”的，就是说镜像请求的响应会被丢弃。

    您可以使用 `mirrorPercentage` 属性下的 `value` 字段来设置镜像流量的百分比，
    而不是镜像所有请求。如果没有这个属性，将镜像所有流量。

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: httpbin
    spec:
      parentRefs:
      - group: ""
        kind: Service
        name: httpbin
        port: 8000
      rules:
      - filters:
        - type: RequestMirror
          requestMirror:
            backendRef:
              name: httpbin-v2
              port: 80
        backendRefs:
        - name: httpbin-v1
          port: 80
    EOF
    {{< /text >}}

    此路由规则将 100% 的流量发送到 `v1`。
    `RequestMirror` 过滤器指定您要将 100% 的相同流量镜像（即也发送）到 `httpbin:v2` 服务。
    当流量被镜像时，请求被发送到镜像服务，其 Host/Authority 请求头附加了 `-shadow`。
    例如，`cluster-1` 变为 `cluster-1-shadow`。

    此外，重点注意这些被镜像的流量是“即发即弃”的，就是说镜像请求的响应会被丢弃。

    {{< /tab >}}

    {{< /tabset >}}

1. 发送流量：

    {{< text bash >}}
    $ kubectl exec deploy/curl -c curl -- curl -sS http://httpbin:8000/headers
    {{< /text >}}

    现在您应看到 `v1` 和 `v2` 版本中都有了访问日志。
    `v2` 版本中的访问日志就是由镜像流量产生的，这些请求的实际目标是 `v1` 版本。

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v1 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs deploy/httpbin-v2 -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    {{< /text >}}

## 清理 {#cleaning-up}

1. 移除规则：

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio API" category-value="istio-apis" >}}

    {{< text bash >}}
    $ kubectl delete virtualservice httpbin
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< text bash >}}
    $ kubectl delete httproute httpbin
    $ kubectl delete svc httpbin-v1 httpbin-v2
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 删除 `httpbin` 和 `curl` Deployment 以及 `httpbin` 服务：

    {{< text bash >}}
    $ kubectl delete deploy httpbin-v1 httpbin-v2 curl
    $ kubectl delete svc httpbin
    {{< /text >}}

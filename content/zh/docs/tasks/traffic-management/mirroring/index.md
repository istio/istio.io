---
title: 镜像
description: 此任务演示了 Istio 的流量镜像/影子功能。
weight: 60
keywords: [traffic-management,mirroring]
owner: istio/wg-networking-maintainers
test: yes
---

此任务演示了 Istio 的流量镜像功能。

流量镜像，也称为影子流量，是一个以尽可能低的风险为生产带来变化的强大的功能。
镜像会将实时流量的副本发送到镜像服务。镜像流量发生在主服务的关键请求路径之外。

在此任务中，首先把流量全部路由到测试服务的 `v1` 版本。然后，执行规则将一部分流量镜像到 `v2` 版本。

{{< boilerplate gateway-api-gamma-support >}}

## 开始之前{#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明设置 Istio。

*   首先部署两个版本的 [Httpbin]({{< github_tree >}}/samples/httpbin) 服务，并开启访问日志功能：

    **httpbin-v1：**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
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

    **httpbin-v2：**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
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

    **httpbin Kubernetes 服务：**

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

*   启动 `sleep` 服务，这样就可以使用 `curl` 来提供负载：

    **sleep 服务：**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: sleep
      template:
        metadata:
          labels:
            app: sleep
        spec:
          containers:
          - name: sleep
            image: curlimages/curl
            command: ["/bin/sleep","3650d"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

## 创建一个默认路由策略{#creating-a-default-routing-policy}

默认情况下，Kubernetes 在 `httpbin` 服务的两个版本之间进行负载均衡。在此步骤中会更改该行为，把所有流量都路由到 `v1` 版本。

1.  创建一个默认路由规则，将所有流量路由到服务的 `v1` 版本：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
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
apiVersion: networking.istio.io/v1alpha3
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
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - kind: Service
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

2) 现在所有流量都转到 `httpbin:v1` 服务，并向此服务发送请求：

    {{< text bash json >}}
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec "${SLEEP_POD}" -c sleep -- curl -sS http://httpbin:8000/headers
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

3) 分别查看 `httpbin` Pod的 `v1` 和 `v2` 两个版本的日志。您可以看到 `v1` 版本的访问日志条目，而 `v2` 版本没有日志：

    {{< text bash >}}
    $ export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
    $ kubectl logs "$V1_POD" -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
    $ kubectl logs "$V2_POD" -c httpbin
    <none>
    {{< /text >}}

## 镜像流量到 v2{#mirroring-traffic-to-v2}

1.  改变流量规则将流量镜像到 v2：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
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

这个路由规则发送 100% 流量到 `v1` 版本。最后一节表示您将 100% 的相同流量镜像（即发送）到 `httpbin:v2` 服务。
当流量被镜像时，请求将发送到镜像服务中，并在 `headers` 中的 `Host/Authority` 属性值上追加 `-shadow`。
例如 `cluster-1` 变为 `cluster-1-shadow`。

此外，重点注意这些被镜像的流量是『即发即弃』的，就是说镜像请求的响应会被丢弃。

您可以使用 `mirrorPercentage` 属性下的 `value` 字段来设置镜像流量的百分比，而不是镜像所有请求。如果没有这个属性，将镜像所有流量。

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - kind: Service
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

此外，重要的是要注意这些请求被镜像为“即发即弃”，这意味着响应将被丢弃。

{{< /tab >}}

{{< /tabset >}}

2) 发送流量：

    {{< text bash >}}
    $ kubectl exec "${SLEEP_POD}" -c sleep -- curl -sS http://httpbin:8000/headers
    {{< /text >}}

    现在就可以看到 `v1` 和 `v2` 版本中都有了访问日志。v2 版本中的访问日志就是由镜像流量产生的，这些请求的实际目标是 `v1` 版本。

    {{< text bash >}}
    $ kubectl logs "$V1_POD" -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs "$V2_POD" -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    {{< /text >}}

## 清理{#cleaning-up}

1.  删除规则：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

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

2)  关闭 [Httpbin]({{< github_tree >}}/samples/httpbin) 服务和客户端：

    {{< text bash >}}
    $ kubectl delete deploy httpbin-v1 httpbin-v2 sleep
    $ kubectl delete svc httpbin
    {{< /text >}}

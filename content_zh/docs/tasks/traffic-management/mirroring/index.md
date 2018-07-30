---
title: 镜像
description: 此任务演示了 Istio 的流量镜像/阴影功能。
weight: 60
keywords: [traffic-management,mirroring]
---

此任务演示了 Istio 的流量镜像功能。

流量镜像，也称为影子流量，是一个以尽可能低的风险为生产带来变化的强大的功能。镜像会将实时流量的副本发送到镜像服务。镜像流量发生在主服务的关键请求路径之外。

在此任务中，您将首先强制所有流量到 `v1` 测试服务。然后，您将使用规则将一部分流量镜像到 `v2` 。

## 开始之前

* 按照[安装指南](/docs/setup/)中的说明设置 Istio 。

*   首先部署启用了访问日志的两个版本的 [httpbin]({{< github_tree >}}/samples/httpbin) 服务：

    **httpbin-v1:**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: httpbin-v1
    spec:
      replicas: 1
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
            command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:8080", "httpbin:app"]
            ports:
            - containerPort: 8080
    EOF
    {{< /text >}}

    **httpbin-v2:**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: httpbin-v2
    spec:
      replicas: 1
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
            command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:8080", "httpbin:app"]
            ports:
            - containerPort: 8080
    EOF
    {{< /text >}}

    **httpbin Kubernetes service:**

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin
      labels:
        app: httpbin
    spec:
      ports:
      - name: http
        port: 8080
      selector:
        app: httpbin
    EOF
    {{< /text >}}

*   启动 `sleep` 服务，这样您就可以使用 `curl` 来提供负载：

    **sleep service:**

    {{< text bash >}}
    $ cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: sleep
        spec:
          containers:
          - name: sleep
            image: tutum/curl
            command: ["/bin/sleep","infinity"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

## 创建默认路由策略

默认情况下，Kubernetes 在 `httpbin` 服务的两个版本之间进行负载均衡。在此步骤中，您将更改该行为，以便所有流量都转到 `v1` 。

1.  创建一个默认路由规则，将所有流量路由到服务的 `v1` ：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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

    > 注意：如果您已经安装/配置 Istio 并启用 TLS 双向认证，您必须增加 [TLSSettings.TLSmode]( /docs/reference/config/istio.networking.v1alpha3/#TLSSettings-TLSmode), `mode: ISTIO_MUTUAL` 。如 [TLSSettings](/docs/reference/config/istio.networking.v1alpha3/#TLSSettings) 参考中所述。

    现在所有流量已经都转到 `httpbin v1` 服务。

1. 向服务发送一些流量：

    {{< text bash json >}}
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers' | python -m json.tool
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8080",
        "User-Agent": "curl/7.35.0",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "eca3d7ed8f2e6a0a",
        "X-B3-Traceid": "eca3d7ed8f2e6a0a",
        "X-Ot-Span-Context": "eca3d7ed8f2e6a0a;eca3d7ed8f2e6a0a;0000000000000000"
      }
    }
    {{< /text >}}

1. 查看 `httpbin` pods 的 `v1` 和 `v2` 日志。您可以看到 `v1` 的访问日志和 `v2` 为 \<none\> 的日志：

    {{< text bash >}}
    $ export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
    $ kubectl logs -f $V1_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
    $ kubectl logs -f $V2_POD -c httpbin
    <none>
    {{< /text >}}

## 镜像流量到 v2

1.  改变路由规则将流量镜像到 v2:

    {{< text bash >}}
    $ cat <<EOF | istioctl replace -f -
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
    EOF
    {{< /text >}}

    此路由规则将 100％ 的流量发送到 `v1` 。最后一节指定镜像到 `httpbin v2` 服务。当流量被镜像时，请求将通过其主机/授权报头发送到镜像服务附上 `-shadow` 。例如，将 `cluster-1` 变为 `cluster-1-shadow` 。

    此外，重点注意这些请求被镜像为"即发即弃"，这意味着这些响应是被丢弃的。

1. 发送流量：

    {{< text bash >}}
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers' | python -m json.tool
    {{< /text >}}

    现在，您可以查看 `v1` 和 `v2` 的访问日志记录。在 `v2` 中创建的请求实际上也通过了 `v1` 。

    {{< text bash >}}
    $ kubectl logs -f $V1_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs -f $V2_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    {{< /text >}}

## 清理

1.  删除规则:

    {{< text bash >}}
    $ istioctl delete virtualservice httpbin
    $ istioctl delete destinationrule httpbin
    {{< /text >}}

1.  关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务和客户端:

    {{< text bash >}}
    $ kubectl delete deploy httpbin-v1 httpbin-v2 sleep
    $ kubectl delete svc httpbin
    {{< /text >}}

1. 如果您不打算探索任何后续任务，请参阅
  [Bookinfo 清理](/docs/examples/bookinfo/#cleanup) 的说明去关闭应用程序。
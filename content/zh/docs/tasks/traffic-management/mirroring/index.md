---
title: 镜像
description: 此任务演示了 Istio 的流量镜像/影子功能。
weight: 60
keywords: [traffic-management,mirroring]
---

此任务演示了 Istio 的流量镜像功能。

流量镜像，也称为影子流量，是一个以尽可能低的风险为生产带来变化的强大的功能。镜像会将实时流量的副本发送到镜像服务。镜像流量发生在主服务的关键请求路径之外。

在此任务中，首先把流量全部路由到 `v1` 版本的测试服务。然后，执行规则将一部分流量镜像到 `v2` 版本。

## 开始之前{#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明设置 Istio。

*   首先部署两个版本的 [httpbin]({{< github_tree >}}/samples/httpbin) 服务，[httpbin]({{< github_tree >}}/samples/httpbin) 服务已开启访问日志：

    **httpbin-v1:**

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

    **httpbin-v2:**

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

    **httpbin Kubernetes service:**

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

*   启动 `sleep` 服务，这样就可以使用 `curl` 来提供负载了：

    **sleep service:**

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
            image: tutum/curl
            command: ["/bin/sleep","infinity"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

## 创建一个默认路由策略{#creating-a-default-routing-policy}

默认情况下，Kubernetes 在 `httpbin` 服务的两个版本之间进行负载均衡。在此步骤中会更改该行为，把所有流量都路由到 `v1`。

1.  创建一个默认路由规则，将所有流量路由到服务的 `v1`：

    {{< warning >}}
    如果安装/配置 Istio 的时候开启了 TLS 认证，在应用 `DestinationRule` 之前必须将 TLS 流量策略 `mode: ISTIO_MUTUAL` 添加到 `DestinationRule`。否则，请求将发生 503 错误，如[设置目标规则后出现 503 错误](/zh/docs/ops/common-problems/network-issues/#service-unavailable-errors-after-setting-destination-rule)所述。
    {{< /warning >}}

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

    现在所有流量都转到`httpbin:v1`服务。

1. 向服务发送一下流量：

    {{< text bash json >}}
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8000/headers' | python -m json.tool
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "eca3d7ed8f2e6a0a",
        "X-B3-Traceid": "eca3d7ed8f2e6a0a",
        "X-Ot-Span-Context": "eca3d7ed8f2e6a0a;eca3d7ed8f2e6a0a;0000000000000000"
      }
    }
    {{< /text >}}

1. 分别查看 `httpbin` 服务 `v1` 和 `v2` 两个 pods 的日志，您可以看到访问日志进入 `v1`，而 `v2` 中没有日志，显示为 `<none>`：

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

## 镜像流量到 v2{#mirroring-traffic-to-v2}

1.  改变流量规则将流量镜像到 v2：

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
        mirror_percent: 100
    EOF
    {{< /text >}}

    这个路由规则发送 100% 流量到 `v1`。最后一段表示你将镜像流量到 `httpbin:v2` 服务。当流量被镜像时，请求将发送到镜像服务中，并在 `headers` 中的 `Host/Authority` 属性值上追加 `-shadow`。例如 `cluster-1` 变为 `cluster-1-shadow`。

    此外，重点注意这些被镜像的流量是『即发即弃』的，就是说镜像请求的响应会被丢弃。

    您可以使用 `mirror_percent` 属性来设置镜像流量的百分比，而不是镜像全部请求。为了兼容老版本，如果这个属性不存在，将镜像所有流量。
1. 发送流量：

    {{< text bash >}}
    $ kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8000/headers' | python -m json.tool
    {{< /text >}}

    现在就可以看到 `v1` 和 `v2` 中都有了访问日志。v2 中的访问日志就是由镜像流量产生的，这些请求的实际目标是 v1。

    {{< text bash >}}
    $ kubectl logs -f $V1_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:02:43 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 321 "-" "curl/7.35.0"
    {{< /text >}}

    {{< text bash >}}
    $ kubectl logs -f $V2_POD -c httpbin
    127.0.0.1 - - [07/Mar/2018:19:26:44 +0000] "GET /headers HTTP/1.1" 200 361 "-" "curl/7.35.0"
    {{< /text >}}

1. 如果要检查流量内部，请在另一个控制台上运行以下命令：

    {{< text bash >}}
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ export V1_POD_IP=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..status.podIP})
    $ export V2_POD_IP=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..status.podIP})
    $ kubectl exec -it $SLEEP_POD -c istio-proxy -- sudo tcpdump -A -s 0 host $V1_POD_IP or host $V2_POD_IP
    tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
    listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
    05:47:50.159513 IP sleep-7b9f8bfcd-2djx5.38836 > 10-233-75-11.httpbin.default.svc.cluster.local.80: Flags [P.], seq 4039989036:4039989832, ack 3139734980, win 254, options [nop,nop,TS val 77427918 ecr 76730809], length 796: HTTP: GET /headers HTTP/1.1
    E..P2.X.X.X.
    .K.
    .K....P..W,.$.......+.....
    ..t.....GET /headers HTTP/1.1
    host: httpbin:8000
    user-agent: curl/7.35.0
    accept: */*
    x-forwarded-proto: http
    x-request-id: 571c0fd6-98d4-4c93-af79-6a2fe2945847
    x-envoy-decorator-operation: httpbin.default.svc.cluster.local:8000/*
    x-b3-traceid: 82f3e0a76dcebca2
    x-b3-spanid: 82f3e0a76dcebca2
    x-b3-sampled: 0
    x-istio-attributes: Cj8KGGRlc3RpbmF0aW9uLnNlcnZpY2UuaG9zdBIjEiFodHRwYmluLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwKPQoXZGVzdGluYXRpb24uc2VydmljZS51aWQSIhIgaXN0aW86Ly9kZWZhdWx0L3NlcnZpY2VzL2h0dHBiaW4KKgodZGVzdGluYXRpb24uc2VydmljZS5uYW1lc3BhY2USCRIHZGVmYXVsdAolChhkZXN0aW5hdGlvbi5zZXJ2aWNlLm5hbWUSCRIHaHR0cGJpbgo6Cgpzb3VyY2UudWlkEiwSKmt1YmVybmV0ZXM6Ly9zbGVlcC03YjlmOGJmY2QtMmRqeDUuZGVmYXVsdAo6ChNkZXN0aW5hdGlvbi5zZXJ2aWNlEiMSIWh0dHBiaW4uZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbA==
    content-length: 0


    05:47:50.159609 IP sleep-7b9f8bfcd-2djx5.49560 > 10-233-71-7.httpbin.default.svc.cluster.local.80: Flags [P.], seq 296287713:296288571, ack 4029574162, win 254, options [nop,nop,TS val 77427918 ecr 76732809], length 858: HTTP: GET /headers HTTP/1.1
    E.....X.X...
    .K.
    .G....P......l......e.....
    ..t.....GET /headers HTTP/1.1
    host: httpbin-shadow:8000
    user-agent: curl/7.35.0
    accept: */*
    x-forwarded-proto: http
    x-request-id: 571c0fd6-98d4-4c93-af79-6a2fe2945847
    x-envoy-decorator-operation: httpbin.default.svc.cluster.local:8000/*
    x-b3-traceid: 82f3e0a76dcebca2
    x-b3-spanid: 82f3e0a76dcebca2
    x-b3-sampled: 0
    x-istio-attributes: Cj8KGGRlc3RpbmF0aW9uLnNlcnZpY2UuaG9zdBIjEiFodHRwYmluLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwKPQoXZGVzdGluYXRpb24uc2VydmljZS51aWQSIhIgaXN0aW86Ly9kZWZhdWx0L3NlcnZpY2VzL2h0dHBiaW4KKgodZGVzdGluYXRpb24uc2VydmljZS5uYW1lc3BhY2USCRIHZGVmYXVsdAolChhkZXN0aW5hdGlvbi5zZXJ2aWNlLm5hbWUSCRIHaHR0cGJpbgo6Cgpzb3VyY2UudWlkEiwSKmt1YmVybmV0ZXM6Ly9zbGVlcC03YjlmOGJmY2QtMmRqeDUuZGVmYXVsdAo6ChNkZXN0aW5hdGlvbi5zZXJ2aWNlEiMSIWh0dHBiaW4uZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbA==
    x-envoy-internal: true
    x-forwarded-for: 10.233.75.12
    content-length: 0


    05:47:50.166734 IP 10-233-75-11.httpbin.default.svc.cluster.local.80 > sleep-7b9f8bfcd-2djx5.38836: Flags [P.], seq 1:472, ack 796, win 276, options [nop,nop,TS val 77427925 ecr 77427918], length 471: HTTP: HTTP/1.1 200 OK
    E....3X.?...
    .K.
    .K..P...$....ZH...........
    ..t...t.HTTP/1.1 200 OK
    server: envoy
    date: Fri, 15 Feb 2019 05:47:50 GMT
    content-type: application/json
    content-length: 241
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 3

    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "82f3e0a76dcebca2",
        "X-B3-Traceid": "82f3e0a76dcebca2"
      }
    }

    05:47:50.166789 IP sleep-7b9f8bfcd-2djx5.38836 > 10-233-75-11.httpbin.default.svc.cluster.local.80: Flags [.], ack 472, win 262, options [nop,nop,TS val 77427925 ecr 77427925], length 0
    E..42.X.X.\.
    .K.
    .K....P..ZH.$.............
    ..t...t.
    05:47:50.167234 IP 10-233-71-7.httpbin.default.svc.cluster.local.80 > sleep-7b9f8bfcd-2djx5.49560: Flags [P.], seq 1:512, ack 858, win 280, options [nop,nop,TS val 77429926 ecr 77427918], length 511: HTTP: HTTP/1.1 200 OK
    E..3..X.>...
    .G.
    .K..P....l....;...........
    ..|...t.HTTP/1.1 200 OK
    server: envoy
    date: Fri, 15 Feb 2019 05:47:49 GMT
    content-type: application/json
    content-length: 281
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 3

    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "httpbin-shadow:8000",
        "User-Agent": "curl/7.35.0",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "82f3e0a76dcebca2",
        "X-B3-Traceid": "82f3e0a76dcebca2",
        "X-Envoy-Internal": "true"
      }
    }

    05:47:50.167253 IP sleep-7b9f8bfcd-2djx5.49560 > 10-233-71-7.httpbin.default.svc.cluster.local.80: Flags [.], ack 512, win 262, options [nop,nop,TS val 77427926 ecr 77429926], length 0
    E..4..X.X...
    .K.
    .G....P...;..n............
    ..t...|.
    {{< /text >}}

    您可以看到流量​​的请求和响应内容。

## 清理{#cleaning-up}

1.  删除规则：

    {{< text bash >}}
    $ kubectl delete virtualservice httpbin
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

1.  关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务和客户端：

    {{< text bash >}}
    $ kubectl delete deploy httpbin-v1 httpbin-v2 sleep
    $ kubectl delete svc httpbin
    {{< /text >}}

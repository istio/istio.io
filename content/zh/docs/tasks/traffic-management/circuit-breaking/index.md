---
title: 熔断
description: 本任务展示如何为连接、请求以及异常检测配置熔断。
weight: 50
keywords: [traffic-management,circuit-breaking]
owner: istio/wg-networking-maintainers
test: yes
---

本任务展示如何为连接、请求以及异常检测配置熔断。

熔断，是创建弹性微服务应用程序的重要模式。
熔断能够使您的应用程序具备应对来自故障、潜在峰值和其他未知网络因素影响的能力。

这个任务中，您将配置熔断规则，然后通过有意的使熔断器“跳闸”来测试配置。

## 开始之前 {#before-you-begin}

* 跟随[安装指南](/zh/docs/setup/)安装 Istio。

{{< boilerplate start-httpbin-service >}}

应用程序 `httpbin` 作为此任务的后端服务。

## 配置熔断器 {#configuring-the-circuit-breaker}

1. 创建一个[目标规则](/zh/docs/reference/config/networking/destination-rule/)，
   在调用 `httpbin` 服务时应用熔断设置：

    {{< warning >}}
    如果您的 Istio 启用了双向 TLS 身份验证，则必须在应用目标规则之前将 TLS 流量策略
    `mode：ISTIO_MUTUAL` 添加到 `DestinationRule`。否则请求将产生 503 错误，
    如[这里](/zh/docs/ops/common-problems/network-issues/#service-unavailable-errors-after-setting-destination-rule)所述。
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: httpbin
    spec:
      host: httpbin
      trafficPolicy:
        connectionPool:
          tcp:
            maxConnections: 1
          http:
            http1MaxPendingRequests: 1
            maxRequestsPerConnection: 1
        outlierDetection:
          consecutive5xxErrors: 1
          interval: 1s
          baseEjectionTime: 3m
          maxEjectionPercent: 100
    EOF
    {{< /text >}}

1. 验证目标规则是否已正确创建：

    {{< text bash yaml >}}
    $ kubectl get destinationrule httpbin -o yaml
    apiVersion: networking.istio.io/v1beta1
    kind: DestinationRule
    ...
    spec:
      host: httpbin
      trafficPolicy:
        connectionPool:
          http:
            http1MaxPendingRequests: 1
            maxRequestsPerConnection: 1
          tcp:
            maxConnections: 1
        outlierDetection:
          baseEjectionTime: 3m
          consecutive5xxErrors: 1
          interval: 1s
          maxEjectionPercent: 100
    {{< /text >}}

## 增加一个客户端 {#adding-a-client}

创建客户端程序以发送流量到 `httpbin` 服务。这是一个名为
[Fortio](https://github.com/istio/fortio) 的负载测试客户端，
它可以控制连接数、并发数及发送 HTTP 请求的延迟。
通过 Fortio 能够有效的触发前面在 `DestinationRule` 中设置的熔断策略。

1. 向客户端注入 Istio Sidecar 代理，以便 Istio 对其网络交互进行管理：

    如果您启用了[自动注入 Sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，
    可以直接部署 `fortio` 应用：

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/sample-client/fortio-deploy.yaml@
    {{< /text >}}

    否则，您需要在部署 `fortio` 应用前手动注入 Sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/sample-client/fortio-deploy.yaml@)
    {{< /text >}}

1. 登入客户端 Pod 并使用 Fortio 工具调用 `httpbin` 服务。`-curl` 参数表明发送一次调用：

    {{< text bash >}}
    $ export FORTIO_POD=$(kubectl get pods -l app=fortio -o 'jsonpath={.items[0].metadata.name}')
    $ kubectl exec "$FORTIO_POD" -c fortio -- /usr/bin/fortio curl -quiet http://httpbin:8000/get
    HTTP/1.1 200 OK
    server: envoy
    date: Tue, 25 Feb 2020 20:25:52 GMT
    content-type: application/json
    content-length: 586
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 36

    {
      "args": {},
      "headers": {
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "fortio.org/fortio-1.3.1",
        "X-B3-Parentspanid": "8fc453fb1dec2c22",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "071d7f06bc94943c",
        "X-B3-Traceid": "86a929a0e76cda378fc453fb1dec2c22",
        "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/httpbin;Hash=68bbaedefe01ef4cb99e17358ff63e92d04a4ce831a35ab9a31d3c8e06adb038;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default"
      },
      "origin": "127.0.0.1",
      "url": "http://httpbin:8000/get"
    }
    {{< /text >}}

可以看到调用后端服务的请求已经成功！接下来，可以测试熔断。

## 触发熔断器 {#tripping-the-circuit-breaker}

在 `DestinationRule` 配置中，您定义了 `maxConnections: 1` 和 `http1MaxPendingRequests: 1`。
这些规则意味着，如果并发的连接和请求数超过一个，在 `istio-proxy` 进行进一步的请求和连接时，后续请求或连接将被阻止。

1. 发送并发数为 2 的连接（`-c 2`），请求 20 次（`-n 20`）：

    {{< text bash >}}
    $ kubectl exec "$FORTIO_POD" -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
    20:33:46 I logger.go:97> Log level is now 3 Warning (was 2 Info)
    Fortio 1.3.1 running at 0 queries per second, 6->6 procs, for 20 calls: http://httpbin:8000/get
    Starting at max qps with 2 thread(s) [gomax 6] for exactly 20 calls (10 per thread + 0)
    20:33:46 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:33:47 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:33:47 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    Ended after 59.8524ms : 20 calls. qps=334.16
    Aggregated Function Time : count 20 avg 0.0056869 +/- 0.003869 min 0.000499 max 0.0144329 sum 0.113738
    # range, mid point, percentile, count
    >= 0.000499 <= 0.001 , 0.0007495 , 10.00, 2
    > 0.001 <= 0.002 , 0.0015 , 15.00, 1
    > 0.003 <= 0.004 , 0.0035 , 45.00, 6
    > 0.004 <= 0.005 , 0.0045 , 55.00, 2
    > 0.005 <= 0.006 , 0.0055 , 60.00, 1
    > 0.006 <= 0.007 , 0.0065 , 70.00, 2
    > 0.007 <= 0.008 , 0.0075 , 80.00, 2
    > 0.008 <= 0.009 , 0.0085 , 85.00, 1
    > 0.011 <= 0.012 , 0.0115 , 90.00, 1
    > 0.012 <= 0.014 , 0.013 , 95.00, 1
    > 0.014 <= 0.0144329 , 0.0142165 , 100.00, 1
    # target 50% 0.0045
    # target 75% 0.0075
    # target 90% 0.012
    # target 99% 0.0143463
    # target 99.9% 0.0144242
    Sockets used: 4 (for perfect keepalive, would be 2)
    Code 200 : 17 (85.0 %)
    Code 503 : 3 (15.0 %)
    Response Header Sizes : count 20 avg 195.65 +/- 82.19 min 0 max 231 sum 3913
    Response Body/Total Sizes : count 20 avg 729.9 +/- 205.4 min 241 max 817 sum 14598
    All done 20 calls (plus 0 warmup) 5.687 ms avg, 334.2 qps
    {{< /text >}}

    有趣的是，几乎所有的请求都完成了！`istio-proxy` 确实允许存在一些误差。

    {{< text plain >}}
    Code 200 : 17 (85.0 %)
    Code 503 : 3 (15.0 %)
    {{< /text >}}

1. 将并发连接数提高到 3 个：

    {{< text bash >}}
    $ kubectl exec "$FORTIO_POD" -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
    20:32:30 I logger.go:97> Log level is now 3 Warning (was 2 Info)
    Fortio 1.3.1 running at 0 queries per second, 6->6 procs, for 30 calls: http://httpbin:8000/get
    Starting at max qps with 3 thread(s) [gomax 6] for exactly 30 calls (10 per thread + 0)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
    Ended after 51.9946ms : 30 calls. qps=576.98
    Aggregated Function Time : count 30 avg 0.0040001633 +/- 0.003447 min 0.0004298 max 0.015943 sum 0.1200049
    # range, mid point, percentile, count
    >= 0.0004298 <= 0.001 , 0.0007149 , 16.67, 5
    > 0.001 <= 0.002 , 0.0015 , 36.67, 6
    > 0.002 <= 0.003 , 0.0025 , 50.00, 4
    > 0.003 <= 0.004 , 0.0035 , 60.00, 3
    > 0.004 <= 0.005 , 0.0045 , 66.67, 2
    > 0.005 <= 0.006 , 0.0055 , 76.67, 3
    > 0.006 <= 0.007 , 0.0065 , 83.33, 2
    > 0.007 <= 0.008 , 0.0075 , 86.67, 1
    > 0.008 <= 0.009 , 0.0085 , 90.00, 1
    > 0.009 <= 0.01 , 0.0095 , 96.67, 2
    > 0.014 <= 0.015943 , 0.0149715 , 100.00, 1
    # target 50% 0.003
    # target 75% 0.00583333
    # target 90% 0.009
    # target 99% 0.0153601
    # target 99.9% 0.0158847
    Sockets used: 20 (for perfect keepalive, would be 3)
    Code 200 : 11 (36.7 %)
    Code 503 : 19 (63.3 %)
    Response Header Sizes : count 30 avg 84.366667 +/- 110.9 min 0 max 231 sum 2531
    Response Body/Total Sizes : count 30 avg 451.86667 +/- 277.1 min 241 max 817 sum 13556
    All done 30 calls (plus 0 warmup) 4.000 ms avg, 577.0 qps
    {{< /text >}}

    现在，您将开始看到预期的熔断行为，只有 36.7% 的请求成功，其余的均被熔断器拦截：

    {{< text plain >}}
    Code 200 : 11 (36.7 %)
    Code 503 : 19 (63.3 %)
    {{< /text >}}

1. 查询 `istio-proxy` 状态以了解更多熔断详情:

    {{< text bash >}}
    $ kubectl exec "$FORTIO_POD" -c istio-proxy -- pilot-agent request GET stats | grep httpbin | grep pending
    cluster.outbound|8000||httpbin.default.svc.cluster.local.circuit_breakers.default.remaining_pending: 1
    cluster.outbound|8000||httpbin.default.svc.cluster.local.circuit_breakers.default.rq_pending_open: 0
    cluster.outbound|8000||httpbin.default.svc.cluster.local.circuit_breakers.high.rq_pending_open: 0
    cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_active: 0
    cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_failure_eject: 0
    cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_overflow: 21
    cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_total: 29
    {{< /text >}}

    可以看到 `upstream_rq_pending_overflow` 值 `21`，这意味着，目前为止已有 21 个调用被标记为熔断。

## 清理 {#cleaning-up}

1. 清理规则:

    {{< text bash >}}
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

1. 下线 [httpbin]({{< github_tree >}}/samples/httpbin) 服务和客户端：

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/sample-client/fortio-deploy.yaml@
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

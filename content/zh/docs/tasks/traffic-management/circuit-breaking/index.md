---
title: 熔断
description: 本任务展示如何为连接、请求以及异常检测配置熔断。
weight: 50
keywords: [traffic-management,circuit-breaking]
---

本任务展示如何为连接、请求以及异常检测配置熔断。

熔断，是创建弹性微服务应用程序的重要模式。熔断能够使您的应用程序具备应对来自故障、潜在峰值和其他
未知网络因素影响的能力。

这个任务中，你将配置熔断规则，然后通过有意的使熔断器“跳闸”来测试配置。

## 开始之前{#before-you-begin}

* 跟随[安装指南](/zh/docs/setup/)安装 Istio。

{{< boilerplate start-httpbin-service >}}

应用程序 `httpbin` 作为此任务的后端服务。

## 配置熔断器{#configuring-the-circuit-breaker}

1. 创建一个[目标规则](/zh/docs/reference/config/networking/destination-rule/)，在调用 `httpbin`
服务时应用熔断设置：

    {{< warning >}}
    如果您的 Istio 启用了双向 TLS 身份验证，则必须在应用目标规则之前将 TLS 流量策略 `mode：ISTIO_MUTUAL` 添加到 `DestinationRule` 。否则请求将产生 503 错误，如[这里](/zh/docs/ops/common-problems/network-issues/#service-unavailable-errors-after-setting-destination-rule)所述。
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
          consecutiveErrors: 1
          interval: 1s
          baseEjectionTime: 3m
          maxEjectionPercent: 100
    EOF
    {{< /text >}}

1. 验证目标规则是否已正确创建：

    {{< text bash yaml >}}
    $ kubectl get destinationrule httpbin -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: httpbin
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
          baseEjectionTime: 180.000s
          consecutiveErrors: 1
          interval: 1.000s
          maxEjectionPercent: 100
    {{< /text >}}

## 增加一个客户{#adding-a-client}

创建客户端程序以发送流量到 `httpbin` 服务。这是一个名为 [Fortio](https://github.com/istio/fortio)
的负载测试客户的，其可以控制连接数、并发数及发送 HTTP 请求的延迟。通过 Fortio 能够有效的触发前面
在 `DestinationRule` 中设置的熔断策略。

1. 向客户端注入 Istio Sidecar 代理，以便 Istio 对其网络交互进行管理：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/sample-client/fortio-deploy.yaml@)
    {{< /text >}}

1. 登入客户端 Pod 并使用 Fortio 工具调用 `httpbin` 服务。`-curl` 参数表明发送一次调用：

    {{< text bash >}}
    $ FORTIO_POD=$(kubectl get pod | grep fortio | awk '{ print $1 }')
    $ kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -curl  http://httpbin:8000/get
    HTTP/1.1 200 OK
    server: envoy
    date: Tue, 16 Jan 2018 23:47:00 GMT
    content-type: application/json
    access-control-allow-origin: *
    access-control-allow-credentials: true
    content-length: 445
    x-envoy-upstream-service-time: 36

    {
      "args": {},
      "headers": {
        "Content-Length": "0",
        "Host": "httpbin:8000",
        "User-Agent": "istio/fortio-0.6.2",
        "X-B3-Sampled": "1",
        "X-B3-Spanid": "824fbd828d809bf4",
        "X-B3-Traceid": "824fbd828d809bf4",
        "X-Ot-Span-Context": "824fbd828d809bf4;824fbd828d809bf4;0000000000000000",
        "X-Request-Id": "1ad2de20-806e-9622-949a-bd1d9735a3f4"
      },
      "origin": "127.0.0.1",
      "url": "http://httpbin:8000/get"
    }
    {{< /text >}}

可以看到调用后端服务的请求已经成功！接下来，可以测试熔断。

## 触发熔断器{#tripping-the-circuit-breaker}

在 `DestinationRule` 配置中，您定义了 `maxConnections: 1` 和 `http1MaxPendingRequests: 1`。
这些规则意味着，如果并发的连接和请求数超过一个，在 `istio-proxy` 进行进一步的请求和连接时，后续请求或
连接将被阻止。

1. 发送并发数为 2 的连接（`-c 2`），请求 20 次（`-n 20`）：

    {{< text bash >}}
    $ kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
    Fortio 0.6.2 running at 0 queries per second, 2->2 procs, for 5s: http://httpbin:8000/get
    Starting at max qps with 2 thread(s) [gomax 2] for exactly 20 calls (10 per thread + 0)
    23:51:10 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    Ended after 106.474079ms : 20 calls. qps=187.84
    Aggregated Function Time : count 20 avg 0.010215375 +/- 0.003604 min 0.005172024 max 0.019434859 sum 0.204307492
    # range, mid point, percentile, count
    >= 0.00517202 <= 0.006 , 0.00558601 , 5.00, 1
    > 0.006 <= 0.007 , 0.0065 , 20.00, 3
    > 0.007 <= 0.008 , 0.0075 , 30.00, 2
    > 0.008 <= 0.009 , 0.0085 , 40.00, 2
    > 0.009 <= 0.01 , 0.0095 , 60.00, 4
    > 0.01 <= 0.011 , 0.0105 , 70.00, 2
    > 0.011 <= 0.012 , 0.0115 , 75.00, 1
    > 0.012 <= 0.014 , 0.013 , 90.00, 3
    > 0.016 <= 0.018 , 0.017 , 95.00, 1
    > 0.018 <= 0.0194349 , 0.0187174 , 100.00, 1
    # target 50% 0.0095
    # target 75% 0.012
    # target 99% 0.0191479
    # target 99.9% 0.0194062
    Code 200 : 19 (95.0 %)
    Code 503 : 1 (5.0 %)
    Response Header Sizes : count 20 avg 218.85 +/- 50.21 min 0 max 231 sum 4377
    Response Body/Total Sizes : count 20 avg 652.45 +/- 99.9 min 217 max 676 sum 13049
    All done 20 calls (plus 0 warmup) 10.215 ms avg, 187.8 qps
    {{< /text >}}

    有趣的是，几乎所有的请求都完成了！`istio-proxy` 确实允许存在一些误差。

    {{< text plain >}}
    Code 200 : 19 (95.0 %)
    Code 503 : 1 (5.0 %)
    {{< /text >}}

1. 将并发连接数提高到 3 个：

    {{< text bash >}}
    $ kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
    Fortio 0.6.2 running at 0 queries per second, 2->2 procs, for 5s: http://httpbin:8000/get
    Starting at max qps with 3 thread(s) [gomax 2] for exactly 30 calls (10 per thread + 0)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
    Ended after 71.05365ms : 30 calls. qps=422.22
    Aggregated Function Time : count 30 avg 0.0053360199 +/- 0.004219 min 0.000487853 max 0.018906468 sum 0.160080597
    # range, mid point, percentile, count
    >= 0.000487853 <= 0.001 , 0.000743926 , 10.00, 3
    > 0.001 <= 0.002 , 0.0015 , 30.00, 6
    > 0.002 <= 0.003 , 0.0025 , 33.33, 1
    > 0.003 <= 0.004 , 0.0035 , 40.00, 2
    > 0.004 <= 0.005 , 0.0045 , 46.67, 2
    > 0.005 <= 0.006 , 0.0055 , 60.00, 4
    > 0.006 <= 0.007 , 0.0065 , 73.33, 4
    > 0.007 <= 0.008 , 0.0075 , 80.00, 2
    > 0.008 <= 0.009 , 0.0085 , 86.67, 2
    > 0.009 <= 0.01 , 0.0095 , 93.33, 2
    > 0.014 <= 0.016 , 0.015 , 96.67, 1
    > 0.018 <= 0.0189065 , 0.0184532 , 100.00, 1
    # target 50% 0.00525
    # target 75% 0.00725
    # target 99% 0.0186345
    # target 99.9% 0.0188793
    Code 200 : 19 (63.3 %)
    Code 503 : 11 (36.7 %)
    Response Header Sizes : count 30 avg 145.73333 +/- 110.9 min 0 max 231 sum 4372
    Response Body/Total Sizes : count 30 avg 507.13333 +/- 220.8 min 217 max 676 sum 15214
    All done 30 calls (plus 0 warmup) 5.336 ms avg, 422.2 qps
    {{< /text >}}

    现在，您将开始看到预期的熔断行为，只有 63.3% 的请求成功，其余的均被熔断器拦截：

    {{< text plain >}}
    Code 200 : 19 (63.3 %)
    Code 503 : 11 (36.7 %)
    {{< /text >}}

1. 查询 `istio-proxy` 状态以了解更多熔断详情:

    {{< text bash >}}
    $ kubectl exec $FORTIO_POD -c istio-proxy -- pilot-agent request GET stats | grep httpbin | grep pending
    cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_active: 0
    cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_failure_eject: 0
    cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_overflow: 12
    cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_total: 39
    {{< /text >}}

    可以看到 `upstream_rq_pending_overflow` 值 `12`，这意味着，目前为止已有 12 个调用被标记为熔断。

## 清理{#cleaning-up}

1. 清理规则:

    {{< text bash >}}
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

1. 下线 [httpbin]({{< github_tree >}}/samples/httpbin) 服务和客户端：

    {{< text bash >}}
    $ kubectl delete deploy httpbin fortio-deploy
    $ kubectl delete svc httpbin
    {{< /text >}}

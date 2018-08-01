---
title: 熔断
description: 演示弹性应用所需的熔断能力
weight: 50
keywords: [traffic-management,circuit-breaking]
---

> 本文任务使用了新的 [v1alpha3 流量控制 API](/zh/blog/2018/v1alpha3-routing/)。旧版本 API 已经过时，会在下一个 Istio 版本中移除。如果需要使用旧版本 API，请阅读[旧版本文档](https://archive.istio.io/v0.7/docs/tasks/traffic-management/)

本任务演示了弹性应用所需的熔断能力。网络方面可能会发生一些大家不愿发生的问题，例如故障、延迟高峰等等，熔断功能能够帮助开发人员限制这些负面因素的影响范围。下面的内容会展示如何根据连接、请求以及外部检测的情况对断路器进行设置。

## 开始之前

* 跟随 [安装指南](/zh/docs/setup) 设置 Istio。
* 启动 [httpbin]({{< github_tree >}}/samples/httpbin) 示例应用，这个应用将会作为本任务的后端服务。

    如果启用了 [Sidecar 的自动注入](/zh/docs/setup/kubernetes/sidecar-injection/#sidecar-的自动注入)，只需运行：

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    否者就需要在部署 `httpbin` 应用之前手工注入 Sidecar 了：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    {{< /text >}}

## 断路器

接下来设置一个场景来演示 Istio 的熔断功能。在上一步骤中，我们已经启动了 `httpbin` 服务。

1. 创建一个 [目标规则](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule)，针对 `httpbin` 服务设置断路器：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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

1. 检查我们的目标规则，确定已经正确建立：

    {{< text bash yaml >}}
    $ istioctl get destinationrule httpbin -o yaml
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

### 设置客户端

现在我们已经设置了调用 `httpbin` 服务的规则，接下来创建一个客户端，用来向后端服务发送请求，观察是否会触发熔断策略。这里要使用一个简单的负载测试客户端，名字叫 [fortio](https://github.com/istio/fortio)。这个客户端可以控制连接数量、并发数以及发送 HTTP 请求的延迟。这里我们会把给客户端也进行 Sidecar 的注入，以此保证 Istio 对网络交互的控制：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/sample-client/fortio-deploy.yaml@)
{{< /text >}}

接下来就可以登入客户端 Pod 并使用 Fortio 工具来调用 `httpbin`。`-curl` 参数表明只调用一次：

{{< text bash >}}
$ FORTIO_POD=$(kubectl get pod | grep fortio | awk '{ print $1 }')
$ kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -curl  http://httpbin:8000/get
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

不难看出，调用已经成功。接下来做些变化。

### 触发熔断机制

在上面的熔断设置中指定了 `maxConnections: 1` 以及 `http1MaxPendingRequests: 1`。这意味着如果超过了一个连接同时发起请求，Istio 就会熔断，阻止后续的请求或连接。接下来尝试一下两个并发连接（`-c 2`），发送 20 请求（`-n 20`）：

{{< text bash >}}
$ kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
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

这里可以看到，几乎所有请求都通过了。

{{< text plain >}}
Code 200 : 19 (95.0 %)
Code 503 : 1 (5.0 %)
{{< /text >}}

Istio-proxy 允许一些余地。接下来把并发连接数量提高到 3：

{{< text bash >}}
$ kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -c 3 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
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

这时候会观察到，熔断行为按照之前的设计生效了：

{{< text plain >}}
Code 200 : 19 (63.3 %)
Code 503 : 11 (36.7 %)
{{< /text >}}

只有 63.3% 的请求获得通过，剩余请求被断路器拦截了。我们可以查询 istio-proxy 的状态，获取更多相关信息：

{{< text bash >}}
$ kubectl exec -it $FORTIO_POD  -c istio-proxy  -- sh -c 'curl localhost:15000/stats' | grep httpbin | grep pending
cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_active: 0
cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_failure_eject: 0
cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_overflow: 12
cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_total: 39
{{< /text >}}

`upstream_rq_pending_overflow`  的值是 `12`，说明有 `12` 次调用被标志为熔断。

## 清理

1. 清理规则

    {{< text bash >}}
    $ istioctl delete destinationrule httpbin
    {{< /text >}}

1. 关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务和客户端

    {{< text bash >}}
    $ kubectl delete deploy httpbin fortio-deploy
    $ kubectl delete svc httpbin
    {{< /text >}}

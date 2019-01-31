---
title: Circuit Breaking
description: This task shows you how to configure circuit breaking for connections, requests, and outlier detection.
weight: 50
keywords: [traffic-management,circuit-breaking]
---

This task shows you how to configure circuit breaking for connections, requests,
and outlier detection.

Circuit breaking is an important pattern for creating resilient microservice
applications. Circuit breaking allows you to write applications that limit the impact of failures, latency spikes, and other undesirable effects of network peculiarities.

In this task, you will configure circuit breaking rules and then test the
configuration by intentionally "tripping" the circuit breaker.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Add the [httpbin]({{< github_tree >}}/samples/httpbin) sample to the mesh:

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), run this command:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    otherwise, manually inject the sidecar before deploying the `httpbin` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    {{< /text >}}

    The `httpbin` application serves as the backend service for this task.

## Configuring the circuit breaker

1.  Create a [destination rule](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule) to apply circuit breaking settings
when calling the `httpbin` service:

    {{< warning >}}
    If you installed/configured Istio with mutual TLS Authentication enabled, you must add a TLS traffic policy `mode: ISTIO_MUTUAL` to the `DestinationRule` before applying it. Otherwise requests will generate 503 errors as described [here](/help/ops/traffic-management/troubleshooting/#503-errors-after-setting-destination-rule).
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

1.  Verify the destination rule was created correctly:

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

## Adding a client

Create a client to send traffic to the `httpbin` service. The client is
a simple load-testing client called [fortio](https://github.com/istio/fortio).
Fortio lets you control the number of connections, concurrency, and
delays for outgoing HTTP calls. You will use this client to "trip" the circuit breaker
policies you set in the `DestinationRule`. 

1. Inject the client with the Istio sidecar proxy so network interactions are
governed by Istio:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/sample-client/fortio-deploy.yaml@)
    {{< /text >}}

1. Log in to the client pod and use the fortio tool to call `httpbin`.
Pass in `-curl` to indicate that you just want to make one call:

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

You can see the request succeeded! Now, it's time to break something.

## Tripping the circuit breaker

In the `DestinationRule` settings, you specified `maxConnections: 1` and
`http1MaxPendingRequests: 1`. These rules indicate that if you exceed more than
one connection and request concurrently, you should see some failures when the
`istio-proxy` opens the circuit for further requests and connections.

1. Call the service with two concurrent connections (`-c 2`) and send 20 requests
(`-n 20`):

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

    It's interesting to see that almost all requests made it through! The `istio-proxy`
    does allow for some leeway.

    {{< text plain >}}
    Code 200 : 19 (95.0 %)
    Code 503 : 1 (5.0 %)
    {{< /text >}}

1. Bring the number of concurrent connections up to 3:

    {{< text bash >}}
    $ kubectl exec -it $FORTIO_POD  -c fortio /usr/local/bin/fortio -- load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
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

    Now you start to see the expected circuit breaking behavior. Only 63.3% of the
    requests succeeded and the rest were trapped by circuit breaking:

    {{< text plain >}}
    Code 200 : 19 (63.3 %)
    Code 503 : 11 (36.7 %)
    {{< /text >}}

1. Query the `istio-proxy` stats to see more:

    {{< text bash >}}
    $ kubectl exec -it $FORTIO_POD  -c istio-proxy  -- sh -c 'curl localhost:15000/stats' | grep httpbin | grep pending
    cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_active: 0
    cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_failure_eject: 0
    cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_overflow: 12
    cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_total: 39
    {{< /text >}}

    You can see `12` for the `upstream_rq_pending_overflow` value which means `12`
    calls so far have been flagged for circuit breaking.

## Cleaning up

1.  Remove the rules:

    {{< text bash >}}
    $ kubectl delete destinationrule httpbin
    {{< /text >}}

1.  Shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service and client:

    {{< text bash >}}
    $ kubectl delete deploy httpbin fortio-deploy
    $ kubectl delete svc httpbin
    {{< /text >}}

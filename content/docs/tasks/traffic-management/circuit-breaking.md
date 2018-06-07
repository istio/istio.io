---
title: Circuit Breaking
description: This task demonstrates the circuit-breaking capability for resilient applications
weight: 50
---

> This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/).

This task demonstrates the circuit-breaking capability for resilient applications. Circuit breaking allows developers to write applications that limit the impact of failures, latency spikes, and other undesirable effects of network peculiarities. This task will show how to configure circuit breaking for connections, requests, and outlier detection.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

*   Start the [httpbin](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/httpbin) sample
    which will be used as the backend service for our task.

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), do

    ```command
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    ```
    otherwise, you have to manually inject the sidecar before deploying the `httpbin` application:

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    ```

## Circuit breaker

Let's set up a scenario to demonstrate the circuit-breaking capabilities of Istio. We should have the `httpbin` service running from the previous section.

1.  Create a [destination rule](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule) to specify our circuit breaking settings when calling the `httpbin` service:

    ```bash
    cat <<EOF | istioctl create -f -
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
          http:
            consecutiveErrors: 1
            interval: 1s
            baseEjectionTime: 3m
            maxEjectionPercent: 100
    EOF
    ```

1.  Verify our destination rule was created correctly:

    ```command-output-as-yaml
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
          http:
            baseEjectionTime: 180.000s
            consecutiveErrors: 1
            interval: 1.000s
            maxEjectionPercent: 100
    ```

### Setting up our client

Now that we've set up rules for calling the `httpbin` service, let's create a client we can use to send traffic to our service and see whether we can trip the circuit breaking policies. We're going to use a simple load-testing client called [fortio](https://github.com/istio/fortio). With this client we can control the number of connections, concurrency, and delays of outgoing HTTP calls. In this step, we'll set up a client that is injected with the istio sidecar proxy so our network interactions are governed by Istio:

```command
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/sample-client/fortio-deploy.yaml@)
```

Now we should be able to log into that client pod and use the simple fortio tool to call `httpbin`. We'll pass in `-curl` to indicate we just want to make one call:

```command
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
```

You can see the request succeeded! Now, let's break something.

### Tripping the circuit breaker

In the circuit-breaking settings, we specified `maxConnections: 1` and `http1MaxPendingRequests: 1`. This should mean that if we exceed more than one connection and request concurrently, we should see the istio-proxy open the circuit for further requests/connections. Let's try with two concurrent connections (`-c 2`) and send 20 requests (`-n 20`)

```command
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
```

We see almost all requests made it through!

```plain
Code 200 : 19 (95.0 %)
Code 503 : 1 (5.0 %)
```

The istio-proxy does allow for some leeway. Let's bring the number of concurrent connections up to 3:

```command
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
```

Now we start to see the circuit breaking behavior we expect.

```plain
Code 200 : 19 (63.3 %)
Code 503 : 11 (36.7 %)
```

Only 63.3% of the requests made it through and the rest were trapped by circuit breaking. We can query the istio-proxy stats to see more:

```command
$ kubectl exec -it $FORTIO_POD  -c istio-proxy  -- sh -c 'curl localhost:15000/stats' | grep httpbin | grep pending
cluster.out.httpbin.springistio.svc.cluster.local|http|version=v1.upstream_rq_pending_active: 0
cluster.out.httpbin.springistio.svc.cluster.local|http|version=v1.upstream_rq_pending_failure_eject: 0
cluster.out.httpbin.springistio.svc.cluster.local|http|version=v1.upstream_rq_pending_overflow: 12
cluster.out.httpbin.springistio.svc.cluster.local|http|version=v1.upstream_rq_pending_total: 39
```

We see `12` for the `upstream_rq_pending_overflow` value which means `12` calls so far have been flagged for circuit breaking.

## Cleaning up

1.  Remove the rules.

    ```command
    $ istioctl delete destinationrule httpbin
    ```

1.  Shutdown the [httpbin](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/httpbin) service and client.

    ```command
    $ kubectl delete deploy httpbin fortio-deploy
    $ kubectl delete svc httpbin
    ```

## What's next

Check out the [destination rule](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule) reference section for more circuit breaker settings.

---
title: Request Timeouts
description: This task shows you how to set up request timeouts in Envoy using Istio.
weight: 40
aliases:
    - /docs/tasks/request-timeouts.html
keywords: [traffic-management,timeouts]
owner: istio/wg-networking-maintainers
test: yes
---

This task shows you how to set up request timeouts in Envoy using Istio.

{{< boilerplate gateway-api-gamma-support >}}

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application including the
  [service versions](/docs/examples/bookinfo/#define-the-service-versions).

## Request timeouts

A timeout for HTTP requests can be specified using a timeout field in a route rule.
By default, the request timeout is disabled, but in this task you override the `reviews` service
timeout to half a second.
To see its effect, however, you also introduce an artificial 2 second delay in calls
to the `ratings` service.

1.  Route requests to v2 of the `reviews` service, i.e., a version that calls the `ratings` service:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v2
      port: 9080
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Add a 2 second delay to calls to the `ratings` service:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
        subset: v1
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Gateway API does not support fault injection yet, so we need to use an Istio `VirtualService` to
add the delay for now:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Open the Bookinfo URL `http://$GATEWAY_URL/productpage` in your browser, where `$GATEWAY_URL` is the External IP address of the ingress, as explained in
the [Bookinfo](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) doc.

    You should see the Bookinfo application working normally (with ratings stars displayed),
    but there is a 2 second delay whenever you refresh the page.

4)  Now add a half second request timeout for calls to the `reviews` service:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v2
      port: 9080
    timeouts:
      request: 500ms
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Refresh the Bookinfo web page.

    You should now see that it returns in about 1 second, instead of 2, and the reviews are unavailable.

    {{< tip >}}
    The reason that the response takes 1 second, even though the timeout is configured at half a second, is
    because there is a hard-coded retry in the `productpage` service, so it calls the timing out `reviews` service
    twice before returning.
    {{< /tip >}}

## Understanding what happened

In this task, you used Istio to set the request timeout for calls to the `reviews`
microservice to half a second. By default the request timeout is disabled.
Since the `reviews` service subsequently calls the `ratings` service when handling requests,
you used Istio to inject a 2 second delay in calls to `ratings` to cause the
`reviews` service to take longer than half a second to complete and consequently you could see the timeout in action.

You observed that instead of displaying reviews, the Bookinfo product page (which calls the `reviews` service to populate the page) displayed
the message: Sorry, product reviews are currently unavailable for this book.
This was the result of it receiving the timeout error from the `reviews` service.

If you examine the [fault injection task](/docs/tasks/traffic-management/fault-injection/), you'll find out that the `productpage`
microservice also has its own application-level timeout (3 seconds) for calls to the `reviews` microservice.
Notice that in this task you used an Istio route rule to set the timeout to half a second.
Had you instead set the timeout to something greater than 3 seconds (such as 4 seconds) the timeout
would have had no effect since the more restrictive of the two takes precedence.
More details can be found [here](/docs/concepts/traffic-management/#network-resilience-and-testing).

One more thing to note about timeouts in Istio is that in addition to overriding them in route rules,
as you did in this task, they can also be overridden on a per-request basis if the application adds
an `x-envoy-upstream-rq-timeout-ms` header on outbound requests. In the header,
the timeout is specified in milliseconds instead of seconds.

## Cleanup

*   Remove the application routing rules:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete httproute reviews
$ kubectl delete virtualservice ratings
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* If you are not planning to explore any follow-on tasks, see the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.

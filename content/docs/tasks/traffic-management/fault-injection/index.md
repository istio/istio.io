---
title: Fault Injection
description: This task shows you how to inject faults to test the resiliency of your application.
weight: 20
keywords: [traffic-management,fault-injection]
aliases:
    - /docs/tasks/fault-injection.html
---

This task shows you how to inject faults to test the resiliency of your application.

## Before you begin

* Set up Istio by following the instructions in the
  [Installation guide](/docs/setup/).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

* Review the fault injection discussion in the
[Traffic Management](/docs/concepts/traffic-management) concepts doc.

* Apply application version routing by either performing the
  [request routing](/docs/tasks/traffic-management/request-routing/) task or by
  running the following commands:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

* With the above configuration, this is how requests flow:
    *  `productpage` → `reviews:v2` → `ratings` (only for user `jason`)
    *  `productpage` → `reviews:v1` (for everyone else)

## Injecting an HTTP delay fault

To test the Bookinfo application microservices for resiliency, inject a 7s delay
between the `reviews:v2` and `ratings` microservices for user `jason`. This test
will uncover a bug that was intentionally introduced into the Bookinfo app.

Note that the `reviews:v2` service has a 10s hard-coded connection timeout for
calls to the ratings service. Even with the 7s delay that you introduced, you
still expect the end-to-end flow to continue without any errors.

1.  Create a fault injection rule to delay traffic coming from the test user
`jason`.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml@
    {{< /text >}}

1. Confirm the rule was created:

    {{< text bash yaml >}}
    $ kubectl get virtualservice ratings -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
      ...
    spec:
      hosts:
      - ratings
      http:
      - fault:
          delay:
            fixedDelay: 7s
            percent: 100
        match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

    Allow several seconds for the new rule to propagate to all pods.

## Testing the delay configuration

1. Open the [Bookinfo](/docs/examples/bookinfo) web application in your browser.

1. On the `/productpage`, log in as user `jason`.

    You expect the Bookinfo home page to load without errors in approximately
    7 seconds. However, there is a problem: the Reviews section displays an error
    message:

    {{< text plain >}}
    Error fetching product reviews!
    Sorry, product reviews are currently unavailable for this book.
    {{< /text >}}

1. View the web page response times:
    1. Open the *Developer Tools* menu in you web browser.
    1. Open the Network tab
    1. Reload the `productpage` web page. You will see that the webpage actually
    loads in about 6 seconds.

## Understanding what happened

You've found a bug. There are hard-coded timeouts in the microservices that have
caused the `reviews` service to fail.

The timeout between the
`productpage` and the `reviews` service is 6 seconds - coded as 3s + 1 retry
for 6s total. The timeout between the `reviews` and `ratings`
service is hard-coded at 10 seconds. Because of the delay we introduced, the `/productpage` times out prematurely and throws the error.

Bugs like this can occur in typical enterprise applications where different teams
develop different microservices independently. Istio's fault injection rules help you identify such anomalies without impacting end users.

{{< tip >}}
Notice that the fault injection test is restricted to when the logged in user is
`jason`. If you login as any other user, you will not experience any delays.
{{< /tip >}}

## Fixing the bug

You would normally fix the problem by:

1. Either increasing the
`/productpage` timeout or decreasing the `reviews` to `ratings` service timeout
1. Stopping and restarting the fixed microservice
1. Confirming that the `/productpage` returns its response without any errors.

However, you already have this fix running in v3 of the reviews service, so you
can simply fix the problem by migrating all traffic to `reviews:v3` as described
in the [traffic shifting](/docs/tasks/traffic-management/traffic-shifting/) task.

## Exercise

Change the delay rule to use a 2.8 second delay and then run it against the v3
version of reviews.

## Injecting an HTTP abort fault

Another way to test microservice resiliency is to introduce an HTTP abort fault.
In this task, you will introduce an HTTP abort to the `ratings` microservices for
the test user `jason`.

In this case, you expect the page to load immediately and display the `Ratings
service is currently unavailable` message.

1.  Create a fault injection rule to send an HTTP abort for user `jason`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml@
    {{< /text >}}

1. Confirm the rule was created:

    {{< text bash yaml >}}
    $ kubectl get virtualservice ratings -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
      ...
    spec:
      hosts:
      - ratings
      http:
      - fault:
          abort:
            httpStatus: 500
            percent: 100
        match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

## Testing the abort configuration

1. Open the [Bookinfo](/docs/examples/bookinfo) web application in your browser.

1. On the `/productpage`, log in as user `jason`.

    If the rule propagated successfully to all pods, the page loads
    immediately and the `Ratings service is currently unavailable` message appears.

1. If you log out from user `jason` or open the Bookinfo application in an anonymous
   window (or in another browser), you will see that `/productpage` still calls `reviews:v1`
   (which does not call `ratings` at all) for everybody but `jason`. Therefore you
   will not see any error message.

## Cleanup

1. Remove the application routing rules:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, refer to the
[Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
to shutdown the application.

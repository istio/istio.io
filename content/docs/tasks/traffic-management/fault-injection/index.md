---
title: Fault Injection
description: This task shows how to inject delays and test the resiliency of your application.
weight: 20
keywords: [traffic-management,fault-injection]
aliases:
    - /docs/tasks/fault-injection.html
---

> This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/).

This task shows how to inject delays and test the resiliency of your application.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

*   Initialize the application version routing by either first doing the
    [request routing](/docs/tasks/traffic-management/request-routing/) task or by running following
    commands:

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/routing/route-rule-all-v1.yaml@
    $ istioctl replace -f @samples/bookinfo/routing/route-rule-reviews-test-v2.yaml@
    {{< /text >}}

## Fault injection using HTTP delay

To test our Bookinfo application microservices for resiliency, we will _inject a 7s delay_
between the reviews:v2 and ratings microservices, for user "jason". Since the _reviews:v2_ service has a
10s hard-coded connection timeout for its calls to the ratings service, we expect the end-to-end flow to
continue without any errors.

1.  Create a fault injection rule to delay traffic coming from user "jason" (our test user)

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/routing/route-rule-ratings-test-delay.yaml@
    {{< /text >}}

    Confirm the rule is created:

    {{< text bash yaml >}}
    $ istioctl get virtualservice ratings -o yaml
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
            cookie:
              regex: ^(.*?;)?(user=jason)(;.*)?$
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

    Allow several seconds to account for rule propagation delay to all pods.

1.  Observe application behavior

    Log in as user "jason". If the application's front page was set to correctly handle delays, we expect it
    to load within approximately 7 seconds. To see the web page response times, open the
    *Developer Tools* menu in IE, Chrome or Firefox (typically, key combination _Ctrl+Shift+I_
    or _Alt+Cmd+I_), tab Network, and reload the `productpage` web page.

    You will see that the webpage loads in about 6 seconds. The reviews section will show
    *Sorry, product reviews are currently unavailable for this book*.

## Understanding what happened

The reason that the entire reviews service has failed is because our Bookinfo application
has a bug. The timeout between the productpage and reviews service is less (3s + 1 retry = 6s total)
than the timeout between the reviews and ratings service (hard-coded connection timeout is 10s). These
kinds of bugs can occur in typical enterprise applications where different teams develop different
microservices independently. Istio's fault injection rules help you identify such anomalies without
impacting end users.

> Notice that we are restricting the failure impact to user "jason" only. If you login
> as any other user, you would not experience any delays.

**Fixing the bug:** At this point we would normally fix the problem by either increasing the
productpage timeout or decreasing the reviews to ratings service timeout,
terminate and restart the fixed microservice, and then confirm that the `productpage`
returns its response without any errors.

However, we already have this fix running in v3 of the reviews service, so we can simply
fix the problem by migrating all
traffic to `reviews:v3` as described in the
[traffic shifting](/docs/tasks/traffic-management/traffic-shifting/) task.

(Left as an exercise for the reader - change the delay rule to
use a 2.8 second delay and then run it against the v3 version of reviews.)

## Fault injection using HTTP Abort

As another test of resiliency, we will introduce an HTTP abort to the ratings microservices for the user "jason".
We expect the page to load immediately unlike the delay example and display the "product ratings not available"
message.

1.  Create a fault injection rule to send an HTTP abort for user "jason"

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/routing/route-rule-ratings-test-abort.yaml@
    {{< /text >}}

    Confirm the rule is created

    {{< text bash yaml >}}
    $ istioctl get virtualservice ratings -o yaml
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
            cookie:
              regex: ^(.*?;)?(user=jason)(;.*)?$
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

1.  Observe application behavior

    Login as user "jason". If the rule propagated successfully to all pods, you should see the page load
    immediately with the "product ratings not available" message. Logout from user "jason" and you should
    see reviews with rating stars show up successfully on the productpage web page.

## Cleanup

*   Remove the application routing rules:

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/routing/route-rule-all-v1.yaml@
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.

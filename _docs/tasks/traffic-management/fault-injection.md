---
title: Fault Injection
description: This task shows how to inject delays and test the resiliency of your application.

weight: 20

---
{% include home.html %}

> Note: This task uses the new [v1alpha3 traffic management API]({{home}}/blog/2018/v1alpha3-routing.html). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.6/docs/tasks/).

This task shows how to inject delays and test the resiliency of your application.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).

* Deploy the [Bookinfo]({{home}}/docs/guides/bookinfo.html) sample application.

*   Initialize the application version routing by either first doing the
    [request routing](./request-routing.html) task or by running following
    commands:

    ```command
    $ istioctl create -f samples/bookinfo/routing/route-rule-all-v1.yaml
    $ istioctl replace -f samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
    ```

# Fault injection

## Fault injection using HTTP delay

To test our Bookinfo application microservices for resiliency, we will _inject a 7s delay_
between the reviews:v2 and ratings microservices, for user "jason". Since the _reviews:v2_ service has a
10s timeout for its calls to the ratings service, we expect the end-to-end flow to
continue without any errors.

1.  Create a fault injection rule to delay traffic coming from user "jason" (our test user)

    ```command
    $ istioctl replace -f samples/bookinfo/routing/route-rule-ratings-test-delay.yaml
    ```

    Confirm the rule is created:

    ```command-output-as-yaml
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
            name: ratings
            subset: v1
      - route:
        - destination:
            name: ratings
            subset: v1
    ```

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
than the timeout between the reviews and ratings service (10s). These kinds of bugs can occur in
typical enterprise applications where different teams develop different microservices
independently. Istio's fault injection rules help you identify such anomalies without
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
[traffic shifting]({{home}}/docs/tasks/traffic-management/traffic-shifting.html) task.

(Left as an exercise for the reader - change the delay rule to
use a 2.8 second delay and then run it against the v3 version of reviews.)

## Fault injection using HTTP Abort

As another test of resiliency, we will introduce an HTTP abort to the ratings microservices for the user "jason".
We expect the page to load immediately unlike the delay example and display the "product ratings not available"
message.

1.  Create a fault injection rule to send an HTTP abort for user "jason"

    ```command
    $ istioctl replace -f samples/bookinfo/routing/route-rule-ratings-test-abort.yaml
    ```

    Confirm the rule is created

    ```command-output-as-yaml
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
            name: ratings
            subset: v1
      - route:
        - destination:
            name: ratings
            subset: v1
    ```

1.  Observe application behavior

    Login as user "jason". If the rule propagated successfully to all pods, you should see the page load
    immediately with the "product ratings not available" message. Logout from user "jason" and you should
    see reviews with rating stars show up successfully on the productpage web page.

## Cleanup

*   Remove the application routing rules:

    ```command
    $ istioctl delete -f samples/bookinfo/routing/route-rule-all-v1.yaml
    ```

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
  to shutdown the application.

## What's next

* Learn more about [fault injection]({{home}}/docs/concepts/traffic-management/fault-injection.html).

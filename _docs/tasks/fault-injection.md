---
title: Fault Injection
overview: This task shows how to inject delays and test the resiliency of your application.
            
order: 60

layout: docs
type: markdown
---

This task shows how to inject delays and test the resiliency of your application.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/tasks/installing-istio.html).

* Deploy the [bookinfo](/docs/samples/bookinfo.html) sample application.

* Initialize the application version routing by either first doing the
  [request routing](/docs/tasks/request-routing.html) task or by running following
  commands:
  
  ```bash
  $ istioctl create -f route-rule-all-v1.yaml
  $ istioctl create -f route-rule-reviews-test-v2.yaml
  ```

## Fault injection

To test our bookinfo application microservices for resiliency, we will _inject a 7s delay_
between the reviews:v2 and ratings microservices. Since the _reviews:v2_ service has a
10s timeout for its calls to the ratings service, we expect the end-to-end flow to
continue without any errors.

1. Create a fault injection rule to delay traffic coming from user "jason" (our test user)

   ```bash
   istioctl create -f destination-ratings-test-delay.yaml
   ```
   
   Confirm the rule is created:
   
   ```yaml
   $ istioctl get route-rule ratings-test-delay
   destination: ratings.default.svc.cluster.local
   httpFault:
     delay:
       fixedDelay: 7s
       percent: 100
   match:
     httpHeaders:
       Cookie:
         regex: "^(.*?;)?(user=jason)(;.*)?$"
   precedence: 2
   route:
   - tags:
       version: v1
   ```
   
   Allow several seconds to account for rule propagation delay to all pods.

1. Observe application behavior

   If the application's front page was set to correctly handle delays, we expect it
   to load within approximately 7 seconds. To see the web page response times, open the
   *Developer Tools* menu in IE, Chrome or Firefox (typically, key combination _Ctrl+Shift+I_
   or _Alt+Cmd+I_) and reload the `productpage` web page.

   You will see that the webpage loads in about 6 seconds. The reviews section will show
   *Sorry, product reviews are currently unavailable for this book*.

## Understanding what happened

   The reason that the entire reviews service has failed is because our bookinfo application
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
  traffic to `reviews:v3` as described in the [request routing task](/docs/tasks/request-routing.html).
         
  (Left as an exercise for the reader - change the delay rule to
  use a 2.8 second delay and then run it against the v3 version of reviews.)

## What's next

* Learn more about [fault injection](/docs/concepts/traffic-management/fault-injection.html).

* Limit requests to the bookinfo `ratings` service with Istio [rate limiting](/docs/tasks/rate-limiting.html).

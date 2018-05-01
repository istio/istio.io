---
title: Configuring Request Routing
description: This task shows you how to configure dynamic request routing based on weights and HTTP headers.

weight: 10

---
{% include home.html %}

This task shows you how to configure dynamic request routing based on weights and HTTP headers.

## Before you begin

* Setup Istio by following the instructions in the
[Installation guide]({{home}}/docs/setup/).

* Deploy the [Bookinfo]({{home}}/docs/guides/bookinfo.html) sample application.

## Content-based routing

Because the Bookinfo sample deploys 3 versions of the reviews microservice,
we need to set a default route.
Otherwise if you access the application several times, you'll notice that sometimes the output contains
star ratings.
This is because without an explicit default version set, Istio will
route requests to all available versions of a service in a random fashion.

> This task assumes you don't have any routes set yet. If you've already created conflicting route rules for the sample,
you'll need to use `replace` rather than `create` in the following command.

1. Set the default version for all microservices to v1.

   ```bash
   istioctl create -f samples/bookinfo/routing/route-rule-all-v1.yaml
   ```

   > In a Kubernetes deployment of Istio, you can replace `istioctl`
   > with `kubectl` in the above, and for all other CLI commands.
   > Note, however, that `kubectl` currently does not provide input validation.

   You can display the routes that are defined with the following command:

   ```bash
   istioctl get virtualservices -o yaml
   ```

   ```yaml
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: details
     ...
   spec:
     hosts:
     - details
     http:
     - route:
       - destination:
           name: details
           subset: v1
   ---
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: productpage
     ...
   spec:
     gateways:
     - bookinfo-gateway
     - mesh
     hosts:
     - productpage
     http:
     - route:
       - destination:
           name: productpage
           subset: v1
   ---
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: ratings
     ...
   spec:
     hosts:
     - ratings
     http:
     - route:
       - destination:
           name: ratings
           subset: v1
   ---
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: reviews
     ...
   spec:
     hosts:
     - reviews
     http:
     - route:
       - destination:
           name: reviews
           subset: v1
   ---
   ```

   > The corresponding `subset` definitions can be displayed using `istioctl get destinationrules -o yaml`.

   Since rule propagation to the proxies is asynchronous, you should wait a few seconds for the rules
   to propagate to all pods before attempting to access the application.

1. Open the Bookinfo URL (http://$GATEWAY_URL/productpage) in your browser

   You should see the Bookinfo application productpage displayed.
   Notice that the `productpage` is displayed with no rating stars since `reviews:v1` does not access the ratings service.

1. Route a specific user to `reviews:v2`

   Lets enable the ratings service for test user "jason" by routing productpage traffic to
   `reviews:v2` instances.

   ```bash
   istioctl replace -f samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
   ```

   Confirm the rule is created:

   ```bash
   istioctl get virtualservice reviews -o yaml
   ```
   ```yaml
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: reviews
     ...
   spec:
     hosts:
     - reviews
     http:
     - match:
       - headers:
           cookie:
             regex: ^(.*?;)?(user=jason)(;.*)?$
       route:
       - destination:
           name: reviews
           subset: v2
     - route:
       - destination:
           name: reviews
           subset: v1
   ```

1. Log in as user "jason" at the `productpage` web page.

   You should now see ratings (1-5 stars) next to each review. Notice that if you log in as
   any other user, you will continue to see `reviews:v1`.

## Understanding what happened

In this task, you used Istio to send 100% of the traffic to the v1 version of each of the Bookinfo
services. You then set a rule to selectively send traffic to version v2 of the reviews service based
on a header (i.e., a user cookie) in a request.

Once the v2 version has been tested to our satisfaction, we could use Istio to send traffic from
all users to v2, optionally in a gradual fashion. We'll explore this in a separate task.

## Cleanup

* Remove the application routing rules.

  ```bash
  istioctl delete -f samples/bookinfo/routing/route-rule-all-v1.yaml
  ```

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
  to shutdown the application.

## What's next

* Learn more about [request routing]({{home}}/docs/concepts/traffic-management/rules-configuration.html).

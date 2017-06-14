---
title: Configuring Request Routing
overview: This task shows you how to configure dynamic request routing based on weights and HTTP headers.

order: 50

layout: docs
type: markdown
---
{% include home.html %}

This task shows you how to configure dynamic request routing based on weights and HTTP headers.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](./installing-istio.html).

* Deploy the [BookInfo]({{home}}/docs/samples/bookinfo.html) sample application.

## Content-based routing

Because the BookInfo sample deploys 3 versions of the reviews microservice,
we need to set a default route.
Otherwise if you access the application several times, you'll notice that sometimes the output contains
star ratings.
This is because without an explicit default version set, Istio will
route requests to all available versions of a service in a random fashion.

> Note: This task assumes you don't have any routes set yet. If you've already created conflicting route rules for the sample, you'll need to use `replace` rather than `create` in one or both of the following commands.

1. Set the default version for all microservices to v1.

   ```bash
   istioctl create -f samples/apps/bookinfo/route-rule-all-v1.yaml
   ```

   You can display the routes that are defined with the following command:

   ```bash
   istioctl get route-rules -o yaml
   ```
   ```yaml
   type: route-rule
   name: ratings-default
   namespace: default
   spec:
     destination: ratings.default.svc.cluster.local
     precedence: 1
     route:
     - tags:
         version: v1
       weight: 100
   ---
   type: route-rule
   name: reviews-default
   namespace: default
   spec:
     destination: reviews.default.svc.cluster.local
     precedence: 1
     route:
     - tags:
         version: v1
       weight: 100
   ---
   type: route-rule
   name: details-default
   namespace: default
   spec:
     destination: details.default.svc.cluster.local
     precedence: 1
     route:
     - tags:
         version: v1
       weight: 100
   ---
   type: route-rule
   name: productpage-default
   namespace: default
   spec:
     destination: productpage.default.svc.cluster.local
     precedence: 1
     route:
     - tags:
         version: v1
       weight: 100
   ---
   ```

   Since rule propagation to the proxies is asynchronous, you should wait a few seconds for the rules
   to propagate to all pods before attempting to access the application.

1. Open the BookInfo URL (http://$GATEWAY_URL/productpage) in your browser

   You should see the BookInfo application productpage displayed.
   Notice that the `productpage` is displayed with no rating stars since `reviews:v1` does not access the ratings service.

1. Route a specific user to `reviews:v2`

   Lets enable the ratings service for test user "jason" by routing productpage traffic to
   `reviews:v2` instances.

   ```bash
   istioctl create -f samples/apps/bookinfo/route-rule-reviews-test-v2.yaml
   ```

   Confirm the rule is created:

   ```bash
   istioctl get route-rule reviews-test-v2
   ```
   ```yaml
   destination: reviews.default.svc.cluster.local
   match:
     httpHeaders:
       cookie:
         regex: ^(.*?;)?(user=jason)(;.*)?$
   precedence: 2
   route:
   - tags:
       version: v2
   ```

1. Log in as user "jason" at the `productpage` web page.

   You should now see ratings (1-5 stars) next to each review. Notice that if you log in as
   any other user, you will continue to see `reviews:v1`.

## Understanding what happened

In this task, you used Istio to send 100% of the traffic to the v1 version of each of the BookInfo
services. You then set a rule to selectively send traffic to version v2 of the reviews service based
on a header (i.e., a user cookie) in a request.

Once the v2 version has been tested to our satisfaction, we could use Istio to send traffic from
all users to v2, optionally in a gradual fashion by using a sequence of rules with weights less
than 100 to migrate traffic in steps, for example 10, 20, 30, ... 100%.

If you now proceed to the [fault injection task](./fault-injection.html), you will see
that with simple testing, the v2 version of the reviews service has a bug, which is fixed in v3.
So after exploring that task, you can route all user traffic from `reviews:v1`
to `reviews:v3` in two steps as follows:

1. First, transfer 50% of traffic from `reviews:v1` to `reviews:v3` with the following command:

   ```bash
   istioctl replace -f samples/apps/bookinfo/route-rule-reviews-50-v3.yaml
   ```

   Notice that we are using `istioctl replace` instead of `create`.

2. To see the new version you need to either Log out as test user "jason" or delete the test rules
that we created exclusively for him:

   ```bash
   istioctl delete route-rule reviews-test-v2
   istioctl delete route-rule ratings-test-delay
   ```

   You should now see *red* colored star ratings approximately 50% of the time when you refresh
   the `productpage`.

   > Note: With the Envoy sidecar implementation, you may need to refresh the `productpage` multiple times
   > to see the proper distribution. You can modify the rules to route 90% of the traffic to v3 to see red stars more often.

3. When version v3 of the reviews microservice is stable, route 100% of the traffic to `reviews:v3`:

   ```bash
   istioctl replace -f samples/apps/bookinfo/route-rule-reviews-v3.yaml
   ```

   You can now log in to the `productpage` as any user and you should always see book reviews
   with *red* colored star ratings for each review.

## What's next

* Learn more about [request routing]({{home}}/docs/concepts/traffic-management/rules-configuration.html).

* Test the BookInfo application resiliency by [injecting faults](./fault-injection.html).

* If you are not planning to explore any follow-on tasks, refer to the
  [BookInfo cleanup]({{home}}/docs/samples/bookinfo.html#cleanup) instructions
  to shutdown the application and cleanup the associated rules.

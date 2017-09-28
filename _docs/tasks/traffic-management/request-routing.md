---
title: Configuring Request Routing
overview: This task shows you how to configure dynamic request routing based on weights and HTTP headers.

order: 10

layout: docs
type: markdown
redirect_from: "/docs/tasks/request-routing.html"
---
{% include home.html %}

This task shows you how to configure dynamic request routing based on weights and HTTP headers.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).

* Deploy the [BookInfo]({{home}}/docs/guides/bookinfo.html) sample application.

> Note: This task assumes you are deploying the application on Kubernetes.
  All of the example commands are using the Kubernetes version of the rule yaml files
  (e.g., `samples/bookinfo/kube/route-rule-all-v1.yaml`). If you are running this
  task in a different environment, change `kube` to the directory that corresponds
  to your runtime (e.g., samples/bookinfo/consul/route-rule-all-v1.yaml for
  the Consul-based runtime).

## Content-based routing

Because the BookInfo sample deploys 3 versions of the reviews microservice,
we need to set a default route.
Otherwise if you access the application several times, you'll notice that sometimes the output contains
star ratings.
This is because without an explicit default version set, Istio will
route requests to all available versions of a service in a random fashion.

> Note: This task assumes you don't have any routes set yet. If you've already created conflicting route rules for the sample,
  you'll need to use `replace` rather than `create` in one or both of the following commands.

1. Set the default version for all microservices to v1.

   ```bash
   istioctl create -f samples/bookinfo/kube/route-rule-all-v1.yaml
   ```

   > Note: In a Kubernetes deployment of Istio, you can replace `istioctl`
   > with `kubectl` in the above, and for all other CLI commands.
   > Note, however, that `kubectl` currently does not provide input validation.

   You can display the routes that are defined with the following command:

   ```bash
   istioctl get routerules -o yaml
   ```
   ```yaml
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: details-default
     namespace: default
     ...
   spec:
     destination:
       name: details
     precedence: 1
     route:
     - labels:
         version: v1
   ---
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: productpage-default
     namespace: default
     ...
   spec:
     destination:
       name: productpage
     precedence: 1
     route:
     - labels:
         version: v1
   ---
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: ratings-default
     namespace: default
     ...
   spec:
     destination:
       name: ratings
     precedence: 1
     route:
     - labels:
         version: v1
   ---
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: reviews-default
     namespace: default
     ...
   spec:
     destination:
       name: reviews
     precedence: 1
     route:
     - labels:
         version: v1
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
   istioctl create -f samples/bookinfo/kube/route-rule-reviews-test-v2.yaml
   ```

   Confirm the rule is created:

   ```bash
   istioctl get routerule reviews-test-v2 -o yaml
   ```
   ```yaml
   apiVersion: config.istio.io/v1alpha2
   kind: RouteRule
   metadata:
     name: reviews-test-v2
     namespace: default
     ...
   spec:
     destination:
       name: reviews
     match:
       request:
         headers:
           cookie:
             regex: ^(.*?;)?(user=jason)(;.*)?$
     precedence: 2
     route:
     - labels:
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
all users to v2, optionally in a gradual fashion. We'll explore this in a separate task.

## Cleanup

* Remove the application routing rules.

  For Kubernetes-based setup, use the following command:

  ```bash
  istioctl delete -f samples/bookinfo/kube/route-rule-all-v1.yaml
  istioctl delete -f samples/bookinfo/kube/route-rule-reviews-test-v2.yaml
  ```

  For Consul-based setup, use the following command:

  ```bash
  istioctl delete -f samples/bookinfo/consul/route-rule-all-v1.yaml
  istioctl delete -f samples/bookinfo/consul/route-rule-reviews-test-v2.yaml
  ```

## What's next

* Learn more about [request routing]({{home}}/docs/concepts/traffic-management/rules-configuration.html).

* Test the BookInfo application resiliency by [injecting faults](./fault-injection.html).

* If you are not planning to explore any follow-on tasks, refer to the
  [BookInfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
  to shutdown the application and cleanup the associated rules.

---
title: Traffic Shifting
overview: This task shows you how to migrate traffic from an old to new version of a service.

order: 25

layout: docs
type: markdown
---
{% include home.html %}

This task shows you how to gradually migrate traffic from an old to new version of a service.
With Istio, we can migrate the traffic in a gradual fashion by using a sequence of rules
with weights less than 100 to migrate traffic in steps, for example 10, 20, 30, ... 100%.
For simplicity this task will migrate the traffic from `reviews:v1` to `reviews:v3` in just
two steps: 50%, 100%.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).

* Deploy the [BookInfo]({{home}}/docs/guides/bookinfo.html) sample application.

> Note: This task assumes you are deploying the application on Kubernetes.
  All of the example commands are using the Kubernetes version of the rule yaml files
  (e.g., `samples/bookinfo/kube/route-rule-all-v1.yaml`). If you are running this
  task in a different environment, change `kube` to the directory that corresponds
  to your runtime (e.g., `samples/bookinfo/consul/route-rule-all-v1.yaml` for
  the Consul-based runtime).

## Weight-based version routing

1. Set the default version for all microservices to v1.

   ```bash
   istioctl create -f samples/bookinfo/kube/route-rule-all-v1.yaml
   ```

1. Confirm v1 is the active version of the `reviews` service by opening http://$GATEWAY_URL/productpage in your browser.

   You should see the BookInfo application productpage displayed.
   Notice that the `productpage` is displayed with no rating stars since `reviews:v1` does not access the ratings service.

   > Note: If you previously ran the [request routing](./request-routing.html) task, you may need to either log out
     as test user "jason" or delete the test rules that were created exclusively for him:

   ```bash
   istioctl delete routerule reviews-test-v2
   ```

1. First, transfer 50% of the traffic from `reviews:v1` to `reviews:v3` with the following command:

   ```bash
   istioctl replace -f samples/bookinfo/kube/route-rule-reviews-50-v3.yaml
   ```

   Notice that we are using `istioctl replace` instead of `create`.

1. Refresh the `productpage` in your browser and you should now see *red* colored star ratings approximately 50% of the time.

   > Note: With the current Envoy sidecar implementation, you may need to refresh the `productpage` very many times
   > to see the proper distribution. It may require 15 refreshes or more before you see any change. You can modify the rules to route 90% of the traffic to v3 to see red stars more often.

1. When version v3 of the `reviews` microservice is considered stable, we can route 100% of the traffic to `reviews:v3`:

   ```bash
   istioctl replace -f samples/bookinfo/kube/route-rule-reviews-v3.yaml
   ```

   You can now log into the `productpage` as any user and you should always see book reviews
   with *red* colored star ratings for each review.

## Understanding what happened

In this task we migrated traffic from an old to new version of the `reviews` service using Istio's
weighted routing feature. Note that this is very different than version migration using deployment features
of container orchestration platforms, which use instance scaling to manage the traffic.
With Istio, we can allow the two versions of the `reviews` service to scale up and down independently,
without affecting the traffic distribution between them.
For more about version routing with autoscaling, check out [Canary Deployments using Istio]({{home}}/blog/canary-deployments-using-istio.html).

## Cleanup

* Remove the application routing rules.

  ```bash
  istioctl delete -f samples/bookinfo/kube/route-rule-all-v1.yaml
  ```

* If you are not planning to explore any follow-on tasks, refer to the
  [BookInfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
  to shutdown the application.

## Further reading

* Learn more about [request routing]({{home}}/docs/concepts/traffic-management/rules-configuration.html).

---
title: Traffic Shifting
description: Shows you how to migrate traffic from an old to new version of a service.
weight: 25
aliases:
    - /docs/tasks/traffic-management/version-migration.html
---

> This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.6/docs/tasks/).

This task shows you how to gradually migrate traffic from an old to new version of a service.
With Istio, we can migrate the traffic in a gradual fashion by using a sequence of rules
with weights less than 100 to migrate traffic in steps, for example 10, 20, 30, ... 100%.
For simplicity this task will migrate the traffic from `reviews:v1` to `reviews:v3` in just
two steps: 50%, 100%.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).

* Deploy the [Bookinfo](/docs/guides/bookinfo/) sample application.

## Weight-based version routing

1.  Set the default version for all microservices to v1.

    ```command
    $ istioctl create -f samples/bookinfo/routing/route-rule-all-v1.yaml
    ```

1.  Confirm v1 is the active version of the `reviews` service by opening http://$GATEWAY_URL/productpage in your browser.

    You should see the Bookinfo application productpage displayed.
    Notice that the `productpage` is displayed with no rating stars since `reviews:v1` does not access the ratings service.

1.  First, transfer 50% of the traffic from `reviews:v1` to `reviews:v3` with the following command:

    ```command
    $ istioctl replace -f samples/bookinfo/routing/route-rule-reviews-50-v3.yaml
    ```

    Confirm the rule was replaced:

    ```command-output-as-yaml
        $ istioctl get virtualservice reviews -o yaml
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
                host: reviews
                subset: v1
              weight: 50
          - route:
            - destination:
                host: reviews
                subset: v3
              weight: 50
    ```

1.  Refresh the `productpage` in your browser and you should now see *red* colored star ratings approximately 50% of the time.

    > With the current Envoy sidecar implementation, you may need to refresh the `productpage` very many times
    > to see the proper distribution. It may require 15 refreshes or more before you see any change. You can modify the rules to route 90% of the traffic to v3 to see red stars more often.

1.  When version v3 of the `reviews` microservice is considered stable, we can route 100% of the traffic to `reviews:v3`:

    ```command
    $ istioctl replace -f samples/bookinfo/routing/route-rule-reviews-v3.yaml
    ```

    You can now log into the `productpage` as any user and you should always see book reviews
    with *red* colored star ratings for each review.

## Understanding what happened

In this task we migrated traffic from an old to new version of the `reviews` service using Istio's
weighted routing feature. Note that this is very different than version migration using deployment features
of container orchestration platforms, which use instance scaling to manage the traffic.
With Istio, we can allow the two versions of the `reviews` service to scale up and down independently,
without affecting the traffic distribution between them.
For more about version routing with autoscaling, check out [Canary Deployments using Istio](/blog/2017/0.1-canary/).

## Cleanup

*   Remove the application routing rules.

    ```command
    $ istioctl delete -f samples/bookinfo/routing/route-rule-all-v1.yaml
    ```

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/guides/bookinfo/#cleanup) instructions
  to shutdown the application.

## What's next

* Learn more about [request routing](/docs/concepts/traffic-management/request-routing/).

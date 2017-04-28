---
title: Rate Limiting
overview: This task shows you how to use Istio to dynamically limit the traffic to a service.
          
order: 40

bodyclass: docs
layout: docs
type: markdown
---

This task shows you how to use Istio to dynamically limit the traffic to a service.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/tasks/installing-istio.html).

* Deploy the [bookinfo](/docs/samples/bookinfo.html) sample application.

* Initialize the application version routing by either first doing the
  [request routing](/docs/tasks/request-routing.html) task or by running following
  commands:
  
  ```bash
  $ istioctl create -f route-rule-all-v1.yaml
  $ istioctl replace -f route-rule-reviews-v3.yaml
  ```

### Rate Limiting [WIP]

We will pretend that `ratings` is an external service for which we are paying
(like going to rotten tomatoes), so we will set a rate limit on the service
such that the load remains under the Free quota (5q/s).

1. Configure mixer with the rate limit:

   ```bash
   # (TODO) istioctl create -f mixer-rule-ratings-ratelimit.yaml
   kubectl apply -f ../../mixer-config-quota-bookinfo.yaml
   ```

2. Generate load on the `productpage` with the following command:

   ```bash
   while true; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done
   ```
   
   If you now refresh the `productpage` (http://$GATEWAY_URL/productpage)
   you'll see that while the load generator is running 
   (i.e., generating more than 5 req/s), we stop seeing stars.

## Understanding ...

Here's an interesting thing to know about the steps you just did.

## What's next
* Learn more about [this](...).
* See this [related task](...).




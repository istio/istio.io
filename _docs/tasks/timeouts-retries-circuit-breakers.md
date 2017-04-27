---
category: Tasks
title: Timeouts, Retries, and Circuit Breakers
overview: This task shows you how to setup timeouts, retries, and circuit breakers in Envoy using Istio.
            
order: 40

bodyclass: docs
layout: docs
type: markdown
---

This task shows you how to setup timeouts, retries, and circuit breakers in
Envoy using Istio.


## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/tasks/installing-istio.html).

* Deploy the [bookinfo](/docs/samples/bookinfo.html) sample application.

* Initialize the application version routing by running following command:
  
  ```bash
  $ istioctl create -f route-rule-all-v1.yaml
  ```

## Request timeouts

A timeout for http requests can be specified using the *httpReqTimeout* field of a routing rule.
By default, the timeout is 15 seconds, but in this task, we'll override the `reviews` service
timeout to 1 second.
To see its effect, however, we'll also introduce an artificial 2 second delay in calls
to the `ratings` service.
 
1. Route requests to v2 of the `reviews` service, i.e., a version that calls the `ratings` service

   ```bash
   $ cat <<EOF | istioctl replace
   type: route-rule
   name: reviews-default
   spec:
     destination: reviews.default.svc.cluster.local
     route:
     - tags:
         version: v2
   EOF
   ```

1. Add a 2 second delay to calls to the `ratings` service:

   ```bash
   $ cat <<EOF | istioctl replace
   type: route-rule
   name: ratings-default
   spec:
     destination: ratings.default.svc.cluster.local
     route:
     - tags:
         version: v1
     httpFault:
       delay:
         percent: 100
         fixedDelaySeconds: 2
   EOF
   ```

1. Open the Bookinfo URL (http://$GATEWAY_URL/productpage) in your browser

   You should see the bookinfo application working normally (with ratings stars),
   but there is a 2 second delay whenever you refresh the page.

1. Now add a 1 second request timeout for calls to the `reviews` service
   
   ```bash
   $ cat <<EOF | istioctl replace
   type: route-rule
   name: reviews-default
   spec:
     destination: reviews.default.svc.cluster.local
     route:
     - tags:
         version: v2
     httpReqTimeout:
       simpleTimeout:
         timeoutSeconds: 1
   EOF
   ```

1. Refresh the Bookinfo web page

   You should now see that it returns in 1 second (instead of 2), but the reviews are unavailable.

## Request retries

The *httpReqRetries* field can be used to control the number retries for a given http request.
The maximum number of attempts, or as many as possible within the time period
specified by *httpReqTimeout*, can be set as follows:

```yaml
destination: "ratings.default.svc.cluster.local"
route:
- tags:
    version: v1
httpReqRetries:
  simpleRetry:
    attempts: 3
```

## Circuit Breakers

The *circuitBreaker* field of a destination policy
can be used to set a circuit breaker for a particular microservice. 
A simple circuit breaker can be set based on a number of criteria such as connection and request limits.

For example, the following destination policy
sets a limit of 100 connections to "reviews" service version "v1" backends.

```yaml
destination: reviews.default.svc.cluster.local
tags:
  version: v2
circuitBreaker:
  simpleCb:
    maxConnections: 100
```

The complete set of simple circuit breaker fields can be found
[here](https://github.com/istio/api/blob/master/proxy/v1/config/cfg.md#circuitbreakersimplecircuitbreakerpolicy).

## Understanding ...

Here's an interesting thing to know about the steps you just did.


## What's next
* Learn more about [this](...).
* See this [related task](...).

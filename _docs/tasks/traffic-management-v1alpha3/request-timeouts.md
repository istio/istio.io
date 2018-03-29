---
title: Setting Request Timeouts
overview: This task shows you how to setup request timeouts in Envoy using Istio.
            
order: 28

layout: docs
type: markdown
---
{% include home.html %}

This task shows you how to setup request timeouts in Envoy using Istio.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).

* Deploy the [Bookinfo]({{home}}/docs/guides/bookinfo.html) sample application.

* Initialize the application version routing by running the following command:

  ```bash
  istioctl create -f samples/bookinfo/routing/route-rule-all-v1.yaml
  ```

## Request timeouts

A timeout for http requests can be specified using the *httpReqTimeout* field of a routing rule.
By default, the timeout is 15 seconds, but in this task we'll override the `reviews` service
timeout to 1 second.
To see its effect, however, we'll also introduce an artificial 2 second delay in calls
to the `ratings` service.
 
1. Route requests to v2 of the `reviews` service, i.e., a version that calls the `ratings` service

   ```bash
   cat <<EOF | istioctl replace -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: reviews
   spec:
     hosts:
       - reviews
     http:
     - route:
       - destination:
           name: reviews
           subset: v2
   EOF
   ```

1. Add a 2 second delay to calls to the `ratings` service:

   ```bash
   cat <<EOF | istioctl replace -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: ratings
   spec:
     hosts:
     - ratings
     http:
     - fault:
         delay:
           percent: 100
           fixedDelay: 2s
       route:
       - destination:
           name: ratings
           subset: v1
   EOF
   ```

1. Open the Bookinfo URL (http://$GATEWAY_URL/productpage) in your browser

   You should see the Bookinfo application working normally (with ratings stars displayed),
   but there is a 2 second delay whenever you refresh the page.

1. Now add a 1 second request timeout for calls to the `reviews` service
   
   ```bash
   cat <<EOF | istioctl replace -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: reviews
   spec:
     hosts:
       - reviews
     http:
     - route:
       - destination:
           name: reviews
           subset: v2
       timeout: 1s
   EOF
   ```

1. Refresh the Bookinfo web page

   You should now see that it returns in 1 second (instead of 2), but the reviews are unavailable.


## Understanding what happened

In this task, you used Istio to set the request timeout for calls to the `reviews`
microservice to 1 second (instead of the default 15 seconds). 
Since the `reviews` service subsequently calls the `ratings` service when handling requests,
you used Istio to inject a 2 second delay in calls to `ratings`, so that you would cause the
`reviews` service to take longer than 1 second to complete and consequently you could see the
timeout in action. 

You observed that the Bookinfo productpage (which calls the `reviews` service to populate the page),
instead of displaying reviews, displayed
the message: Sorry, product reviews are currently unavailable for this book.
This was the result of it receiving the timeout error from the `reviews` service.

If you check out the [fault injection task](./fault-injection.html), you'll find out that the `productpage`
microservice also has its own application-level timeout (3 seconds) for calls to the `reviews` microservice.
Notice that in this task we used an Istio route rule to set the timeout to 1 second.
Had you instead set the timeout to something greater than 3 seconds (e.g., 4 seconds) the timeout
would have had no effect since the more restrictive of the two will take precedence.
More details can be found [here]({{home}}/docs/concepts/traffic-management/handling-failures.html#faq).

One more thing to note about timeouts in Istio is that in addition to overriding them in route rules,
as you did in this task, they can also be overridden on a per-request basis if the application adds
an "x-envoy-upstream-rq-timeout-ms" header on outbound requests. In the header
the timeout is specified in millisecond (instead of second) units. 

## Cleanup

* Remove the application routing rules.

  ```bash
  istioctl delete -f samples/bookinfo/routing/route-rule-all-v1.yaml
  ```

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
  to shutdown the application.

## What's next

* Learn more about [failure handling]({{home}}/docs/concepts/traffic-management/handling-failures.html).

* Learn more about [routing rules]({{home}}/docs/concepts/traffic-management/rules-configuration.html).

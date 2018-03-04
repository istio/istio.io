---
title: Fault injection with istio
overview: Overview

order: 11

layout: docs
type: markdown
---
{% include home.html %}\n# Fault injection with Istio

In this learning module, we inject a fault, error 418 on the path from the _ratings_ microservice to the _reviews_ microservice.

1. Let's add a rule to inject a fault on requests to _reviews_, for our test user `jason`:
   ```bash
    istioctl create -f route-rule-reviews-fault-418.yaml
   ```
   
1. Let's access the webpage of the application, login as `jason` and see that now an error is displayed instead of the reviews.

1. Also, let's see the error 418 appear in the logs of the sidecar proxy of the `productpage`:
   ```bash
   kubectl logs -l app=productpage -c istio-proxy
   ```
   You should see something similar to:
   ```
   [2018-02-12T14:52:15.126Z] "GET /reviews/0 HTTP/1.1" 418 FI 0 18 0 - "-" "python-requests/2.18.4" "8410206d-d471-9816-9cd5-d3780edc5ab6" "reviews:9080" "-"
   ```
1. Let's logout, login as some other user, and see that other users are not effected by the fault.

1. Now let's remove the route rule, login as `jason` and see that everything works OK.
   ```bash
   istioctl delete -f route-rule-reviews-fault-418.yaml
   ```

1. Let's check another kind of fault injection - let's insert a delay of seven seconds on requests to _ratings_:
   ```bash
   istioctl create -f  ../../istio-*/samples/bookinfo/kube/route-rule-ratings-test-delay.yaml
   ```

1. We will see that now the message "Error fetching product reviews!" is displayed. It means that the application cannot handle the delay of seven seconds between _reviews_ and _ratings_. If we suspect that such delays may happen in production, we should handle the problem now, proactively, before it appears in production.

   Let's examine [the code of _reviews_](https://github.com/istio/istio/blob/master/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java) that calls _ratings_:

   ```java
   String timeout = star_color.equals("black") ? "10000" : "2500";
   cb.property("com.ibm.ws.jaxrs.client.connection.timeout", timeout);
   cb.property("com.ibm.ws.jaxrs.client.receive.timeout", timeout);
   ```

   We can see that the code sets the timeout as 10 seconds, so it should absorb the delay of seven seconds.

   Let's go up the call chain and check the delay between _productpage_ and _reviews_. Let's examime [the code of _productpage_](https://github.com/istio/istio/blob/master/samples/bookinfo/src/productpage/productpage.py):

   ```python
   def getProductReviews(product_id, headers):
   ...
       res = requests.get(url, headers=headers, timeout=3.0)
   ```

   As we can see, the timeout is too low (three seconds), it cannot accommodate the delays of seven seconds. We must increase it. Also note that we can remove the timeouts from the code to make it cleaner, and [handle the timeouts by Istio route rules](https://istio.io/docs/tasks/traffic-management/request-timeouts.html).

1. Let's set the delay to two seconds and see that the current application can handle it:
   ```bash
   istioctl replace -f <(cat ../../istio-*/samples/bookinfo/kube/route-rule-ratings-test-delay.yaml | sed 's/7s/2s/g')
   ```

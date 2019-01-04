---
title: Fault injection with Istio
overview: Inject an HTTP error and a delay to test our microservices in production.

weight: 11

---

In this module we will perform _fault injection_ on our application. We know that in real life our microservices will fail, we cannot prevent all possible failures. What we can do is to verify that our microservices react to failures in a best possible way. We definitely want to prevent _cascading failures_: a situation when a failure in one microservice causes chain of failures in other microservices.

To verify that our microservices behave well under failures, first we inject a fault, an HTTP error on the path from one microservice to another. Next, we introduce a delay on a path between two microservices. We inspect how our microservices react to the faults we injected.

1. Let's add a rule to inject a fault on requests to _ratings_, for our test user `jason`:
   ```bash
    istioctl create -f samples/bookinfo/kube/route-rule-ratings-test-abort.yaml
   ```

1. Let's access the webpage of the application, login as `jason` and observe that now an error is displayed instead of the reviews.

1. Also, let's see that the error appears in the logs of the sidecar proxy of the `productpage`:
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
   istioctl delete -f samples/bookinfo/kube/route-rule-ratings-test-abort.yaml
   ```

1. Let's check another kind of fault injection - let's insert a delay of seven seconds on requests to _ratings_:
   ```bash
   istioctl create -f  samples/bookinfo/kube/route-rule-ratings-test-delay.yaml
   ```

1. We will see that now the message "Error fetching product reviews!" is displayed. It means that the application cannot handle the delay of seven seconds between _reviews_ and _ratings_. If we suspect that such delays may happen in production, we should handle the problem now, proactively, before it appears in production.

   Let's examine [_reviews_'s code](https://github.com/istio/istio/blob/master/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java) that calls _ratings_:

   ```java
   String timeout = star_color.equals("black") ? "10000" : "2500";
   cb.property("com.ibm.ws.jaxrs.client.connection.timeout", timeout);
   cb.property("com.ibm.ws.jaxrs.client.receive.timeout", timeout);
   ```

   We can see that the code sets the timeout as 10 seconds, so it should absorb the delay of seven seconds.

   Let's go up the call chain and check the delay between _productpage_ and _reviews_. Let's examime [_productpage_'s code](https://github.com/istio/istio/blob/master/samples/bookinfo/src/productpage/productpage.py):

   ```python
   def getProductReviews(product_id, headers):
   ...
       res = requests.get(url, headers=headers, timeout=3.0)
   ```

   As we can see, the timeout is too low (three seconds), it cannot accommodate the delays of seven seconds. We must increase it. Also note that we can remove the timeouts from the code to make it cleaner, and [handle the timeouts with Istio route rules]({{home}}/docs/tasks/traffic-management/request-timeouts.html).

1. Let's set the delay to two seconds and see that the current application can handle it:
   ```bash
   istioctl replace -f <(cat samples/bookinfo/kube/route-rule-ratings-test-delay.yaml | sed 's/7s/2s/g')
   ```


---
title: Traffic shadowing with Istio
overview: Shadow the traffic to the new version of a microservice

order: 09

layout: docs
type: markdown
---
{% include home.html %}

In this step, we will perform traffic shadowing. We will shadow the traffic destined to _reviews v1_ to _reviews v2_ and see if our new version provides incorrect results or produces any errors.

1. Let's add a route rule to route traffic to _reviews v1_, while shadowing traffic to _reviews 2_ (using the [route rule _mirror_ attribute]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#RouteRule)):
   ```bash
   istioctl create -f samples/bookinfo/istio.io-tutorial/route-rule-reviews-shadow-v2.yaml
   ```

2. Let's access the webpage of the application a couple of times. We'll see that the review stars are not displayed, it means that _reviews v1_ is called as previously. Let's examine the logs of the sidecar proxy of _reviews v2_:
   ```bash
   kubectl logs -l app=reviews,version=v2 -c istio-proxy
   ```
   The expected output is:
   ```bash
   [2018-02-12T12:41:15.428Z] "GET /ratings/0 HTTP/1.1" 200 - 0 48 23 22 "-" "Apache-CXF/3.1.14" "3a17f766-1077-99ab-bb8a-5b3808642ff2" "ratings:9080" "172.30.174.69:9080"
   [2018-02-12T12:41:15.228Z] "GET /reviews/0 HTTP/1.1" 200 - 0 379 240 223 "172.30.30.8" "python-requests/2.18.4" "3a17f766-1077-99ab-bb8a-5b3808642ff2" "reviews:9080-shadow" "127.0.0.1:9080"
   ```

   It means that our _reviews v2_ received the shadow traffic and did not crash. Then we would check the microservice logs of _reviews v1_ and _reviews v2_ and would compare the results.

3. Let's remove the rule:
   ```bash
   istioctl delete -f samples/bookinfo/istio.io-tutorial/route-rule-reviews-shadow-v2.yaml
   ```

{% include what-is-next-footer.md %}

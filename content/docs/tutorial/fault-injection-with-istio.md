---
title: Fault injection with Istio
overview: Inject an HTTP error and a delay to test our microservices in production.

weight: 110

---

In this module you will perform _fault injection_ on our application. you know that in real life our microservices will fail, you cannot prevent all possible failures. What you can do is to verify that our microservices react to failures in a best possible way. you definitely want to prevent _cascading failures_: a situation when a failure in one microservice causes chain of failures in other microservices.

To verify that our microservices behave well under failures, first you inject a fault, an HTTP error on the path from one microservice to another. Next, you introduce a delay on a path between two microservices. you inspect how our microservices react to the faults you injected.

1.  Configure a virtual service to inject a fault on requests to _ratings_, for our test user `jason`:

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml
    {{< /text >}}

1.  Access application's webpage, sign in as `jason` and observe that now an error is displayed instead of the reviews.

1.  See that the error appears in the logs of the sidecar proxy of the `reviews` microservice which calls
    _ratings_:

    {{< text bash >}}
    $ kubectl logs -l app=reviews -c istio-proxy
    {{< /text >}}

    You should see something similar to:

    {{< text plain >}}
    [2019-02-17T03:25:41.941Z] "GET /ratings/0 HTTP/1.1" 500 FI 0 18 0 - "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "2d0740d7-64e7-9c83-ae49-67be45457b1a" "ratings:9080" "-" - - 172.21.175.188:9080 172.30.146.72:46062 -
    [2019-02-17T03:25:41.929Z] "GET /reviews/0 HTTP/1.1" 200 - 0 425 18 17 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "2d0740d7-64e7-9c83-ae49-67be45457b1a" "reviews:9080" "127.0.0.1:9080" inbound|9080|http|reviews.tutorial.svc.cluster.local - 172.30.146.72:9080 172.30.109.78:37748 outbound_.9080_.v3_.reviews.tutorial.svc.cluster.local
    {{< /text >}}

    According to the log messages above, a call to _ratings_ returned `500` while _reviews_ managed to handle the error
    and returned `200`. You did get _cascading failire_, a failing microservice or a network error did not cause the
    whole chain of calls to fail. The application continued to function, but with reduced functionality, just not
    presenting ratings stars. You experience _graceful degradation_ which is good.

1.  Sign out, sign in as some other user, and see that other users are not effected by the fault.

1.  Remove the virtual service, sign in as `jason` and see that everything works OK.

    {{< text bash >}}
    $ kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml
    {{< /text >}}

1.  Check another kind of fault injection. Insert a delay of seven seconds on requests to _ratings_:

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
    {{< /text >}}

1.  Access the application's webpage and sign in as `jason`.
    You should see that now the message "Error fetching product reviews!" is displayed.
    It means that the application cannot handle the delay of seven seconds between _reviews_ and _ratings_.
    If you suspect that such delays may happen in production, you should handle the problem now, proactively,
    before it appears in production.

1.  Check the logs of _productpage_ and see that the delay from _ratings_ propagated through _reviews_ to _productpage_!
    That's not good.

    {{< text bash >}}
    $ kubectl logs -l app=productpage -c istio-proxy
    {{< /text >}}

    You should see something similar to:

    {{< text plain >}}
    [2019-02-17T03:55:50.384Z] "GET /reviews/0 HTTP/1.1" 500 - 0 3965 2824 2824 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "8acc1b91-e238-9ec3-ab04-32317110c27d" "reviews:9080" "172.30.146.72:9080" outbound|9080|v3|reviews.tutorial.svc.cluster.local - 172.21.5.201:9080 172.30.109.78:48222 -
    [2019-02-17T03:55:47.367Z] "GET /productpage HTTP/1.1" 200 - 0 4209 5843 5843 "10.127.220.66" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "8acc1b91-e238-9ec3-ab04-32317110c27d" "tutorial.bookinfo.com" "127.0.0.1:9080" inbound|9080|http|productpage.tutorial.svc.cluster.local - 172.30.109.78:9080 10.127.220.66:0 -
    {{< /text >}}

1.  Access the Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard), _Istio Service Dashboard_, the _reviews_ service.

    Notice the response code `500` in _Service Workloads_, _Incoming requests by destination and response code_.

    {{< image width="80%"
        link="images/dashboard-reviews-500.png"
        caption="Istio Service Dashboard"
        >}}

1.   Examine [_reviews_'s code](https://github.com/istio/istio/blob/master/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java#L88) that calls _ratings_:

    {{< text java >}}
    String timeout = star_color.equals("black") ? "10000" : "2500";
    cb.property("com.ibm.ws.jaxrs.client.connection.timeout", timeout);
    cb.property("com.ibm.ws.jaxrs.client.receive.timeout", timeout);
    {{< /text >}}

    You can see that the code sets the timeout as 10 seconds, so it should absorb the delay of seven seconds.

    Go up the call chain and check the delay between _productpage_ and _reviews_.
    Examine
    [_productpage_'s code](https://github.com/istio/istio/blob/master/samples/bookinfo/src/productpage/productpage.py#L296):

    {{< text python >}}
    def getProductReviews(product_id, headers):
    ...
        res = requests.get(url, headers=headers, timeout=3.0)
    {{< /text >}}

    As you can see, the timeout is too low (three seconds), it cannot accommodate the delays of seven seconds.
    You must increase it. Also note that you can remove the timeouts from the code to make it cleaner, and
    [handle the timeouts by Istio virtual services](/docs/tasks/traffic-management/request-timeouts).

1.  Set the delay to two seconds and see that the current application can handle it:

    {{< text bash >}}
    $ curl -s https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml | sed 's/7s/2s/g' | kubectl apply -f -
    {{< /text >}}

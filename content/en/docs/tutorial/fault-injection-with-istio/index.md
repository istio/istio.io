---
title: Fault injection with Istio
overview: Inject an HTTP error and a delay to test your microservices in production.

weight: 110

---

In this module you [inject faults](https://en.wikipedia.org/wiki/Fault_injection) in your application.
You know that in real life your microservices will fail, you cannot prevent all possible failures.
What you can do is verify that your microservices react to failures in a best possible way.
You definitely want to prevent [cascading failures](https://en.wikipedia.org/wiki/Cascading_failure): a situation when a
failure in one microservice causes chain of failures in other microservices.

In this module, to verify that your microservices behave well under failures, first you inject a fault, an HTTP error on the path from
one microservice to another. Next, you introduce a delay on a path between two microservices. You inspect how your
microservices react to the faults you injected.

1.  Configure a virtual service to inject a fault on requests to `ratings`, for your test user `jason`:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml
    {{< /text >}}

1.  Access application's webpage, sign in as `jason` and observe that now an error is displayed instead of the reviews.

    {{< image width="80%"
        link="bookinfo-ratings-unavailable-jason.png"
        caption="Bookinfo Web Application, ratings unavailable for a test user"
        >}}

1.  Check that the error appears in the logs of the sidecar proxy of the `reviews` microservice which calls
    `ratings`:

    {{< text bash >}}
    $ kubectl logs -l app=reviews -c istio-proxy
    {{< /text >}}

    You should see something similar to:

    {{< text plain >}}
    [2019-02-17T03:25:41.941Z] "GET /ratings/0 HTTP/1.1" 500 FI 0 18 0 - "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "2d0740d7-64e7-9c83-ae49-67be45457b1a" "ratings:9080" "-" - - 172.21.175.188:9080 172.30.146.72:46062 -
    [2019-02-17T03:25:41.929Z] "GET /reviews/0 HTTP/1.1" 200 - 0 425 18 17 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "2d0740d7-64e7-9c83-ae49-67be45457b1a" "reviews:9080" "127.0.0.1:9080" inbound|9080|http|reviews.tutorial.svc.cluster.local - 172.30.146.72:9080 172.30.109.78:37748 outbound_.9080_.v3_.reviews.tutorial.svc.cluster.local
    {{< /text >}}

    According to the log messages above, a call to `ratings` returned `500` while `reviews` managed to handle the error
    and returned `200`. You didn't get _cascading failire_, a failing microservice or a network error did not cause the
    whole chain of calls to fail. The application continued to function, but with reduced functionality, just not
    presenting ratings stars. You experience _graceful degradation_, which is good.

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Note that the `reviews` microservice became orange and the edges to `ratings` became red.

    {{< image width="80%"
        link="kiali-fault-injection.png"
        caption="Kiali Graph Tab with fault injection"
        >}}

1.  Sign out, sign in as some other user, and see that other users are not effected by the fault.

1.  Remove the virtual service, sign in as `jason` and see that everything works OK.

    {{< text bash >}}
    $ kubectl delete -f {{< github_file >}}/samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml
    {{< /text >}}

1.  Check another kind of fault injection. Insert a delay of seven seconds on requests to `ratings`:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
    {{< /text >}}

1.  Access the application's webpage and sign in as `jason`.
    You should see that now the "Error fetching product reviews!" message is displayed.

    {{< image width="80%"
        link="bookinfo-reviews-unavailable-jason.png"
        caption="Bookinfo Web Application, reviews unavailable for a test user"
        >}}

    It means that the application cannot handle the delay of seven seconds between `reviews` and `ratings`.
    If you suspect that such delays may happen in production, you should handle the problem now, proactively,
    before it appears in production.

1.  Check the logs of `productpage` and see that the delay from `ratings` propagated through `reviews` to `productpage`!
    That's not good.

    {{< text bash >}}
    $ kubectl logs -l app=productpage -c istio-proxy
    {{< /text >}}

    You should see something similar to:

    {{< text plain >}}
    [2019-06-02T02:19:26.742Z] "GET /reviews/0 HTTP/1.1" 0 DC "-" 0 0 3003 - "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.1 Safari/605.1.15" "0c33b868-b724-96d7-9113-501b1bf0513c" "reviews:9080" "172.30.230.14:9080" outbound|9080|v2|reviews.tutorial.svc.cluster.local - 172.21.35.212:9080 172.30.109.86:50506 -
    [2019-06-02T02:19:23.726Z] "GET /productpage HTTP/1.1" 200 - "-" 0 4209 6020 6020 "10.127.220.66" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.1 Safari/605.1.15" "0c33b868-b724-96d7-9113-501b1bf0513c" "istio.tutorial.bookinfo.com" "127.0.0.1:9080" inbound|9080|http|productpage.tutorial.svc.cluster.local - 172.30.109.86:9080 10.127.220.66:0 outbound_.9080_._.productpage.tutorial.svc.cluster.local
    {{< /text >}}

    Notice the `0` response code in the call to `/reviews/0`, appears after `GET /reviews/0 HTTP/1.1`, and Envoy's
    response flag `DC` (`Downstream connection termination`) appears next to it.

1.  Check your Kiali console,
        [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    This time the situation is more serious. Both the `reviews` and the `productpage` microservices
    turned orange.

    {{< image width="80%"
        link="kiali-delay-injection.png"
        caption="Kiali Graph Tab with delay injection"
    >}}

1.  Access the Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard), _Istio Service Dashboard_, the `reviews` service.

    Notice the response code `500` in _Service Workloads_, _Incoming requests by destination and response code_.

    {{< image width="80%"
        link="dashboard-reviews-500.png"
        caption="Istio Service Dashboard"
        >}}

1.   Examine [`reviews`'s code]({{< github_blob >}}/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java) that calls `ratings`:

    {{< text java >}}
    String timeout = star_color.equals("black") ? "10000" : "2500";
    cb.property("com.ibm.ws.jaxrs.client.connection.timeout", timeout);
    cb.property("com.ibm.ws.jaxrs.client.receive.timeout", timeout);
    {{< /text >}}

    You can see that the code sets the timeout as 10 seconds for the version with black stars,
    so it should absorb the delay of seven seconds for that version. For the version with red stars the timeout is 2.5
    seconds, exactly the latency you see in the tracing system. In real life you would increase the timeout for the
    version with red stars.

    Go up the call chain and check the delay between `productpage` and `reviews`.
    Examine
    [`productpage`'s code]({{< github_blob >}}/samples/bookinfo/src/productpage/productpage.py):

    {{< text python >}}
    def getProductReviews(product_id, headers):
    ...
        res = requests.get(url, headers=headers, timeout=3.0)
    {{< /text >}}

    As you can see, the timeout is too low (three seconds), it cannot accommodate the delays of seven seconds, even if
    `reviews` could accommodate it. In real life you would increase this timeout.
    Also note that you can remove the timeouts from the code to make it cleaner, and
    [handle the timeouts by Istio virtual services](/docs/tasks/traffic-management/request-timeouts).

1.  Set the delay to two seconds and see that the current application can handle it:

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml | sed 's/7s/2s/g' | kubectl apply -f -
    {{< /text >}}

1.  Access the application's webpage signed in as `jason`. You can see that while there is some delay, there are no
    errors anymore.

1.  Clean the fault injection:

    {{< text bash >}}
    $ kubectl delete virtualservice ratings
    {{< /text >}}

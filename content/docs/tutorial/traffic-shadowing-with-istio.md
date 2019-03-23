---
title: Traffic shadowing with Istio
overview: Shadow the traffic to the new version of a microservice.

weight: 90

---

The next step in deploying a new version of a microservice is to perform [traffic shadowing](https://blog.christianposta.com/microservices/advanced-traffic-shadowing-patterns-for-microservices-with-istio-service-mesh/). You will shadow the
traffic destined to _reviews_ to _reviews v3_ and verify that your new version provides correct results without errors.

1.  Add a virtual service to route traffic to _reviews v2_, while shadowing traffic to _reviews 2_
    (using the
      [HTTP route _mirror_ attribute](http://localhost:1313/docs/reference/config/istio.networking.v1alpha3/#HTTPRoute)):

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
            host: reviews
            subset: v2
        mirror:
          host: reviews
          subset: v3
    EOF
    {{< /text >}}

1.  Access the webpage of the application a couple of times. You'll see that the black ratings stars are displayed
    which means that _reviews v2_ are called as previously.
    Examine the logs of the sidecar proxy of _reviews v3_:

    {{< text bash >}}
    $ kubectl logs -l app=reviews,version=v3 -c istio-proxy
    {{< /text >}}

    The expected output is:

    {{< text plain >}}
    [2019-02-16T09:30:14.205Z] "GET /ratings/0 HTTP/1.1" 200 - 0 48 2 2 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "3ad5ec07-0d68-9b96-8dae-1723a45b4cd6" "ratings:9080" "172.30.109.94:9080" outbound|9080||ratings.tutorial.svc.cluster.local - 172.21.27.97:9080 172.30.230.54:53090 -
    [2019-02-16T09:30:14.192Z] "GET /reviews/0 HTTP/1.1" 200 - 0 375 17 17 "172.30.146.98" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "3ad5ec07-0d68-9b96-8dae-1723a45b4cd6" "reviews-shadow:9080" "127.0.0.1:9080" inbound|9080|http|reviews.tutorial.svc.cluster.local - 172.30.230.54:9080 172.30.146.98:0 outbound_.9080_.v3_.reviews.tutorial.svc.cluster.local
    {{< /text >}}

    It means that your _reviews v3_ received the shadow traffic and did not crash. In real life you may also want to
    compare the data returned by invocation of a production version and a mirrored version.

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    This time you will see that _reviews v3_ does not receive the traffic from _`productpage`_, since it receives only
    shadow traffic. As a response to the shadow traffic, _reviews v3_ generates traffic to _ratings_, which is shown in
    the graph.

    {{< image width="80%"
        link="images/kiali-traffic-shadowing.png"
        caption="Kiali Graph Tab with traffic shadowing to reviews v3"
        >}}

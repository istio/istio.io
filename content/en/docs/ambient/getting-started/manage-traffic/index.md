## Control traffic {#control}

1. You can use the same waypoint to control traffic to `reviews`. Configure traffic routing to send 90% of requests to `reviews` v1 and 10% to `reviews` v2:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-90-10.yaml@
    {{< /text >}}

1. Confirm that roughly 10% of the traffic from 100 requests goes to reviews-v2:

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"
    {{< /text >}}
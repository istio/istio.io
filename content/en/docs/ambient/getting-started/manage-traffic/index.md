---
title: Manage traffic
description: Manage traffic between services in the ambient mode.
weight: 5
owner: istio/wg-networking-maintainers
test: yes
---

Now we have a waypoint proxy installed, we will learn how to split traffic between services.

## Split traffic between services

The Bookinfo application has three versions of the `reviews` service. You can split traffic between these versions to test new features or perform A/B testing.

Let's configure traffic routing to send 90% of requests to `reviews` v1 and 10% to `reviews` v2:

{{< text syntax=bash snip_id=deploy_httproute >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
EOF
{{< /text >}}

To confirm that roughly 10% of the of the traffic from 100 requests goes to `reviews-v2`, you can run the following command:

{{< text syntax=bash snip_id=test_traffic_split >}}
$ kubectl exec deploy/curl -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"
{{< /text >}}

You'll notice the majority of requests go to `reviews-v1`. You can confirm the same if you open the Bookinfo application in your browser and refresh the page multiple times. Notice the requests from the `reviews-v1` don't have any stars, while the requests from `reviews-v2` have black stars.

## Next steps

This section concludes the Getting Started guide for ambient mode. You can continue to the [Cleanup](/docs/ambient/getting-started/cleanup) section to remove Istio or continue exploring the [ambient mode user guides](/docs/ambient/usage/) to learn more about Istio's features and capabilities.

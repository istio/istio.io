---
title: Phased rollout with Istio
overview: Incrementally direct live traffic to the new version of a microservice.

weight: 100

---

In this module, we will start phased rollout of _reviews v2_. After performing unit tests, integration tests, end-to-end tests, tests in the staging environment, and finally canary deployment and traffic shadowing, we are pretty confident. Now we can start directing live traffic from the real users. We will perform it gradually, first to 10% of the users, then to 20% and so on.

1. Let's add a route rule to distribute the traffic 90:10 between _reviews v1_ and _reviews v2_:
   {{< text bash >}}
   istioctl create -f samples/bookinfo/istio.io-tutorial/route-rule-reviews-90-10.yaml
   {{< /text >}}

2. Let's call reviews 20 times and see that _reviews v2_ is called, part of the times:
   {{< text bash >}}
   kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') bash
   for i in {1..20}; do echo perform request $i; curl -s http://reviews:9080/reviews/0 | grep -l star; done
   {{< /text >}}

   We will see output similar to:
   {{< text bash >}}
   perform request 1
   perform request 2
   perform request 3
   perform request 4
   perform request 5
   (standard input)
   perform request 6
   (standard input)
   perform request 7
   perform request 8
   perform request 9
   perform request 10
   perform request 11
   perform request 12
   perform request 13
   perform request 14
   perform request 15
   (standard input)
   perform request 16
   (standard input)
   perform request 17
   perform request 18
   perform request 19
   (standard input)
   perform request 20
   {{< /text >}}
   In the cases _reviews v2_ is called, the `(standard output)` string is printed. Note that the percentage of requests sent to _reviews v2_ is about 10%.

2. Let's increase the rollout of _reviews v2_, this time to 20%:
   {{< text bash >}}
   istioctl delete -f samples/bookinfo/istio.io-tutorial/route-rule-reviews-90-10.yaml
   istioctl create -f samples/bookinfo/istio.io-tutorial/route-rule-reviews-80-20.yaml
   {{< /text >}}

3. Let's send multiple requests again and see that the number of requests sent to _reviews v2_ was increased.

4. Finally, let's direct all the traffic to _reviews v2_.
   {{< text bash >}}
   istioctl delete -f samples/bookinfo/istio.io-tutorial/route-rule-reviews-80-20.yaml
   istioctl create -f samples/bookinfo/kube/route-rule-reviews-v2.yaml
   {{< /text >}}
3. Let's check that no more requests were sent to _reviews v1_:
   {{< text bash >}}
   kubectl logs -l app=reviews,version=v1 -c istio-proxy
   {{< /text >}}

4. We examined the logs and saw that no more requests to _reviews v1_ arrived (in reality we would take a while to be sure). Now we can safely decommission _reviews v1_:
   {{< text bash >}}
   kubectl delete deployment reviews-v1
   {{< /text >}}

5. Let's remove the route rules for _reviews_, since they are not relevant anymore:
   {{< text bash >}}
   istioctl delete routerule reviews-default reviews-v2 -n default
   {{< /text >}}

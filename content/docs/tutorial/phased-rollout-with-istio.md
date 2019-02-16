---
title: Phased rollout with Istio
overview: Incrementally direct live traffic to the new version of a microservice.

weight: 100

---

In this module, you perform phased rollout of _reviews v3_. After performing unit tests, integration tests,
end-to-end tests, tests in the staging environment, and finally canary deployment and traffic shadowing,
you are pretty confident.
Now you can start directing live traffic from the real users. you will perform it gradually, first to 10% of the users,
then to 20% and so on.

1.  Configure a virtual service to distribute the traffic 90:10 between _reviews v2_ and _reviews v3_:

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
          weight: 90
        - destination:
            host: reviews
            subset: v3
          weight: 10
    EOF
    {{< /text >}}

1.  Call reviews 20 times and see that _reviews v3_ is called, part of the times.

    Get a shell to the testing pod:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep sh
    {{< /text >}}

    Run the following command in the shell of the testing pod:

    {{< text bash >}}
    $ for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do echo -n "perform request $i : "; curl -s http://reviews:9080/reviews/0 | sed -n 's/^.*color": "\(.*\)".*/\1\n/p'; done
    {{< /text >}}

    you will see output similar to:

    {{< text plain >}}
    perform request 1 : black
    perform request 2 : red
    perform request 3 : black
    perform request 4 : black
    perform request 5 : black
    perform request 6 : black
    perform request 7 : black
    perform request 8 : black
    perform request 9 : black
    perform request 10 : black
    perform request 11 : black
    perform request 12 : black
    perform request 13 : red
    perform request 14 : black
    perform request 15 : black
    perform request 16 : black
    perform request 17 : black
    perform request 18 : black
    perform request 19 : black
    perform request 20 : black
    {{< /text >}}

    In the cases _reviews v2_ is called, the `(standard output)` string is printed. Note that the percentage of
    requests sent to _reviews v2_ is about 10%.

1.  Increase the rollout of _reviews v2_, this time to 20%:

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
          weight: 80
        - destination:
            host: reviews
            subset: v3
          weight: 20
    EOF
    {{< /text >}}

1.  Send multiple requests again and see that the number of requests sent to _reviews v2_ was increased.

1.  **Exercise**: direct 70% of the traffic to _reviews v2_.

1.  Finally, direct all the traffic to _reviews v2_.

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/networking/virtual-service-reviews-v3.yaml
    {{< /text >}}

1.  Let's check that no more requests were sent to _reviews v2_:

    {{< text bash >}}
    $ kubectl logs -l app=reviews,version=v2 -c istio-proxy
    {{< /text >}}

1.  You examined the logs and saw that no more requests to _reviews v2_ arrived
    (in real life you would take a while to be sure). Now you can safely decommission _reviews v2_:

    {{< text bash >}}
    $ kubectl delete deployment reviews-v2
    {{< /text >}}

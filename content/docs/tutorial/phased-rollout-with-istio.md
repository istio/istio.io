---
title: Phased rollout with Istio
overview: Incrementally direct live traffic to the new version of a microservice.

weight: 100

---

In this module, you perform phased rollout of _reviews v3_. After performing unit tests, integration tests,
end-to-end tests, tests in the staging environment, and finally canary deployment and traffic shadowing,
you are pretty confident.
Now you can start directing live traffic from the real users. You perform it gradually, first to 10% of the users,
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

1.  Check the distribution of the requests in your log database,
    at [http://my-istio-logs-database.io](http://my-istio-logs-database.io).

    Execute the following query:

    {{< text plain >}}
    istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews"}
    {{< /text >}}

    Observe the _Value_ column, the counters of the calls to reviews _v2_ and reviews _v3_.

1.  Execute the following queries:

    1.  Number of requests from _sleep_ to _reviews v2_:

        {{< text plain >}}
        sum(istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews", destination_version="v2"})
        {{< /text >}}

    1.  Number of requests from _sleep_ to _reviews v3_:

        {{< text plain >}}
        sum(istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews", destination_version="v3"})
        {{< /text >}}

    1.  You can even perform math on the results of queries above:

        {{< text plain >}}
        sum(istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews", destination_version="v2"}) + sum(istio_requests_total{destination_service_namespace="tutorial", reporter="destination",destination_service_name="reviews", destination_version="v3"})
        {{< /text >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    You will see the rate of the traffic entering `reviews` split roughly 90:10 between `reviews` _v2_ and _v3_.

    {{< image width="80%"
        link="images/kiali-phased-rollout.png"
        caption="Kiali Graph Tab with traffic splitting 90:10 between reviews v2 and v3"
        >}}

1.  Observe the `reviews` virtual service in your Kiali console, the `Istio Config` tab.

    {{< image width="80%"
        link="images/kiali-phased-rollout-virtual-service.png"
        caption="Kiali, the reviews virtual service"
        >}}

1.  Note that you can edit the virtual service in Kiali. Go to the `YAML` tab and change the weight of _reviews v2_ to
    80 without changing the weight of _reviews v3_.
    Try to save and see that you get an error in the top right corner. The error is that the sum of the weights to
    `reviews` is not equal to 100: 80 to _v2_ and 10 to _v3_. Istio validates the configuration items you submit. Good.

    {{< image width="80%"
        link="images/kiali-edit-virtual-service-error.png"
        caption="Kiali, editing the reviews virtual service with error"
        >}}

1.  Edit the virtual service in Kiali, this time setting the weights correctly, 80:20.

1.  Observe the traffic rates and verify that they are roughly 80:20, as expected.

1.  You can also edit the virtual service directly, using `kubectl edit` command.
    Direct 70% of the traffic to _reviews v3_.

    {{< text bash >}}
    $ kubectl edit virtualservice reviews
    {{< /text >}}

1.  Finally, direct all the traffic to _reviews v3_.

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/virtual-service-reviews-v3.yaml
    {{< /text >}}

1.  Observe in the Kiali console, the graph of your namespace, how the traffic switches from _v2_ to _v3_.

1.  Check that no more requests were sent to _reviews v2_:

    {{< text bash >}}
    $ kubectl logs -l app=reviews,version=v2 -c istio-proxy
    {{< /text >}}

1.  You examined the logs and saw that no more requests to _reviews v2_ arrived
    (in real life you would wait a while to be sure). Now you can safely decommission _reviews v2_:

    {{< text bash >}}
    $ kubectl delete deployment reviews-v2
    {{< /text >}}

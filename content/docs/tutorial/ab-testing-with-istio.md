---
title: A/B testing with Istio
overview: Deploy two different versions of a microservice and split the traffic between them.

weight: 101

---

In the previous module you deployed a new version of the _reviews_ microservice, _v3_. This version returns ratings as
red stars, as opposed to the black stars of _reviews v2_.

While you performed a successful rollout of the new version, how can you be sure that the new version is actually
better than the previous one?
You may want to perform _A/B_ testing: to run two versions of the _reviews_ microservice, _v2_ and _v3_, splitting the
requests 50:50. Then you will measure by various metrics which version is accepted better by the users.
(Measuring business metrics is out of scope of Istio). In this module you redeploy _reviews v2_ and configure Istio
to split the traffic destined to _reviews_ equally between the _v2_ and _v3_ versions.

1.  Deploy _reviews v2_:

    {{< text bash >}}
    $ kubectl apply -l app=reviews,version=v2 -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo.yaml
    deployment "reviews-v2" created
    {{< /text >}}

1.  Configure a virtual service to distribute the traffic 50:50 between _reviews v2_ and _reviews v3_.

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/networking/virtual-service-reviews-v2-v3.yaml
    {{< /text >}}

1.  Access application's webpage and verify that now the red stars are displayed roughly every other access.

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    You will see the rate of the traffic entering _reviews_ split roughly 50:50 between _reviews_ _v2_ and _v3_.

    {{< image width="80%"
        link="images/kiali-ab-testing.png"
        caption="Kiali Graph Tab with traffic splitting 50:50 between reviews v2 and v3"
        >}}

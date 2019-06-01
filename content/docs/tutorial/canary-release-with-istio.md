---
title: Canary release with Istio
overview: Enable a new version of a microservice for a tester, in production.

weight: 80

---

In this module you deploy a new version of the `reviews` microservice, _v3_. This version displays ratings as red stars
(_v2_ displays ratings as black stars). In this and a couple of next modules, you will learn how deploying a new
version of a microservice can be made simple, effective and safe with Istio.

First, you want your new version to be accessible to testers only and not to the real clients. In this module you deploy
a new version and enable traffic to it for a tester with login name `jason`.

1.  Create a virtual service to limit the traffic to the `reviews` microservice to the _v2_ version:

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
    EOF
    {{< /text >}}

1.  Access your application's webpage and verify that it works as previously, in particular you see reviews as black
    stars.

1.  Deploy a new version of the `reviews` microservice, _v3_.
    Note that you are safe to deploy it: no traffic will arrive to your new version of the `reviews` microservice
    thanks to the virtual service you defined in the previous step.

    {{< text bash >}}
    $ kubectl apply -l app=reviews,version=v3 -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
    deployment "reviews-v3" created
    {{< /text >}}

1.  Check the pods of `reviews`. Note that you have two pods, a pod for each of the different versions,
    and each of the pods has two containers (an Istio sidecar was injected automatically in the `reviews v3`).

    {{< text bash >}}
    $ kubectl get pods -l app=reviews
    NAME                          READY     STATUS    RESTARTS   AGE
    reviews-v2-dfbcf859c-27dvk    2/2       Running   0          4h
    reviews-v3-6cf47594fd-gnsxj   2/2       Running   0          2m
    {{< /text >}}

1.  Access the application's web page multiple times and verify that your new version is not called, that is you
    do not see red stars as ratings.

1.  Create an Istio virtual service to allow the `jason` user to access your new version for testing:

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
      - match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: reviews
            subset: v3
      - route:
        - destination:
            host: reviews
            subset: v2
    EOF
    {{< /text >}}

1.  Use the _Sign in_ button in the top right corner to sign in as `jason` (any password would do).
    You will see that now the ratings have red stars which means that your new version is used.

    {{< image width="80%"
        link="images/bookinfo-ratings-v3-jason.png"
        caption="Bookinfo Web Application, ratings v3 version for the jason user"
        >}}

    You can let a human tester test your new version as part of the whole application or use some automatic testing
    tool. This way you verify that your new version of the `reviews` microservice works correctly with all other
    microservices in production. You test the whole application, end-to-end, with the new version.

1.  Access your application's page several times, signed in as `jason`.

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    This time you will see the traffic to `reviews` is split between _v2_ and _v3_. Notice the icon that designates the
    `reviews` virtual service on the box that designates the `reviews` microservice.

    {{< image width="80%"
        link="images/kiali-reviews-v3.png"
        caption="Kiali Graph Tab with reviews v3"
        >}}

1.  Sign out. Now all the ratings appear with black stars which means that your old versions are used.

1.  You can query your virtual services:

    {{< text bash >}}
    $ kubectl get virtualservices
    NAME      AGE
    reviews   22m
    {{< /text >}}

1.  You can also see your virtual services and other Istio configuration items in the `Istio Config` tab of your Kiali
    console.

    {{< image width="80%"
        link="images/kiali-istio-config.png"
        caption="Kiali Istio Config tab"
        >}}

1.  Click on the `reviews` virtual service to see its visual representation.

    {{< image width="80%"
        link="images/kiali-reviews-virtual-service.png"
        caption="Kiali Reviews Virtual Service"
        >}}

---
title: Canary release with Istio
overview: Enable a new version of a microservice for a tester, in production.

weight: 80

---

In this module you deploy a new version of the _reviews_ microservice, _v3_. This version displays ratings as red stars
(_v2_ displayed ratings as black stars). In this and a couple of next modules, you will learn how deploying a new
version of a microservice can be made simple, effective and safe with Istio.

First, you want your new version to be accessible to testers only and not to the real clients. In this module you deploy
a new version and enable traffic to it for a tester with login name `jason`.

1.  Create a virtual service to limit the traffic to _reviews_ microservice to the _v1_ and _v2_ versions:

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
            subset: v1
          weight: 50
        - destination:
            host: reviews
            subset: v2
          weight: 50
    EOF
    {{< /text >}}

1.  Access your application's webpage and verify that it works as previously, in particular you see reviews as black
    stars or without stars, intermittently.

1.  Deploy a new version of the _reviews_ microservice, _v3_.
    Note that you are safe to deploy it: no traffic will arrive to your new version of the _reviews_ microservice
    thanks to the virtual service you defined in the previous step.

    {{< text bash >}}
    $ kubectl apply -l app=reviews,version=v3 -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo.yaml
    deployment "reviews-v3" created
    {{< /text >}}

1.  Check the pods of `reviews`. Note that you have three pods each of the different version, and each of them has two
    containers (an Istio sidecar was injected automatically in the `reviews v3`).

    {{< text bash >}}
    $ kubectl get pods -l app=reviews
    NAME                          READY     STATUS    RESTARTS   AGE
    reviews-v1-6f954d668-d7w4l    2/2       Running   0          4h
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
            subset: v1
          weight: 50
        - destination:
            host: reviews
            subset: v2
          weight: 50
    EOF
    {{< /text >}}

1.  Use the _Sign in_ button in the top right corner to sign in as `jason` (any password would do).
    You will see that now the ratings have red stars which means that your new version is used.
    You can let a human tester test your new version as part of the whole application or use some automatic testing
    tool. This way you verify that your new version of the _reviews_ microserice works correctly with all other
    microservices in production. You test the whole application, end-to-end, with the new version.

1.  Sign out. Now all the ratings appear without stars or with black stars which means that your old versions are used.

1.  You can query your virtual services:

    {{< text bash >}}
    $ kubectl get virtualservices
    NAME      AGE
    reviews   22m
    {{< /text >}}

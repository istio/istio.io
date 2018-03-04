---
title: Canary release with istio
overview: Overview

order: 07

layout: docs
type: markdown
---
{% include home.html %}\n# Canary Release with Istio
In this learning module we will deploy a new version of the _reviews_ microservice again,
this time with Istio enabled. We will release our new version to the `jason` user only (`jason` is our tester). It will allow the `jason` user to test the whole application end-to-end in production, with our new version.

1. Let's specify a routing rule that all the production traffic will flow to the version _v1_ of all the microservices:
   ```bash
   istioctl create -f ../../istio-*/samples/bookinfo/kube/route-rule-all-v1.yaml
   ```

2. Let's deploy our new version of the _reviews_ microservice. This time we will deploy it with the _app_ label, since Istio will route the traffic to _v1_ anyway. No traffic will arrive to our new version of the _reviews_ microservice.
   ```bash
   kubectl apply -f  ../05-adding-a-new-version-of-a-microservice/bookinfo-reviews-v2-with-app-label.yaml
   ```

3. Let' access the application's web page multiple times and verify that our new version is not called.

4. Now, let's apply an Istio [route rule](https://istio.io/docs/reference/config/istio.routing.v1alpha1.html) to allow `jason` user to access our new version for testing:
   ```bash
   istioctl create -f ../../istio-*/samples/bookinfo/kube/route-rule-reviews-test-v2.yaml
   ```

5. Let's login as `jason` (any password would do). We will see that now the reviews have black stars (our new version is used). Now we can let a human tester or a testing tool test our new version on the whole application

5. We verify that our new version of the _reviews_ microserice works correctly with all other microservices in production. We test the whole application, end-to-end, with the new version of the _reviews_ microservice.

6. Let's logout. Now all the reviews appear without stars (our old version is used).

7. We can query our routing rules:
   ```bash
   istioctl get routerules
   ```

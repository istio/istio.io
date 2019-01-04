---
title: Canary release with Istio
overview: Enable a new version of a microservice for a tester, in production.

order: 07

layout: docs
type: markdown
---

In this module we will deploy a new version of the _reviews_ microservice again,
this time with Istio enabled. We will release our new version to the `jason` user only (`jason` is our tester). It will allow the `jason` user to test the whole application end-to-end in production, with our new version.

1. Let's specify a routing rule to send all production traffic to version _v1_ of all the microservices:
   ```bash
   istioctl create -f samples/bookinfo/kube/route-rule-all-v1.yaml
   ```

2. Let's deploy our new version of the _reviews_ microservice. This time we will deploy the microservice's pod with the _app_ label, so the Kubernetes _reviews service_ will apply to it. Still, we are safe: no traffic will arrive to our new version of the _reviews_ microservice thanks to the route rule ([samples/bookinfo/kube/route-rule-all-v1.yaml](https://github.com/istio/istio/blob/master/samples/bookinfo/kube/route-rule-all-v1.yaml)) we defined in the previous step.

   ```bash
   kubectl apply -f samples/bookinfo/kube/bookinfo-reviews-v2.yaml
   ```

3. Let's access the application's web page multiple times and verify that our new version is not called.

4. Now, let's apply an Istio [route rule]({{home}}/docs/reference/config/istio.routing.v1alpha1.html) to allow the `jason` user to access our new version for testing:
   ```bash
   istioctl create -f samples/bookinfo/kube/route-rule-reviews-test-v2.yaml
   ```

5. Let's login as `jason` (any password would do). We will see that now the reviews have black stars (our new version is used). Now we can let a human tester or a testing tool test our new version as part of the whole application.

5. We verify that our new version of the _reviews_ microserice works correctly with all other microservices in production. We test the whole application, end-to-end, with the new version of the _reviews_ microservice.

6. Let's logout. Now all the reviews appear without stars (our old version is used).

7. We can query our routing rules:
   ```bash
   istioctl get routerules
   ```


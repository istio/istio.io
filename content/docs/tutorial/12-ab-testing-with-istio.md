---
title: A/B testing with Istio
overview: Deploy two different versions of a microservice and split the traffic between them.

order: 12

layout: docs
type: markdown
---

In this module, we deploy a new version of the _reviews_ microservice, _v3_. This version returns review stars in red, as opposed to the black of _reviews v2_.

Here we assume that we performed all the required testing of _reviews v3_, locally, in the staging and in the production environments. Now we want to perform _A/B_ testing: we will run two versions of the _reviews_ microservice, _v2_ and _v3_, splitting the requests 50:50. Then we will measure by various metrics which version is accepted better by the users. (Measuring business metrics is out of scope of Istio). Let's apply the corresponding rule and see that traffic is distributed between _v2_ and _v3_.

1. Let's deploy _reviews v3_:
  ```bash
  kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/bookinfo-reviews-v3.yaml)
  ```
2. Let's add a rule to distribute the traffic 50:50 between _reviews v2_ and _reviews v3_.
  ```bash
  istioctl create -f samples/bookinfo/kube/route-rule-reviews-v2-v3.yaml
  ```

3. Let's access the webpage of the application and see that now the red stars are displayed roughly every other refresh.


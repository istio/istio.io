---
title: Cleanup
overview: Undeploy Bookinfo and the Istio control plane with all the addons

order: 99

layout: docs
type: markdown
---
{% include home.html %}

1. Undeploy Bookinfo:
  ```bash
  kubectl delete -f <(istioctl kube-inject -f ../03-run-bookinfo-with-kubernetes/bookinfo.yaml)
  kubectl delete -f <(istioctl kube-inject -f ../06-add-istio-and-redeploy-bookinfo/ingress.yaml)
  kubectl delete -f <(istioctl kube-inject -f ../05-adding-a-new-version-of-a-microservice/bookinfo-reviews-v2-with-app-label.yaml)
  kubectl delete -f <(istioctl kube-inject -f ../10-ab-testing-with-istio/bookinfo-reviews-v3.yaml)
  kubectl delete -f <(istioctl kube-inject -f./../istio-*/samples/sleep/sleep.yaml)
  ```

2. Undeploy Istio with all the addons:
  ```bash
  kubectl delete -f ../../istio-*/install/kubernetes/istio.yaml
  ```

## What's next
{% if page.previous.url %}
Previous step: [{{page.previous.title}}]({{page.previous.url}})
{% endif %}

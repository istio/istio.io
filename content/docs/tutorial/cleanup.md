---
title: Cleanup
overview: Undeploy Bookinfo and the Istio control plane with all the addons.

weight: 990

---

1. Undeploy Bookinfo:
  ```bash
  kubectl delete -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/bookinfo.yaml)
  kubectl delete -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/ingress-for-istio.yaml)
  kubectl delete -f <(istioctl kube-inject -f samples/bookinfo/kube/bookinfo-reviews-v2.yaml)
  kubectl delete -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/bookinfo-reviews-v3.yaml)
  kubectl delete -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
  ```

2. Undeploy Istio with all the addons:
  ```bash
  kubectl delete -f install/kubernetes/istio.yaml
  ```

## What's next
Previous module: [{{page.previous.title}}]({{home}}{{page.previous.url}})

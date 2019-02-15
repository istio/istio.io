---
title: Cleanup
overview: Undeploy Bookinfo and the Istio control plane with all the addons.

weight: 990

---

1.  Undeploy Bookinfo:

    {{< text bash >}}
    $ kubectl delete -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/bookinfo.yaml)
    $ kubectl delete -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/ingress-for-istio.yaml)
    $ kubectl delete -f <(istioctl kube-inject -f samples/bookinfo/kube/bookinfo-reviews-v2.yaml)
    $ kubectl delete -f <(istioctl kube-inject -f samples/bookinfo/istio.io-tutorial/bookinfo-reviews-v3.yaml)
    $ kubectl delete -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
    {{< /text >}}

1.  Undeploy Istio with all the addons:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio.yaml
    {{< /text >}}

---
title: Setup
weight: 10
type: section-index
---

When the Kube-apiserver included proxy settings such as:

{{< text yaml >}}
env:
  - name: http_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: https_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: no_proxy
  value: 127.0.0.1,localhost,dockerhub.foo.com,devhub-docker.foo.com,10.84.100.125,10.84.100.126,10.84.100.127
{{< /text >}}
The sidecar injection would fail. The only related failure logs was in the kube-apiserver log:

{{< text plain >}}
W0227 21:51:03.156818       1 admission.go:257] Failed calling webhook, failing open sidecar-injector.istio.io: failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: Service Unavailable
{{< /text >}}

Make sure both pod and service CIDRs are not proxied according to *_proxy variables.  Check the kube-apiserver files and logs to verify the configuration and whether any requests are being proxied.

A workaround is to remove the proxy settings from the kube-apiserver manifest and restart the server or use a later version of Kubernetes.

An issue was filed with Kubernetes related to this and has since been closed.   [https://github.com/kubernetes/kubeadm/issues/666](https://github.com/kubernetes/kubeadm/issues/666)
[https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)

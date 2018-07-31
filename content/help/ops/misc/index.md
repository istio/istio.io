---
title: Miscellaneous
description: Advice on tackling common problems with Istio.
weight: 90
force_inline_toc: true
---

## Verifying connectivity to Istio Pilot

Verifying connectivity to Pilot is a useful troubleshooting step. Every proxy container in the service mesh should be able to communicate with Pilot. This can be accomplished in a few simple steps:

1.  Get the name of the Istio Ingress pod:

    {{< text bash >}}
    $ INGRESS_POD_NAME=$(kubectl get po -n istio-system | grep ingressgateway\- | awk '{print$1}'); echo ${INGRESS_POD_NAME};
    {{< /text >}}

1.  Exec into the Istio Ingress pod:

    {{< text bash >}}
    $ kubectl exec -it $INGRESS_POD_NAME -n istio-system /bin/bash
    {{< /text >}}

1.  Test connectivity to Pilot using `curl`. The following example invokes the v1 registration API using default Pilot configuration parameters and mutual TLS enabled:

    {{< text bash >}}
    $ curl -k --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem --key /etc/certs/key.pem https://istio-pilot:15003/v1/registration
    {{< /text >}}

    If mutual TLS is disabled:

    {{< text bash >}}
    $ curl http://istio-pilot:15003/v1/registration
    {{< /text >}}

You should receive a response listing the "service-key" and "hosts" for each service in the mesh.

## No traces appearing in Zipkin when running Istio locally on Mac

Istio is installed and everything seems to be working except there are no traces showing up in Zipkin when there
should be.

This may be caused by a known [Docker issue](https://github.com/docker/for-mac/issues/1260) where the time inside
containers may skew significantly from the time on the host machine. If this is the case,
when you select a very long date range in Zipkin you will see the traces appearing as much as several days too early.

You can also confirm this problem by comparing the date inside a docker container to outside:

{{< text bash >}}
$ docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

To fix the problem, you'll need to shutdown and then restart Docker before reinstalling Istio.

## Automatic sidecar injection will fail if the kube-apiserver has proxy settings

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

## What Envoy version is istio using?

To find out the envoy version, you can follow below steps:

1. `kubectl exec -it PODNAME -c istio-proxy -n NAMESPACE /bin/bash`

1. `curl localhost:15000/server_info`

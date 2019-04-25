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
    $ curl -k --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem --key /etc/certs/key.pem https://istio-pilot:8080/debug/edsz
    {{< /text >}}

    If mutual TLS is disabled:

    {{< text bash >}}
    $ curl http://istio-pilot:8080/debug/edsz
    {{< /text >}}

You should receive a response listing the "service-key" and "hosts" for each service in the mesh.

## No traces appearing in Zipkin when running Istio locally on Mac

Istio is installed and everything seems to be working except there are no traces showing up in Zipkin when there
should be.

This may be caused by a known [Docker issue](https://github.com/docker/for-mac/issues/1260) where the time inside
containers may skew significantly from the time on the host machine. If this is the case,
when you select a very long date range in Zipkin you will see the traces appearing as much as several days too early.

You can also confirm this problem by comparing the date inside a Docker container to outside:

{{< text bash >}}
$ docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

To fix the problem, you'll need to shutdown and then restart Docker before reinstalling Istio.

## Automatic sidecar injection fails if the Kubernetes API server has proxy settings

When the Kubernetes API server includes proxy settings such as:

{{< text yaml >}}
env:
  - name: http_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: https_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: no_proxy
  value: 127.0.0.1,localhost,dockerhub.foo.com,devhub-docker.foo.com,10.84.100.125,10.84.100.126,10.84.100.127
{{< /text >}}

With these settings, Sidecar injection fails. The only related failure log can be found in `kube-apiserver` log:

{{< text plain >}}
W0227 21:51:03.156818       1 admission.go:257] Failed calling webhook, failing open sidecar-injector.istio.io: failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: Service Unavailable
{{< /text >}}

Make sure both pod and service CIDRs are not proxied according to *_proxy variables.  Check the `kube-apiserver` files and logs to verify the configuration and whether any requests are being proxied.

A workaround is to remove the proxy settings from the `kube-apiserver` manifest and restart the server or use a later version of Kubernetes.

An [issue](https://github.com/kubernetes/kubeadm/issues/666) was filed with Kubernetes related to this and has since been closed.
[https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)

## What Envoy version is Istio using?

To find out the Envoy version used in deployment, you can `exec` into the container and query the `server_info` endpoint:

{{< text bash >}}
$ kubectl exec -it PODNAME -c istio-proxy -n NAMESPACE /bin/bash
root@5c7e9d3a4b67:/# curl localhost:15000/server_info
envoy 0/1.9.0-dev//RELEASE live 57964 57964 0
{{< /text >}}

In addition, the `Envoy` and `istio-api` repository versions are stored as labels on the image:

{{< text bash >}}
$ docker inspect -f '{{json .Config.Labels }}' ISTIO-PROXY-IMAGE
{"envoy-vcs-ref":"b3be5713f2100ab5c40316e73ce34581245bd26a","istio-api-vcs-ref":"825044c7e15f6723d558b7b878855670663c2e1e"}
{{< /text >}}

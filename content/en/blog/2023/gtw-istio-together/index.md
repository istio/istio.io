---
title: Gateway API and Istio's Traffic-management API Working Together
description: Using Istio traffic-management resources to supplement the configuration for Istio features not fully supported in the Gateway API.
publishdate: 2023-06-01
attribution: Frank Budinsky (IBM)
keywords: [traffic-management,gateway,gateway-api,api,gamma,sig-network]
---

If you've heard about the latest-and-greatest new API for configuring traffic management in Kubernetes,
[Gateway API](https://gateway-api.sigs.k8s.io/), you may also know that Istio plans to make it the default
API for all of its traffic management in the future. If you've also started to
[consider using Gateway API](/blog/2022/getting-started-gtwapi/), instead of the traditional Istio API to
configure your traffic, you may have noticed that Gateway API does not currently cover 100% of Istio's features.

Some of the missing Istio features are, or will be, supported using Gateway API's extensibility plug-points
or policy attachments, others are expected to be added to the API proper at some time in the future.
You may be wondering, however, how you can use Gateway API today if your application needs features
that are not currently, or may never be, supported by the Gateway API. 

Fortunately, Gateway API and Istio's configuration API are not mutually exclusive.
The two APIs can be used together, giving you the ability to use Gateway API for much of your
traffic management and then supplement it with the traditional Istio API to
do things that are not currently possible using Gateway API. Over time, as new features are added to
the Gateway API, you will be able, but not required, to switch to using Gateway API to
configure those features as well.

In this article, we'll look at some examples of how you can augment Gateway API configuration with Istio
configuration resources to let you use Istio freatures that are not currently supported by Gateway API.
If you'd like to run some of the examples yourself, install the experimental Gateway API CRDs
and a recent version minimal Istio runtime before proceeding:

{{< text bash >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -
$ istioctl install --set profile=minimal
{{< /text >}}

## Gateway API to Istio resource mapping

To understand how you can combine Istio configuration with Gateway API configuration, you first need to
know how Istio represents the Gateway API configuration internally. Quite simply, Gateway API configuration
resources, like `Gateway`, `HTTPRoute`, etc., are converted by the Istio gateway-controller to ordinary,
but hidden, Istio configuration resources, like `networking.istio.io/v1beta1.Gateway` and
`networking.istio.io/v1beta1.VirtualService`, which are then used to program Envoy proxies, just
like any other Istio configuration resources that you create yourself. So the key point is that
"under the covers" everything is configured using the Istio configuration API. Gateway API is just
a standard Kubernetes API layer above it.

### Viewing the generated resources

Before you can combine Gateway API and Istio configuration resources, you need to first understand how
Istio converts the Gateway API resources to Isito ones.

You can use the `istioctl x internal-debug` command to view the internal config resources generated from
your Gateway API configuration:

{{< text bash >}}
$ istioctl x internal-debug configz | yq -P
{{< /text >}}

To illustrate, let's start with a simple HTTPRoute definition:


## Route rules

Deploy the `helloworld` and `sleep` samples:

{{< text bash >}}
$ kubectl create ns sample
$ kubectl label namespace sample istio-injection=enabled
$ kubectl apply -n sample -f @samples/helloworld/helloworld.yaml@ -f @samples/helloworld/gateway-api/helloworld-versions.yaml@
$ kubectl apply -n sample -f @samples/sleep/sleep.yaml@
{{< /text >}}

Wait for the pods to be up and running:

{{< text bash >}}
$ kubectl get pod -n sample
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-78b9f5c87f-szgcq   2/2     Running   0          10s
helloworld-v2-54dddc5567-nqcrq   2/2     Running   0          10s
sleep-78ff5975c6-gv888           2/2     Running   0          8s
{{< /text >}}

Route to `helloworld:v1` using Gateway API:

{{< text bash >}}
$ kubectl apply -n sample -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: helloworld
    port: 5000
  rules:
  - backendRefs:
    - name: helloworld-v1
      port: 5000
EOF
{{< /text >}}

{{< text bash >}}
$ for run in {1..10}; do \
    kubectl exec -n sample -c sleep deployment/sleep -- curl -sS helloworld.sample:5000/hello; done
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
{{< /text >}}

Inject fault using an Istio `VirtualService`:

{{< text bash >}}
$ kubectl apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - helloworld
  http:
  - route:
    - destination:
        host: helloworld-v2
        port:
          number: 5000
    fault:
      abort:
        percentage:
          value: 50
        httpStatus: 500
EOF
{{< /text >}}

{{< text bash >}}
$ for run in {1..10}; do \
    kubectl exec -n sample -c sleep deployment/sleep -- curl -s helloworld.sample:5000/hello | sed -e "s/abort/abort\n/"; done
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
Hello version: v1, instance: helloworld-v1-78b9f5c87f-szgcq
{{< /text >}}

{{< text bash >}}
$ kubectl delete -n sample httproute helloworld
{{< /text >}}

{{< text bash >}}
$ for run in {1..10}; do \
    kubectl exec -n sample -c sleep deployment/sleep -- curl -s helloworld.sample:5000/hello | sed -e "s/abort/abort\n/"; done
fault filter abort
Hello version: v2, instance: helloworld-v2-54dddc5567-nqcrq
Hello version: v2, instance: helloworld-v2-54dddc5567-nqcrq
fault filter abort
fault filter abort
Hello version: v2, instance: helloworld-v2-54dddc5567-nqcrq
fault filter abort
Hello version: v2, instance: helloworld-v2-54dddc5567-nqcrq
Hello version: v2, instance: helloworld-v2-54dddc5567-nqcrq
fault filter abort
{{< /text >}}

{{< text bash >}}
$ kubectl delete -n sample virtualservice helloworld
{{< /text >}}

## Ingress

So, once you know the names of these internal resources, you can create other compatible Istio resources which
work with them hand in hand.

Deploy the `httpbin` test application:

{{< text bash >}}
$ kubectl create namespace sample-ingress
$ kubectl apply -n sample-ingress -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n sample-ingress -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: example-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: default
    hostname: "*.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
      kinds:
      - kind: HTTPRoute
      - kind: VirtualService
        group: "networking.istio.io"
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin-get
spec:
  parentRefs:
  - name: example-gateway
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /get
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl wait -n sample-ingress --for=condition=programmed gateways.gateway.networking.k8s.io example-gateway
$ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io example-gateway -n sample-ingress -ojsonpath='{.status.addresses[0].value}')
{{< /text >}}

{{< text bash >}}
$ curl -sI -HHost:httpbin.example.com http://$INGRESS_HOST/get
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n sample-ingress -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin-headers
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - "gateway.networking.k8s.io:example-gateway.default"
  http:
  - match:
    - uri:
        exact: /headers
    fault:
      abort:
        percentage:
          value: 50
        httpStatus: 500
    route:
    - destination:
        host: httpbin
        port:
          number: 8000
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n sample-ingress -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin-headers
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - "sample-ingress/example-gateway-istio-autogenerated-k8s-gateway-default"
  http:
  - match:
    - uri:
        exact: /headers
    fault:
      abort:
        percentage:
          value: 50
        httpStatus: 500
    route:
    - destination:
        host: httpbin
        port:
          number: 8000
EOF
{{< /text >}}

{{< text bash >}}
$ curl -sI -HHost:httpbin.example.com http://$INGRESS_HOST/headers
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n sample-ingress -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: example-gateway
spec:
  selector:
    istio.io/gateway-name: example-gateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*.example.com"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin-headers
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - example-gateway
  http:
  - match:
    - uri:
        exact: /headers
    fault:
      abort:
        percentage:
          value: 50
        httpStatus: 500
    route:
    - destination:
        host: httpbin
        port:
          number: 8000
EOF
{{< /text >}}

## Summary

In this article, ...

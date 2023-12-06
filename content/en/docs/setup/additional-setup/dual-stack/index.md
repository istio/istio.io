---
title: Install Istio in Dual-Stack mode
description: Install and use Istio in Dual-Stack mode running on a Dual-Stack Kubernetes cluster.
weight: 70
keywords: [dual-stack]
owner: istio/wg-networking-maintainers
test: yes
---

{{< boilerplate experimental >}}

## Prerequisites

* Istio 1.17 or later.
* Kubernetes 1.23 or later [configured for dual-stack operations](https://kubernetes.io/docs/concepts/services-networking/dual-stack/).

## Installation steps

If you want to use `kind` for your test, you can set up a dual stack cluster with the following command:

{{< text syntax=bash snip_id=none >}}
$ kind create cluster --name istio-ds --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: dual
EOF
{{< /text >}}

To enable dual-stack for Istio, you will need to modify your `IstioOperator` or Helm values with the following configuration.

{{< tabset category-name="dualstack" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_DUAL_STACK: "true"
  values:
    pilot:
      env:
        ISTIO_DUAL_STACK: "true"
    # The below values are optional and can be used based on your requirements
    gateways:
      istio-ingressgateway:
        ipFamilyPolicy: RequireDualStack
      istio-egressgateway:
        ipFamilyPolicy: RequireDualStack
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text syntax=yaml snip_id=none >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ISTIO_DUAL_STACK: "true"
values:
  pilot:
    env:
      ISTIO_DUAL_STACK: "true"
  # The below values are optional and can be used based on your requirements
  gateways:
    istio-ingressgateway:
      ipFamilyPolicy: RequireDualStack
    istio-egressgateway:
      ipFamilyPolicy: RequireDualStack
{{< /text >}}

{{< /tab >}}

{{< tab name="Istioctl" category-value="istioctl" >}}

{{< text syntax=bash snip_id=none >}}
$ istioctl install --set values.pilot.env.ISTIO_DUAL_STACK=true --set meshConfig.defaultConfig.proxyMetadata.ISTIO_DUAL_STACK="true" --set values.gateways.istio-ingressgateway.ipFamilyPolicy=RequireDualStack --set values.gateways.istio-egressgateway.ipFamilyPolicy=RequireDualStack -y
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Verification

1. Create three namespaces:

    * `dual-stack`: `tcp-echo` will listen on both an IPv4 and IPv6 address.
    * `ipv4`: `tcp-echo` will listen on only an IPv4 address.
    * `ipv6`: `tcp-echo` will listen on only an IPv6 address.

    {{< text bash >}}
    $ kubectl create namespace dual-stack
    $ kubectl create namespace ipv4
    $ kubectl create namespace ipv6
    {{< /text >}}

1. Enable sidecar injection on all of those namespaces as well as the `default` namespace:

    {{< text bash >}}
    $ kubectl label --overwrite namespace default istio-injection=enabled
    $ kubectl label --overwrite namespace dual-stack istio-injection=enabled
    $ kubectl label --overwrite namespace ipv4 istio-injection=enabled
    $ kubectl label --overwrite namespace ipv6 istio-injection=enabled
    {{< /text >}}

1. Create [tcp-echo]({{< github_tree >}}/samples/tcp-echo) deployments in the namespaces:

    {{< text bash >}}
    $ kubectl apply --namespace dual-stack -f @samples/tcp-echo/tcp-echo-dual-stack.yaml@
    $ kubectl apply --namespace ipv4 -f @samples/tcp-echo/tcp-echo-ipv4.yaml@
    $ kubectl apply --namespace ipv6 -f @samples/tcp-echo/tcp-echo-ipv6.yaml@
    {{< /text >}}

1. Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample app to use as a test source for sending requests.

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. Verify the traffic reaches the dual-stack pods:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo dualstack | nc tcp-echo.dual-stack 9000"
    hello dualstack
    {{< /text >}}

1. Verify the traffic reaches the IPv4 pods:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv4 | nc tcp-echo.ipv4 9000"
    hello ipv4
    {{< /text >}}

1. Verify the traffic reaches the IPv6 pods:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv6 | nc tcp-echo.ipv6 9000"
    hello ipv6
    {{< /text >}}

1. Verify the envoy listeners:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl proxy-config listeners "$(kubectl get pod -n dual-stack -l app=tcp-echo -o jsonpath='{.items[0].metadata.name}')" -n dual-stack --port 9000
    {{< /text >}}

    You will see listeners are now bound to multiple addresses, but only for dual stack services. Other services will only be listening on a single IP address.

    {{< text syntax=json snip_id=none >}}
        "name": "fd00:10:96::f9fc_9000",
        "address": {
            "socketAddress": {
                "address": "fd00:10:96::f9fc",
                "portValue": 9000
            }
        },
        "additionalAddresses": [
            {
                "address": {
                    "socketAddress": {
                        "address": "10.96.106.11",
                        "portValue": 9000
                    }
                }
            }
        ],
    {{< /text >}}

1. Verify virtual inbound addresses are configured to listen on both `0.0.0.0` and `[::]`.

    {{< text syntax=json snip_id=none >}}
    "name": "virtualInbound",
    "address": {
        "socketAddress": {
            "address": "0.0.0.0",
            "portValue": 15006
        }
    },
    "additionalAddresses": [
        {
            "address": {
                "socketAddress": {
                    "address": "::",
                    "portValue": 15006
                }
            }
        }
    ],
    {{< /text >}}

1. Verify envoy endpoints are configured to route to both IPv4 and IPv6:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl proxy-config endpoints "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" --port 9000
    ENDPOINT                 STATUS      OUTLIER CHECK     CLUSTER
    10.244.0.19:9000         HEALTHY     OK                outbound|9000||tcp-echo.ipv4.svc.cluster.local
    10.244.0.26:9000         HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
    fd00:10:244::1a:9000     HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
    fd00:10:244::18:9000     HEALTHY     OK                outbound|9000||tcp-echo.ipv6.svc.cluster.local
    {{< /text >}}

Now you can experiment with dual-stack services in your environment!

## Cleanup

1. Cleanup application namespaces and deployments

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    $ kubectl delete ns dual-stack ipv4 ipv6
    {{< /text >}}

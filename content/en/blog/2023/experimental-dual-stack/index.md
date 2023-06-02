---
title: "Support for Dual Stack Kubernetes Clusters"
description: "Experimental support for Dual Stack Kubernetes Clusters."
publishdate: 2023-03-10
attribution: "Steve Zhang (Intel), Alex Xu (Intel), Iris Ding (Intel), Jacob Delgado (F5), Ying-chun Cai (formerly F5)"
keywords: [dual-stack]
---

Over the past year, both Intel and F5 have collaborated on an effort to bring support for
[Kubernetes Dual-Stack networking](https://kubernetes.io/docs/concepts/services-networking/dual-stack/) to Istio.

## Background

The journey has taken us longer than anticipated and we continue to have work to do. The team initially started with a design based
on a reference implementation from F5. The design led to an [RFC](https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/edit?usp=sharing) that caused us to re-examine our approach. Notably, there were concerns about memory and performance issues that the community wanted
to be addressed before implementation. The original design had to duplicate Envoy configuration for listeners, clusters, routes and endpoints. Given that many people already experience Envoy memory and CPU consumption issues, early feedback wanted us to completely re-evaluate this approach. Many proxies transparently handle outbound dual-stack traffic regardless of how the traffic was originated. Much of the earliest feedback was to implement the same behavior in Istio and Envoy.

## Redefining Dual Stack Support

Much of the feedback provided by the community for the original RFC was to update Envoy to better support dual-stack use cases
internally instead of supporting this within Istio. This has led us to a [new design](https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/edit?usp=sharing) where we have taken lessons learned as well as feedback and have applied them to fit a simplified design.

## Support for Dual Stack in Istio 1.17

We have worked with the Envoy community to address numerous concerns which is a reason why dual-stack enablement has
taken us a while to implement. We have implemented [matched IP Family for outbound listener](https://github.com/envoyproxy/envoy/issues/16804)
and [supported multiple addresses per listener](https://github.com/envoyproxy/envoy/issues/11184). Alex Xu has also
been working fervently to get long outstanding issues resolved, with the ability for Envoy to have a
[smarter way to pick endpoints for dual-stack](https://github.com/envoyproxy/envoy/issues/21640). Some of these improvements
to Envoy, such as the ability to [enable socket options on multiple addresses](https://github.com/envoyproxy/envoy/pull/23496),
have landed in the Istio 1.17 release (e.g. [extra source addresses on inbound clusters](https://github.com/istio/istio/pull/41618)).

The Envoy API changes made by the team can be found at their site at [Listener addresses](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto.html?highlight=additional_addresses) and [bind config](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/address.proto#config-core-v3-bindconfig). Making sure we can have proper support at both the downstream and upstream connection for Envoy is important for realizing
dual-stack support.

In total the team has submitted over a dozen PRs to Envoy and are working on at least a half dozen more to make Envoy adoption of
dual stack easier for Istio.

Meanwhile, on the Istio side you can track the progress in [Issue #40394](https://github.com/istio/istio/issues/40394).
Progress has slowed down a bit lately as we continue working with Envoy on various issues, however, we are happy to
announce experimental support for dual stack in Istio 1.17!

## A Quick Experiment using Dual Stack

{{< tip >}}
If you want to use KinD for your test, you can set up a dual stack cluster with the following command:

{{< text bash >}}
$ kind create cluster --name istio-ds --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: dual
EOF
{{< /text >}}

{{< /tip >}}
1. Enable dual stack experimental support on Istio 1.17.0+ with the following:

    {{< text bash >}}
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          proxyMetadata:
            ISTIO_AGENT_DUAL_STACK: "true"
      values:
        pilot:
          env:
            ISTIO_DUAL_STACK: "true"
    EOF
    {{< /text >}}

1. Create three namespaces:

    * `dual-stack`: `tcp-echo` will listen on both an IPv4 and IPv6 address.
    * `ipv4`: `tcp-echo` will listen on only an IPv4 address.
    * `ipv6`: `tcp-echo` will listen on only an IPv6 address.

    {{< text bash >}}
    $ kubectl create namespace dual-stack
    $ kubectl create namespace ipv4
    $ kubectl create namespace ipv6
    {{< /text >}}

1. Enable sidecar injection on all of those namespaces as well as the default namespace:

    {{< text bash >}}
    $ kubectl label --overwrite namespace default istio-injection=enabled
    $ kubectl label --overwrite namespace dual-stack istio-injection=enabled
    $ kubectl label --overwrite namespace ipv4 istio-injection=enabled
    $ kubectl label --overwrite namespace ipv6 istio-injection=enabled
    {{< /text >}}

1. Create `tcp-echo` deployments in the namespaces:

    {{< text bash >}}
    $ kubectl apply --namespace dual-stack -f {{< github_file >}}/samples/tcp-echo/tcp-echo-dual-stack.yaml
    $ kubectl apply --namespace ipv4 -f {{< github_file >}}/samples/tcp-echo/tcp-echo-ipv4.yaml
    $ kubectl apply --namespace ipv6 -f {{< github_file >}}/samples/tcp-echo/tcp-echo-ipv6.yaml
    {{< /text >}}

1. Create sleep deployment in the default namespace:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml
    {{< /text >}}

1. Verify the traffic:

    {{< text bash >}}
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo dualstack | nc tcp-echo 9000"
    hello dualstack
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv4 | nc tcp-echo.ipv4 9000"
    hello ipv4
    $ kubectl exec -it "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv6 | nc tcp-echo.ipv6 9000"
    hello ipv6
    {{< /text >}}

Now you can experiment with dual-stack services in your environment!

## Important Changes to Listeners and Endpoints

For the above experiment, you'll notice changes are made to listeners and routes:

{{< text bash >}}
$ istioctl proxy-config listeners "$(kubectl get pod -n dual-stack -l app=tcp-echo -o jsonpath='{.items[0].metadata.name}')" -n dual-stack --port 9000
{{< /text >}}

You will see listeners are now bound to multiple addresses, but only for dual stack services. Other services will only
be listening on a single IP address.

{{< text json >}}
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

Virtual inbound addresses are now also configured to listen on both `0.0.0.0` and `[::]`.

{{< text json >}}
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

Envoy's endpoints now are configured to route to both IPv4 and IPv6:

{{< text bash >}}
$ istioctl proxy-config endpoints "$(kubectl get pod -n sleep -l app=tcp-echo -o jsonpath='{.items[0].metadata.name}')" --port 9000
ENDPOINT                 STATUS      OUTLIER CHECK     CLUSTER
10.244.0.19:9000         HEALTHY     OK                outbound|9000||tcp-echo.ipv4.svc.cluster.local
10.244.0.26:9000         HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
fd00:10:244::1a:9000     HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
fd00:10:244::18:9000     HEALTHY     OK                outbound|9000||tcp-echo.ipv6.svc.cluster.local
{{< /text >}}

## Get Involved

Plenty of work remains, and you are welcome to help us with the remaining tasks needed for dual stack support to get to
Alpha [here](https://github.com/istio/enhancements/blob/master/features/dual-stack-support.md).

For instance, Iris Ding (Intel) and Li Chun (Intel) are already working with the community for getting redirection of
network traffic for ambient, and we are hoping to have ambient support dual stack for its upcoming alpha release in
Istio 1.18.

We would love your feedback and if you are eager to work with us please stop by our slack channel, #dual-stack within
the [Istio Slack](https://slack.istio.io/).

_Thank you to the team that has worked on Istio dual-stack!_
* Intel: [Steve Zhang](https://github.com/zhlsunshine), [Alex Xu](https://github.com/soulxu), [Iris Ding](https://github.com/irisdingbj)
* F5: [Jacob Delgado](https://github.com/jacob-delgado)
* [Yingchun Cai](https://github.com/ycai-aspen) (formerly of F5)

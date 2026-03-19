---
title: NetworkPolicy
description: Deploy optional Kubernetes NetworkPolicy resources for Istio components.
weight: 75
keywords: [networkpolicy,security,helm]
owner: istio/wg-networking-maintainers
test: no
---

Istio can optionally deploy Kubernetes [`NetworkPolicy`](https://kubernetes.io/docs/concepts/services-networking/network-policies/) resources for its components. This is useful in clusters that enforce a default-deny network policy, which is a common requirement in secured environments.

When enabled, `NetworkPolicy` resources are created for istiod, istio-cni, ztunnel, and Helm-installed gateways, defining the ingress ports each component needs. All egress is allowed by default, since components like istiod need to connect to user-defined endpoints (e.g. JWKS URLs). The gateway `NetworkPolicy` automatically includes the service ports configured in the gateway's Helm values.

{{< warning >}}
Gateways created through the Kubernetes Gateway API or [gateway injection](/docs/setup/additional-setup/gateway/#deploying-a-gateway), waypoint proxies, and sidecars are **not** covered by Istio's built-in `NetworkPolicy` — you must create and manage `NetworkPolicy` resources for those separately. This is by design: automatically managing `NetworkPolicy` for these proxies would require granting istiod permissions to create and modify `NetworkPolicy` resources cluster-wide, which would negatively impact the security posture of the control plane.
{{< /warning >}}

{{< tip >}}
For information on how ambient mode interacts with `NetworkPolicy` on your application pods, see [Ambient and Kubernetes NetworkPolicy](/docs/ambient/usage/networkpolicy/).
{{< /tip >}}

## Enabling NetworkPolicy

To enable `NetworkPolicy`, set `global.networkPolicy.enabled=true` during installation.

With `istioctl`:

{{< text bash >}}
$ istioctl install --set values.global.networkPolicy.enabled=true
{{< /text >}}

With Helm, pass the setting to each chart:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --set global.networkPolicy.enabled=true
$ helm install istio-cni istio/cni -n istio-system --set global.networkPolicy.enabled=true
$ helm install ztunnel istio/ztunnel -n istio-system --set global.networkPolicy.enabled=true
$ helm install istio-ingressgateway istio/gateway -n istio-ingress --set global.networkPolicy.enabled=true
{{< /text >}}

## Reviewing the generated policies

Each component's `NetworkPolicy` allows ingress on the specific ports that component needs, and permits all egress (since components like istiod need to connect to user-defined endpoints such as JWKS URLs).

You can preview the exact `NetworkPolicy` resources that will be created by using `helm template`:

{{< text bash >}}
$ helm template istiod istio/istiod -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

{{< text bash >}}
$ helm template istio-cni istio/cni -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

{{< text bash >}}
$ helm template ztunnel istio/ztunnel -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

To inspect the policies after installation:

{{< text bash >}}
$ kubectl get networkpolicy -n istio-system
{{< /text >}}

## Customizing NetworkPolicy

The `NetworkPolicy` resources created by Istio are intentionally broad — ingress rules use empty `from` selectors, meaning traffic is allowed from any source on the listed ports. This is because the source of legitimate traffic (e.g. kube-apiserver, Prometheus, application pods) varies between clusters.

If you need more restrictive policies, you can disable Istio's built-in `NetworkPolicy` and create your own, using the output of `helm template` as a starting point.

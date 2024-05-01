---
title: Layer 7 with Waypoint Proxies
description: Gain the full set of Istio feature with optional waypoint proxies.
weight: 2
aliases:
  - /docs/ops/ambient/usage/waypoint
  - /latest/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: no
---

Ambient splits Istio’s functionality into two distinct layers, a secure overlay layer and a Layer 7 processing layer.
The waypoint proxy is an optional component that is Envoy-based and handles L7 processing for different resources.
What is unique about the waypoint proxy is that it runs outside of the application pod. A waypoint proxy can install,
upgrade, and scale independently from the application, as well as reduce operational costs. When deploying a waypoint,
you can configure the waypoint to process traffic for different resource types such as `service` or `workload` or `all`.

## Do you need a waypoint proxy?

This layered approach of ambient allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure overlay, to full L7 processing. If your applications require any of the following L7 mesh functions, you will need to use waypoint proxy for your applications:

{{< image width="100%"
link="L7-processing-layer.png"
caption="L7 processing layer"
>}}

## Deploy a waypoint proxy

Waypoint proxies can process traffic for `service`, `workload` or `all`. You can also configre your waypoint proxy to
process `none` of the traffic, which is primarily used for testing purpose as you incrementally add a waypoint proxy to
your application.

Waypoint proxies are deployed declaratively using Kubernetes Gateway resources or the helpful istioctl command. You can
preview the generated Kubernetes Gateway resource, for example, the command below generates a waypoint proxy for the
`default` namespace that can process traffic for services in the namespace:

{{< text bash >}}
$ istioctl x waypoint generate -n default
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

Note the Gateway resource has `istio-waypoint` as `gatewayClassName` which indicates it is a waypoint provided by Istio. The
Gateway resource is labeled with `istio.io/waypoint-for: service`, indicating the waypoint can process traffic for services,
which is the default.

To deploy a waypoint proxy for the `default` namespace, use the command below:

{{< text bash >}}
$ istioctl x waypoint apply -n default
{{< /text >}}

Or, you can deploy the generated Gateway resource from the `istioctl x waypoint generate` command to your Kubernetes cluster:

{{< text bash >}}
$ kubectl apply -f - <<EOF
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

To config your waypoint to process traffic differently than the default `service`, you can modify the `istio.io/waypoint-for` label
value to the desired value (`workload` or `all` or `none`). For example, the command below deploys a waypoint proxy for the
`default` namespace that can process `all` traffic in the namespace declaractively using the Kubernetes Gateway resource:

{{< text bash >}}
$ kubectl apply -f - <<EOF
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: all
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

Or use the `istioctl x waypoint apply` command with the `--for` parameter such as `istioctl x waypoint apply -n default --for all`.

After the Gateway resources are applied, Istiod will monitor these resources, deploy and manage the corresponding waypoint deployments for users automatically.

## Use a waypoint proxy

By default, waypoint proxy can be used for any services for the namespace where the waypoint proxy runs.

## Attach L7 policies to the waypoint proxy


## Debug your waypoint proxy

---
title: Troubleshoot issues with waypoints
description: How to investigate problems routing through waypoint proxies.
weight: 70
owner: istio/wg-networking-maintainers
test: no
---

This guide describes what to do if you have enrolled a namespace, service or workload in a waypoint proxy, but you are not seeing the expected behavior.

## Problems with traffic routing or security policy

To send some requests to the `reviews` service via the `productpage` service from the `sleep` pod:

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/productpage
{{< /text >}}

To send some requests to the `reviews` `v2` pod from the `sleep` pod:

{{< text bash >}}
$ export REVIEWS_V2_POD_IP=$(kubectl get pod -l version=v2,app=reviews -o jsonpath='{.items[0].status.podIP}')
$ kubectl exec deploy/sleep -- curl -s http://$REVIEWS_V2_POD_IP:9080/reviews/1
{{< /text >}}

Requests to the `reviews` service should be enforced by the `reviews-svc-waypoint` for any L7 policies.
Requests to the `reviews` `v2` pod should be enforced by the `reviews-v2-pod-waypoint` for any L7 policies.

1.  If your L7 configuration isn't applied, run `istioctl analyze` first to check if your configuration has a validation issue.

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

1.  Determine which waypoint is implementing the L7 configuration for your service or pod.

    If your source calls the destination using the service's hostname or IP, use the `istioctl experimental ztunnel-config service` command to confirm your waypoint is used by the destination service. Following the example earlier, the `reviews` service should use the `reviews-svc-waypoint` while all other services in the `default` namespace should use the namespace `waypoint`.

    {{< text bash >}}
    $ istioctl experimental ztunnel-config service
    NAMESPACE    SERVICE NAME            SERVICE VIP   WAYPOINT
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      bookinfo-gateway-istio  10.43.164.194 waypoint
    default      details                 10.43.160.119 waypoint
    default      kubernetes              10.43.0.1     waypoint
    default      notsleep                10.43.156.147 waypoint
    default      productpage             10.43.172.254 waypoint
    default      ratings                 10.43.71.236  waypoint
    default      reviews                 10.43.162.105 reviews-svc-waypoint
    ...
    {{< /text >}}

    If your source calls the destination using a pod IP, use the `istioctl experimental ztunnel-config workload` command to confirm your waypoint is used by the destination pod. Following the example earlier, the `reviews` `v2` pod should use the `reviews-v2-pod-waypoint` while all other pods in the `default` namespace should not have any waypoints, because by default [a waypoint only handles traffic addressed to services](/docs/ambient/usage/waypoint/#waypoint-traffic-types).

    {{< text bash >}}
    $ istioctl experimental ztunnel-config workload
    NAMESPACE    POD NAME                                    IP         NODE                     WAYPOINT                PROTOCOL
    default      bookinfo-gateway-istio-7c57fc4647-wjqvm     10.42.2.8  k3d-k3s-default-server-0 None                    TCP
    default      details-v1-698d88b-wwsnv                    10.42.2.4  k3d-k3s-default-server-0 None                    HBONE
    default      notsleep-685df55c6c-nwhs6                   10.42.0.9  k3d-k3s-default-agent-0  None                    HBONE
    default      productpage-v1-675fc69cf-fp65z              10.42.2.6  k3d-k3s-default-server-0 None                    HBONE
    default      ratings-v1-6484c4d9bb-crjtt                 10.42.0.4  k3d-k3s-default-agent-0  None                    HBONE
    default      reviews-svc-waypoint-c49f9f569-b492t        10.42.2.10 k3d-k3s-default-server-0 None                    TCP
    default      reviews-v1-5b5d6494f4-nrvfx                 10.42.2.5  k3d-k3s-default-server-0 None                    HBONE
    default      reviews-v2-5b667bcbf8-gj7nz                 10.42.0.5  k3d-k3s-default-agent-0  reviews-v2-pod-waypoint HBONE
    ...
    {{< /text >}}

    If the value for the pod's waypoint column isn't correct, verify your pod is labeled with `istio.io/use-waypoint` and the label's value is the name of a waypoint that can process
    workload traffic.  For example, if your `reviews` `v2` pod uses a waypoint that can only process service traffic, you will not see any waypoint used by that pod.
    If the `istio.io/use-waypoint` label on your pod looks correct verify that the Gateway resource for your waypoint is labeled with a compatible value for `istio.io/waypoint-for`. In the case of a pod, suitable values would be `all` or `workload`.

1.  Check the waypoint's proxy status via the `istioctl proxy-status` command.

    {{< text bash >}}
    $ istioctl proxy-status
    NAME                                                CLUSTER        CDS         LDS         EDS          RDS          ECDS         ISTIOD                      VERSION
    bookinfo-gateway-istio-7c57fc4647-wjqvm.default     Kubernetes     SYNCED      SYNCED      SYNCED       SYNCED       NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    reviews-svc-waypoint-c49f9f569-b492t.default        Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    reviews-v2-pod-waypoint-7f5dbd597-7zzw7.default     Kubernetes     SYNCED      SYNCED      NOT SENT     NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    waypoint-6f7b665c89-6hppr.default                   Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    ...
    {{< /text >}}

1.  Enable Envoy's [access log](/docs/tasks/observability/logs/access-log/) and check the logs of the waypoint proxy after sending some requests:

    {{< text bash >}}
    $ kubectl logs deploy/waypoint
    {{< /text >}}

    If there is not enough information, you can enable the debug logs for the waypoint proxy:

    {{< text bash >}}
    $ istioctl pc log deploy/waypoint --level debug
    {{< /text >}}

1.  Check the envoy configuration for the waypoint via the `istioctl proxy-config` command, which shows all the information related to the waypoint such as clusters, endpoints, listeners, routes and secrets:

    {{< text bash >}}
    $ istioctl proxy-config all deploy/waypoint
    {{< /text >}}

Refer to the [deep dive into Envoy configuration](/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration) section for more
information regarding how to debug Envoy since waypoint proxies are based on Envoy.

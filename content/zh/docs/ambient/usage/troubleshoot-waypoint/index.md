---
title: waypoint 问题故障排除
description: 如何排查路由经过 waypoint 代理的难题。
weight: 70
owner: istio/wg-networking-maintainers
test: no
---

本指南说明如果您已经将命名空间、服务或工作负载注册到 waypoint 代理中，但未看到预期的行为时应该如何操作。

## 流量路由或安全策略问题 {#problems-with-traffic-routing-or-security-policy}

通过 `productpage` 服务将一些请求从 `sleep` Pod 发送到 `reviews` 服务：

{{< text bash >}}
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/productpage
{{< /text >}}

将一些请求从 `sleep` Pod 发送到 `reviews` `v2` Pod：

{{< text bash >}}
$ export REVIEWS_V2_POD_IP=$(kubectl get pod -l version=v2,app=reviews -o jsonpath='{.items[0].status.podIP}')
$ kubectl exec deploy/sleep -- curl -s http://$REVIEWS_V2_POD_IP:9080/reviews/1
{{< /text >}}

到 `reviews` 服务的请求应由 `reviews-svc-waypoint` 强制执行所有 L7 策略。
到 `reviews` `v2` Pod 的请求应由 `reviews-v2-pod-waypoint` 强制执行所有 L7 策略。

1. 如果您的 L7 配置未应用，请先运行 `istioctl analyze` 以检查您的配置是否存在校验问题。

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

1. 确定哪个 waypoint 正在为您的服务或 Pod 实现 L7 配置。

    如果您的源使用服务的主机名或 IP 调用目标，请使用
    `istioctl experimental ztunnel-config service` 命令确认您的 waypoint 由目标服务所使用。
    根据早前的示例，`reviews` 服务应该使用 `reviews-svc-waypoint`，
    而 `default` 命名空间中的所有其他服务应使用 `waypoint` 命名空间。

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

    如果您的源使用 Pod IP 调用目标，请使用 `istioctl experimental ztunnel-config workload`
    命令确认您的 waypoint 由目标 Pod 所使用。
    根据早前的示例，`reviews` `v2` Pod 应使用 `reviews-v2-pod-waypoint`，
    而 `default` 命名空间中的所有其他 Pod 不应有任何 waypoint，
    因为默认情况下 [waypoint 仅处理面向服务的流量](/zh/docs/ambient/usage/waypoint/#waypoint-traffic-types)。

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

    如果 Pod 的 waypoint 一栏的值不正确，请验证您的 Pod 是否带有 `istio.io/use-waypoint` 标签，
    并且此标签的值可以处理工作负载流量的 waypoint 的名称。
    例如，如果您的 `reviews` `v2` Pod 使用的 waypoint 只能处理服务流量，
    那么您将不会看到该 Pod 使用的所有 waypoint。
    如果您的 Pod 上的 `istio.io/use-waypoint` 标签看起来正确，
    请验证您的 waypoint 的 Gateway 资源是否带有 `istio.io/waypoint-for` 的兼容值。
    对于 Pod 来说，合适的值可能是 `all` 或 `workload`。

1. 通过 `istioctl proxy-status` 命令检查 waypoint 的代理状态。

    {{< text bash >}}
    $ istioctl proxy-status
    NAME                                                CLUSTER        CDS         LDS         EDS          RDS          ECDS         ISTIOD                      VERSION
    bookinfo-gateway-istio-7c57fc4647-wjqvm.default     Kubernetes     SYNCED      SYNCED      SYNCED       SYNCED       NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    reviews-svc-waypoint-c49f9f569-b492t.default        Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    reviews-v2-pod-waypoint-7f5dbd597-7zzw7.default     Kubernetes     SYNCED      SYNCED      NOT SENT     NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    waypoint-6f7b665c89-6hppr.default                   Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
    ...
    {{< /text >}}

1. 启用 Envoy 的[访问日志](/zh/docs/tasks/observability/logs/access-log/)并在发送一些请求后检查
   waypoint 代理的日志：

    {{< text bash >}}
    $ kubectl logs deploy/waypoint
    {{< /text >}}

    如果信息不够，您可以为 waypoint 代理启用调试日志：

    {{< text bash >}}
    $ istioctl pc log deploy/waypoint --level debug
    {{< /text >}}

1.  通过 `istioctl proxy-config` 命令检查 waypoint 的 Envoy 配置，
    该命令显示与 waypoint 相关的所有信息，如集群、端点、监听器、路由和密钥：

    {{< text bash >}}
    $ istioctl proxy-config all deploy/waypoint
    {{< /text >}}

有关如何调试 Envoy 的更多信息，
请参阅[深入了解 Envoy 配置](/zh/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration)一节，
因为 waypoint 代理是基于 Envoy 的。

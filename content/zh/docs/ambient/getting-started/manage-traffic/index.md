---
title: 管理流量
description: 在 Ambient 模式下管理服务之间的流量。
weight: 5
owner: istio/wg-networking-maintainers
test: yes
---

现在您已经安装了 waypoint 代理，您将学习如何在服务之间分割流量。

## 在服务之间分割流量 {#split-traffic-between-services}

Bookinfo 应用程序有三个版本的 `reviews` 服务。
您可以在这些版本之间分配流量以测试新功能或执行 A/B 测试。

让我们配置流量路由，将 90% 的请求发送到 `reviews` v1，将 10% 的请求发送到 `reviews` v2：

{{< text syntax=bash snip_id=deploy_httproute >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
EOF
{{< /text >}}

为了确认 100 个请求的流量中大约 10% 流向 `reviews-v2`，您可以运行以下命令：

{{< text syntax=bash snip_id=test_traffic_split >}}
$ kubectl exec deploy/curl -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"
{{< /text >}}

您会注意到大多数请求都发往 `reviews-v1`。如果您在浏览器中打开 Bookinfo 应用程序并多次刷新页面，
则可以确认这一点。请注意，来自 `reviews-v1` 的请求没有任何评星，而来自 `reviews-v2` 的请求有黑色评星。

## 下一步 {#next-steps}

本节总结了 Istio 的 Ambient 模式的入门指南。
您可以继续前往[清理](/zh/docs/ambient/getting-started/cleanup)部分以删除 Istio，
或继续探索 [Ambient 模式用户指南](/zh/docs/ambient/usage/)以了解有关 Istio 特性和功能的更多信息。

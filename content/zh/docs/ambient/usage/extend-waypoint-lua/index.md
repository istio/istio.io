---
title: 使用 Lua 脚本扩展 Waypoint
description: 介绍如何通过内联 Lua 脚本扩展 Ambient 模式下的 waypoint 代理。
weight: 56
keywords: [extensibility,Lua,TrafficExtension,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio 提供了通过 [`TrafficExtension`](/zh/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/)
API 使用内联 [Lua](https://www.lua.org/) 脚本来扩展 waypoint 代理的能力。在 Ambient 模式下，
`TrafficExtension` 资源必须通过 `targetRefs` 绑定到 waypoint 代理。

## 开始之前 {#before-you-begin}

1. 按照 [Ambient 模式快速入门指南](/zh/docs/ambient/getting-started) 安装 Istio。
1. 部署 [Bookinfo 示例应用](/zh/docs/ambient/getting-started/deploy-sample-app)。
1. [将 default 命名空间加入 Ambient 网格](/zh/docs/ambient/getting-started/secure-and-visualize)。
1. 将 [curl]({{< github_tree >}}/samples/curl) 示例应用作为测试源部署：

    {{< text syntax=bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

## 在网关上使用 {#at-a-gateway}

获取网关名称：

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

创建一个 `TrafficExtension`，目标为 `bookinfo-gateway`，使用 Lua 奇偶性过滤器。该过滤器读取请求头
`x-number`，并在响应头中添加 `x-parity`，表示该值是奇数还是偶数。该值在请求处理过程中存储在动态元数据中，以便在响应阶段使用：

{{< text syntax=bash snip_id=apply_lua_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### 验证通过网关的流量 {#verify-the-traffic-via-the-gateway}

{{< text syntax=bash snip_id=test_gateway_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 4" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage" | grep x-parity
x-parity: even
{{< /text >}}

## 在 waypoint 上（针对某个命名空间内所有服务） {#at-a-waypoint-for-all-services-in-a-namespace}

### 部署 waypoint 代理 {#deploy-a-waypoint-proxy}

按照 [waypoint 部署说明](/zh/docs/ambient/usage/waypoint/#deploy-a-waypoint-proxy)
在 bookinfo 命名空间中部署 waypoint：

{{< text syntax=bash snip_id=create_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

验证流量是否能够到达服务：

{{< text syntax=bash snip_id=verify_traffic >}}
$ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

获取 waypoint 网关名称：

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

创建一个目标为 waypoint 的 `TrafficExtension`：

{{< text syntax=bash snip_id=apply_lua_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### 验证通过 waypoint 代理的流量 {#verify-the-traffic-via-the-waypoint-proxy}

{{< text syntax=bash snip_id=test_waypoint_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 7" http://productpage:9080/productpage | grep x-parity
x-parity: odd
{{< /text >}}

## 在 waypoint 上（针对特定服务） {#at-a-waypoint-for-a-specific-service}

删除命名空间级别的过滤器，并替换为仅作用于 `reviews` 服务的过滤器：

{{< text syntax=bash snip_id=remove_waypoint_parity >}}
$ kubectl delete trafficextension parity-at-waypoint
{{< /text >}}

创建一个直接针对 `reviews` 服务的 `TrafficExtension`，使过滤器仅作用于该服务的流量：

{{< text syntax=bash snip_id=apply_lua_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-for-reviews
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  match:
  - mode: SERVER
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### 验证指向服务的流量 {#verify-the-traffic-targeting-the-service}

{{< text syntax=bash snip_id=test_waypoint_service_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 3" http://reviews:9080/reviews/1 | grep x-parity
x-parity: odd
{{< /text >}}

## 清理 {#cleanup}

1. 移除 `TrafficExtension` 资源：

    {{< text syntax=bash snip_id=remove_traffic_extensions >}}
    $ kubectl delete trafficextension parity-at-gateway parity-for-reviews
    {{< /text >}}

1. 按照 [Ambient 模式卸载指南](/zh/docs/ambient/getting-started/#uninstall)移除 Istio 和示例应用。

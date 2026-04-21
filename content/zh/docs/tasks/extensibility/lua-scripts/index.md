---
title: 执行 Lua 脚本
description: 描述了如何利用内联 Lua 脚本扩展代理功能。
weight: 15
keywords: [extensibility,Lua,TrafficExtension]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio 提供了通过 [`TrafficExtension`](/zh/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/) API，
利用内联 [Lua](https://www.lua.org/) 脚本来扩展代理功能的能力。
对于简单的请求和响应转换场景，Lua 过滤器是 [WebAssembly](/zh/docs/tasks/extensibility/wasm-modules/)
的一种轻量级替代方案——脚本直接嵌入到资源配置中，并在 Envoy 代理内部执行，无需进行模块分发。

## 开始之前 {#before-you-begin}

部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用程序。

## 配置 Lua 脚本 {#configure-a-lua-script}

Lua 脚本必须定义以下函数之一或两者：

- `envoy_on_request(request_handle)`：针对每个入站请求调用
- `envoy_on_response(response_handle)`：针对每个出站响应调用

这些句柄提供了对请求头、正文、元数据及日志的访问权限。
如需完整的 API 详情，请参阅 [Envoy Lua 过滤器文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter)。

在此示例中，您将向入口网关添加一个 Lua 过滤器，该过滤器读取 `x-number` 请求头，
并返回一个 `x-parity` 响应头，以指示该数值是“奇数”（odd）还是“偶数”（even）。
该数值会在请求处理阶段被读取并存储在动态元数据中，从而确保在写入响应头时能够对其进行访问：

{{< text syntax=bash snip_id=apply_parity >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
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

## 验证 Lua 脚本 {#verify-the-lua-script}

[确定 Ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)。

发送一个包含 `x-number` 标头的请求，并验证响应中是否设置了 `x-parity`。

{{< text syntax=bash snip_id=verify_parity_even >}}
$ curl -s -o /dev/null -D - -H "x-number: 42" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
x-parity: even
{{< /text >}}

{{< text syntax=bash snip_id=verify_parity_odd >}}
$ curl -s -o /dev/null -D - -H "x-number: 7" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
x-parity: odd
{{< /text >}}

## 排序与范围界定 {#ordering-and-scoping}

当多个 `TrafficExtension` 资源指向同一工作负载时，
其执行顺序由 `phase` 和 `priority` 控制。

- **`phase`** 用于设定过滤器链中的大致位置：`AUTHN`、`AUTHZ` 或 `STATS`。
  未指定阶段的扩展将被插入到链的末端附近，即路由器之前。
- **`priority`** 用于在同一阶段内解决优先级冲突。数值越大，执行顺序越靠前。

`match` 字段通过模式和端口，将 `Traffic Extension` 限制于特定的流量。

{{< text yaml >}}
spec:
  match:
  - mode: SERVER
    ports:
    - number: 8080
{{< /text >}}

有效的模式包括 `CLIENT`（出站）、`SERVER`（入站）以及 `CLIENT_AND_SERVER`（双向，默认值）。

## 清理 {#clean-up}

{{< text syntax=bash snip_id=clean_up >}}
$ kubectl delete trafficextension -n istio-system parity
{{< /text >}}

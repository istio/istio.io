---
title: "介绍 TrafficExtension API"
description: 为 Istio 中的 Envoy 代理提供了一个新的统一 API，支持 WebAssembly 和 Lua，同时支持 Sidecar 模式和 Ambient 模式。
publishdate: 2026-05-18
attribution: "Liam White; Translated by Wilson Wu (DaoCloud)"
keywords: [istio, wasm, lua, extensibility, ambient, traffic extension]
target_release: "1.30"
---

网格可扩展性一直是 Istio 设计的核心原则。通过允许用户将自定义逻辑直接注入数据平面，
Istio 支持各种用例，例如执行自定义身份验证、收集专用遥测数据或动态转换请求和响应。

此前，Istio 唯一支持的扩展 API 是 `WasmPlugin`，它用于支持基于 WebAssembly 的扩展。
想要使用 Lua 脚本的用户只能通过 `EnvoyFilter` 间接实现，这是一个功能强大但容易配置错误的底层机制。

Istio 1.30 引入了 `TrafficExtension` API——一个统一的 API，
用于配置基于 Envoy 的 Sidecar、网关和路点的 Wasm 和 Lua 扩展。

## TrafficExtension 是什么？ {#what-is-trafficextension}

`TrafficExtension` 是 Istio 的一项新 API，它取代了 `WasmPlugin`，
成为主要的代理扩展机制。它支持两种扩展类型：

- **Lua 脚本** — 直接嵌入资源中的内联 Lua 脚本，在 Envoy 中执行，无需模块分发。
  最适合简单的头部操作、日志记录和条件逻辑。仅适用于第 7 层（HTTP）流量。
- **WebAssembly 插件** — 从 OCI 镜像仓库动态加载的 Proxy-Wasm 沙箱模块。
  支持多种语言（Go、Rust、C++、AssemblyScript），推荐用于复杂处理、策略执行、
  遥测数据收集和有效载荷修改。可应用于 L7（HTTP）或 L4（TCP）流量。

有关如何根据您的用例选择 Lua 或 Wasm 的详细指导，
请参阅 [TrafficExtension 概念页面](/zh/docs/concepts/extensibility/)。

## 编写扩展 {#writing-extensions}

### Lua

Lua 脚本是内联编写的。以下示例读取一个 `x-number` 请求头，
计算该值是偶数还是奇数，并添加一个 `x-parity` 响应头：

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
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
{{< /text >}}

### WebAssembly

Wasm 模块从 OCI 注册表加载。以下示例使用预构建的 Wasm 插件对 `/productpage` 路径应用基本身份验证：

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods: ["GET", "POST"]
          credentials: ["ok:test"]
{{< /text >}}

预构建的 Wasm 扩展程序可在 [Istio 生态系统仓库](https://github.com/istio-ecosystem/wasm-extensions)中找到。
要构建自己的扩展程序，请参阅 [Proxy-Wasm SDK](https://github.com/proxy-wasm)。

## 目标 {#targeting}

`TrafficExtension` 支持两种目标定位机制，分别适用于不同的部署模式。

**`selector`** 使用标签选择器来指定边车代理。在 `istio-system` 中创建的资源适用于整个集群；
而任何其他命名空间中的资源仅适用于该命名空间中的工作负载。Ambient 模式下的路径点代理所必需的，
因为 Ambient 模式路径点代理不使用基于标签的选择器来映射到工作负载。应用于 Ambient 网关的相同 `basic-auth` 扩展如下所示：

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods: ["GET", "POST"]
          credentials: ["ok:test"]
{{< /text >}}

## 扩展程序顺序 {#ordering-extensions}

当多个扩展程序针对同一个代理时，`phase` 和 `priority` 控制执行顺序。

`phase` 将扩展程序放置在滤波器链中的已知位置：

| 阶段 | 位置 |
|-------|----------|
| `AUTHN` | 认证阶段 |
| `AUTHZ` | 授权阶段 |
| `STATS` | 统计/可观测性阶段 |
| *(未设置)* | 靠近路由器（默认） |

在同一阶段内，`priority` 用于打破平局——优先级越高，请求路径中的优先级就越高。

## 从 WasmPlugin 迁移 {#migrating-from-wasmplugin}

`TrafficExtension` 取代 `WasmPlugin` 成为推荐的扩展 API。现有的 `WasmPlugin` 资源与新 API 完全兼容——事实上，
Istio 现在会在生成要分发给 Envoy 的配置之前，将所有 `WasmPlugin` 资源内部转换为 `TrafficExtension` 资源。

Istio 1.30 中没有强制迁移。当您准备迁移时，
[TrafficExtension API 参考](/zh/docs/reference/config/proxy_extensions/traffic_extension/)文档中提供了完整的规范。

## 开始使用 {#get-started}

- [TrafficExtension 概念](/zh/docs/concepts/extensibility/) — 扩展类型、目标和顺序详解
- [执行 WebAssembly 模块](/zh/docs/tasks/extensibility/wasm-modules/) — Sidecar 部署的分步任务
- [执行 Lua 脚本](/zh/docs/tasks/extensibility/lua-scripts/) — Sidecar 部署的分步任务
- [使用 WebAssembly 扩展路点](/zh/docs/ambient/usage/extend-waypoint-wasm/) — Ambient 模式指南
- [使用 Lua 扩展路点](/zh/docs/ambient/usage/extend-waypoint-lua/) — Ambient 模式指南

## 社区 {#community}

`TrafficExtension` 目前仍处于 Alpha 测试阶段，您的反馈将直接影响 API 的最终版本。
如果您遇到问题或有任何建议，请[在 GitHub 上提交 Issue](https://github.com/istio/istio/issues)或加入
[Istio Slack](https://slack.istio.io/) 参与讨论。我们非常希望了解您如何在部署中使用代理扩展。

准备好参与了吗？访问 Istio 的[社区页面](/zh/get-involved/)。

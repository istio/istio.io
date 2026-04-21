---
title: WebAssembly 模块执行
description: 描述如何在网格中使用远程 WebAssembly 模块。
weight: 10
aliases:
  - /zh/docs/tasks/extensibility/wasm-module-distribution/
  - /zh/help/ops/extensibility/distribute-remote-wasm-module
  - /zh/docs/ops/extensibility/distribute-remote-wasm-module
  - /zh/ops/configuration/extensibility/wasm-module-distribution
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio 提供了使用 [WebAssembly（Wasm）](/zh/docs/concepts/extensibility/trafficextension/))扩展代理功能的能力。
Wasm 可扩展性的关键优势之一是扩展可以在运行时动态加载。
这些扩展必须首先分发到 Envoy 代理。
Istio 通过允许代理动态下载 Wasm 模块来实现这一点。

## 开始之前 {#before-you-begin}

部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用程序。

## 配置一个 Wasm 模块 {#configure-wasm-modules}

在本示例中，您将向服务网格添加一个 HTTP Basic Auth 扩展。
您将配置 Istio，使其从远程镜像仓库拉取
[Basic Auth 模块](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)并将其加载。
该模块将被配置为在处理对 `/productpage` 的调用时运行。

为了配置一个具有远程 Wasm 模块的 WebAssembly 过滤器，
创建一个 `TrafficExtension` 资源：

{{< text bash >}}
$ kubectl apply -f - <<EOF
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
          request_methods:
            - "GET"
            - "POST"
          credentials:
            - "ok:test"
            - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

一个 HTTP 过滤器将被注入到入口网关代理中，作为身份验证过滤器。
Istio 代理将解析 `TrafficExtension` 配置，从 OCI 镜像仓库下载远程 Wasm 模块至本地文件，
并通过引用该文件将该 HTTP 过滤器注入到 Envoy 中。

{{< idea >}}
如果 `TrafficExtension` 资源是在 `istio-system` 以外的特定命名空间中创建的，
则该命名空间内的 Pod 将被配置。如果该资源是在 `istio-system` 命名空间中创建的，
则所有命名空间都将受到影响。
{{< /idea >}}

## 验证 Wasm 模块 {#verify-the-wasm-module}

[确定 Ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)。

1. 不带凭据测试 `/productpage`：

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    401
    {{< /text >}}

1. 带凭据测试 `/productpage`：

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    200
    {{< /text >}}

## 排序与范围界定 {#ordering-and-scoping}

- **`phase`** 用于设定过滤器链中的大致位置：`AUTHN`、`AUTHZ` 或 `STATS`。
  未指定阶段的扩展将被插入到链的末端附近，即路由器之前。
- **`priority`** 用于在同一阶段内解决优先级冲突。数值越大，执行顺序越靠前。

`match` 字段通过模式和端口，将 `Traffic Extension` 限制于特定的流量。

{{< text yaml >}}
spec:
  match:
  - mode: CLIENT
    ports:
    - number: 8080
{{< /text >}}

有效的模式包括 `CLIENT`（出站）、`SERVER`（入站）以及 `CLIENT_AND_SERVER`（双向，默认值）。

## 清理 {#clean-up}

{{< text bash >}}
$ kubectl delete trafficextension -n istio-system basic-auth
{{< /text >}}

## 监控 Wasm 模块分发 {#monitor-wasm-module-distribution}

以下统计数据由 Istio 代理收集：

- `istio_agent_wasm_cache_lookup_count`：Wasm 远程获取缓存查找的次数。
- `istio_agent_wasm_cache_entries`：Wasm 配置转换和结果的数量，
  包括成功、没有远程加载、编组失败、远程获取失败和未收到远程获取提示。
- `istio_agent_wasm_config_conversion_duration_bucket`：istio 代理在 Wasm 模块的配置转换上花费的总时间（以毫秒为单位）。
- `istio_agent_wasm_remote_fetch_count`: Wasm 远程获取和结果的数量，
  包括成功、下载失败和校验和不匹配。

如果由于下载失败或其他原因而拒绝了 Wasm 过滤器配置，
则 istiod 也会发出带有类型标签 `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`
的 `pilot_total_xds_rejects` 。

## 开发 Wasm 扩展 {#develop-a-wasm-extension}

要了解关于 Wasm 模块开发的更多信息，请参阅
[`istio-ecosystem/wasm-extensions` 存储库](https://github.com/istio-ecosystem/wasm-extensions)中提供的那些指南，
这个存储库由 Istio 社区维护，用于开发 Istio 的 Telemetry Wasm 扩展：

- [使用 C++ 编写、测试、部署和维护 Wasm 扩展](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
- [构建与 Istio Wasm 插件兼容的 OCI 镜像](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md)
- [为 C++ Wasm 扩展编写单元测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
- [为 Wasm 扩展编写集成测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)

有关该 API 的更多详情，请参阅 [`TrafficExtension` 参考文档](/zh/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/)。

## 限制 {#limitations}

此模块的分发机制有一些已知的限制，将在未来的版本中解决：

- 仅支持 HTTP 过滤器。

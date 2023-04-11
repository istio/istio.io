---
title: WebAssembly 模块分发
description: 描述如何在网格中使用远程 WebAssembly 模块。
weight: 10
aliases:
  - /zh/help/ops/extensibility/distribute-remote-wasm-module
  - /zh/docs/ops/extensibility/distribute-remote-wasm-module
  - /zh/ops/configuration/extensibility/wasm-module-distribution
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio 提供了[使用 WebAssembly（Wasm）扩展代理功能](/zh/blog/2020/wasm-announce/)的能力。
Wasm 可扩展性的关键优势之一是扩展可以在运行时动态加载。
这些扩展必须首先分发到 Envoy 代理。
Istio 通过允许代理动态下载 Wasm 模块来实现这一点。

## 安装测试应用程序{#setup-the-test-application}

在您开始这项任务之前，请部署[Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application)示例应用程序。

## 配置 Wasm 模块{#configure-wasm-modules}

在这个例子中，您将在您的网格中添加一个 HTTP Basic 身份验证扩展。
您将配置 Istio 从远程镜像仓库中提取并加载[基本身份验证模块](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)。
该模块将被配置为在调用到 `/productpage` 时运行。

为了配置一个具有远程 Wasm 模块的 WebAssembly 过滤器，
创建一个 `WasmPlugin` 资源：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
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

HTTP 过滤器将作为身份验证过滤器注入到入口网关代理中。
Istio 代理将解释 `WasmPlugin` 配置，从 OCI 镜像仓库中下载远程
Wasm 模块到本地文件，并通过引用该文件将 HTTP 过滤器注入 Envoy 中。

{{< idea >}}
如果在 `istio-system` 之外的特定命名空间中创建了 `WasmPlugin`，
则该命名空间中的 Pod 将被配置。如果在 `istio-system` 命名空间中创建资源，
所有命名空间都会受到影响。
{{< /idea >}}

## 检查配置的 Wasm 模块{#check-the-configured-wasm-module}

1. 不带凭据测试 `/productpage`

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    401
    {{< /text >}}

1. 带凭据测试 `/productpage`

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    200
    {{< /text >}}

关于 `WasmPlugin` API 的更多使用示例，请查看
[API 参考](/zh/docs/reference/config/proxy_extensions/wasm-plugin/)。

## 清理 Wasm 模块{#clean-up-wasm-modules}

{{< text bash >}}
$ kubectl delete wasmplugins.extensions.istio.io -n istio-system basic-auth
{{< /text >}}

## 监控 Wasm 模块分发{#monitor-wasm-module-distribution}

有几个统计数据可以跟踪远程 Wasm 模块的分发状态。

Istio 代理收集以下统计信息：

- `istio_agent_wasm_cache_lookup_count`: Wasm 远程获取缓存查找的次数。
- `istio_agent_wasm_cache_entries`: Wasm 配置转换和结果的数量，
  包括成功、没有远程加载、编组失败、远程获取失败和未收到远程获取提示。
- `istio_agent_wasm_config_conversion_duration_bucket`: istio-agent
  在 Wasm 模块的配置转换上花费的总时间（以毫秒为单位）。
- `istio_agent_wasm_remote_fetch_count`: Wasm 远程获取和结果的数量，
  包括成功、下载失败和校验和不匹配。

如果由于下载失败或其他原因而拒绝了 Wasm 过滤器配置，
则 istiod 也会发出带有类型标签 `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`
的 `pilot_total_xds_rejects` 。

## 开发 Wasm 扩展{#develop-a-wasm-extension}

要了解关于 Wasm 模块开发的更多信息，请参阅
[`istio-ecosystem/wasm-extensions` 存储库](https://github.com/istio-ecosystem/wasm-extensions)中提供的那些指南，
这个存储库由 Istio 社区维护，用于开发 Istio 的 Telemetry Wasm 扩展：

- [使用 C++ 编写、测试、部署和维护 Wasm 扩展](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
- [构建与 Istio Wasm 插件兼容的 OCI 镜像](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md)
- [为 C++ Wasm 扩展编写单元测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
- [为 Wasm 扩展编写集成测试](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)

## 限制{#limitations}

此模块的分发机制有一些已知的限制，将在未来的版本中解决：

- 仅支持 HTTP 过滤器。

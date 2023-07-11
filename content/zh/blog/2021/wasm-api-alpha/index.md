---
title: WebAssembly 插件 Alpha 版可用性公告
description: 介绍新的 Wasm 插件 API 以及 Envoy 和 Istio 中基于 Wasm 的插件支持的更新。
publishdate: 2021-12-16
attribution: "Daniel Grimm (Red Hat), Pengyuan Bian (Google), Takeshi Yoneda (Tetrate); Translated by Wilson Wu (DaoCloud)"

keywords: [wasm,extensibility,WebAssembly]
---

[在 Istio 1.9 中引入了](../wasm-progress/)对
WebAssembly（Wasm）模块分发以及 Wasm 扩展生态系统库的实验性支持，
其中包含用于开发扩展程序的规范示例以及相关用例内容。在过去的 9 个月里，
经过 Istio、Envoy 和 Proxy-Wasm 社区共同努力，将 Wasm
可扩展性推进到稳定、可靠且易于使用的程度，我们很高兴地宣布
Istio 1.12 中对 Wasm 可扩展性提供 Alpha 支持！在接下来的内容中，
我们将逐步介绍 1.12 版中针对 Wasm 支持所做的更新。

## 新的 WasmPlugin API {#new-wasmplugin-api}

通过 `extensions.istio.io` 命名空间中的新 `WasmPlugin` CRD，
我们引入了一个用于自定义 Wasm 模块对 Istio 代理功能进行扩展的新顶层 API。
这项出色的工作归功于过去两年 [Proxy-Wasm](https://github.com/proxy-wasm)
社区出色的规范和实施基础。从现在开始，您不再需要使用 `EnvoyFilter`
资源向代理添加自定义 Wasm 模块。取而代之的是使用 `WasmPlugin` 资源：

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: your-filter
spec:
  selector:
    matchLabels:
      app: server
  phase: AUTHN
  priority: 10
  pluginConfig:
    someSetting: true
    someOtherSetting: false
    youNameIt:
    - first
    - second
  url: docker.io/your-org/your-filter:1.0.0
{{< /text >}}

`WasmPlugin` 和 `EnvoyFilter` 之间有不少相似的地方，
但也存在一些不同之处，因此，让我们对这些字段逐一进行分析。

在上面的示例中是将 Wasm 模块部署到与 `selector` 字段匹配的所有工作负载
（包括网关 Pod） —— 这与 `EnvoyFilter` 的工作原理完全相同。

接下来的字段是 `phase`。该字段决定了 Wasm
模块将被注入到代理过滤器链中的哪个位置。我们为其定义了四个不同的阶段：

* `AUTHN`：在所有 Istio 身份验证和授权过滤器之前。
* `AUTHZ`：在 Istio 身份验证过滤器之后以及所有一级授权过滤器之前，
  即：应用于 `AuthorizationPolicy` 资源之前。
* `STATS`：在所有授权过滤器之后，以及 Istio 统计过滤器之前。
* `UNSPECIFIED_PHASE`：让控制平面决定注入的位置。通常位于过滤器链的末端，
  也就是在路由之前。这也是该 `phase` 字段的默认值。

`pluginConfig` 字段用于 Wasm 插件的具体配置。
在此字段中输入的任何内容都将通过 JSON 格式进行编码并传递到您的过滤器中，
您可以在 Proxy-Wasm SDK 的配置回调中访问它。例如，您可以使用
[C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/fd0be8405db25de0264bdb78fae3a82668c03782/proxy_wasm_api.h#L329-L331)
中的 `onConfigure`、[Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk/blob/v0.1.4/src/dispatcher.rs#L255)
中的 `on_configure` 或 [Go SDK](https://github.com/tetratelabs/proxy-wasm-go-sdk/blob/v0.15.0/proxywasm/types/context.go#L74)
中的 `OnPluginStart` 回调对这些配置进行检索。

`url` 字段指定了 Wasm 模块的拉取位置。请注意本示例中的 `url`
是一个 docker URI。除了通过 HTTP、HTTPS 和本地文件系统
（使用 file://）方式加载 Wasm 模块之外，我们还引入了
OCI 镜像格式作为分发 Wasm 模块的首推机制。

最后要注意的一件事是，目前 Wasm 插件 API 仅适用于入站 HTTP 过滤器链。
未来将添加对网络过滤器和出站流量的支持。

## Wasm 镜像规范 {#wasm-image-specification}

我们相信通过容器来存储、发布和管理代理扩展是一个理想的方式，
因此我们与 Solo.io 合作，在与所有仓库和 CLI
工具链兼容的情况下扩展其现有的 Proxy-Wasm 容器格式。
基于您的流程，现在可以使用现有的容器 CLI 工具（例如 Docker CLI
或 [buildah](https://buildah.io/)）构建代理扩展容器。

如需了解如何构建 OCI 镜像，请参阅[这些说明内容（英文）](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md)。

## Istio 代理中的镜像获取器 {#image-fetcher-in-istio-agent}

从 Istio 1.9 开始，Istio-agent 提供了一个用于加载 Wasm
二进制文件的可靠解决方案，利用 istio-agent 内的 xDS 代理和 Envoy
的扩展配置发现服务（ECDS），通过 `EnvoyFilter` 中的配置获取远程 HTTP 源。
相同的机制也适用于 Istio 1.12 中新的 Wasm API 实现。
您可以放心地使用 HTTP 远程资源，不必为远程资源获取失败时 Envoy
可能会因为错误配置陷入困境而担心。

此外，在 Istio 1.12 中，该功能也已在 Wasm OCI 镜像实现兼容。
这意味着 Istio-agent 现在可以从任何 OCI 仓库获取 Wasm 镜像，包括
Docker Hub、Google Container Registry（GCR）、
Amazon Elastic Container Registry（Amazon ECR）等。
获取镜像后，Istio-agent 会从二进制中提取并缓存 Wasm 文件，
然后将它们插入 Envoy 过滤器链中。

{{< image width="75%"
    link="./istio-agent-architecture.svg"
    alt="远程 Wasm 模块获取流程"
    caption="远程 Wasm 模块获取流程"
    >}}

## Envoy Wasm 运行时的改进 {#improvements-in-envoy-wasm-runtime}

在 Envoy 中，通过 V8 引擎对 Wasm 运行时提供支持，自从 Istio 1.5
版开始该功能就已发布，而且在此后版本中已经进行了很多改进。

### WASI 支持 {#wasi-supports}

首先，目前已经对一些 WASI（WebAssembly 系统接口）系统调用进行了支持。
例如，可以在 Wasm 程序中使用 `clock_time_get` 系统调用，
因此，就像任何其他原生平台一样，您可以在 Envoy Wasm 扩展中使用
Rust 语言中的 `std::time::SystemTime::now()` 或 Go 语言中的
`time.Now().UnixNano()`。另一个例子是 Envoy 现在可以支持 `random_get` 操作，
因此 Go 语言中可以使用“crypto/rand”包作为加密安全随机数生成器。
另外我们已经看到在 Envoy 中运行的 Wasm 程序读取和写入本地文件的需求，
因此，目前也在基于其对文件系统的支持进行研究。

### 可调试性 {#debuggability}

接下来是针对可调试性的改进。目前，当 Envoy 运行时遇到错误的时候，
程序将产生堆栈跟踪信息，例如，在 C++ 语言中发生空指针异常，
在 Go 或 Rust 语言中调用函数时发生 Panic。相比之前 Envoy
错误消息缺失相关信息的情况，目前这些信息已经被展示并且可用于程序调试：

{{< text plain >}}
Function: proxy_on_request_headers failed: Uncaught RuntimeError: unreachable
Proxy-Wasm plugin in-VM backtrace:
  0:  0xdbd - runtime._panic
  1:  0x103ab - main.anotherCalculation
  2:  0x10399 - main.someCalculation
  3:  0xea57 - main.myHeaderHandler
  4:  0xea15 - proxy_on_request_headers
{{< /text >}}

上面是基于 Go SDK Wasm 扩展的示例堆栈跟踪信息。
您可能会注意到输出在跟踪信息中的内容不包括任何文件名和行序号。
这也是一个与 WebAssembly 的 DWARF 格式以及 WebAssembly
异常处理规范提案相关的未解决问题，以及未来的重点工作内容。

### Wasm 程序对 Strace 的支持 {#strace-support-for-wasm-programs}

您可以看到 Envoy 产生的 `strace` 等效日志。通过使用 Istio
代理组件的 `wasm:trace` 日志级别，您可以观察到横跨 Wasm 虚拟机和
Envoy 之间的所有系统调用和 Proxy-Wasm ABI 调用内容。
下面是此类 `strace` 日志流的示例：

{{< text plain >}}
[host->vm] proxy_on_context_create(2, 1)
[host<-vm] proxy_on_context_create return: void
[host->vm] proxy_on_request_headers(2, 8, 1)
[vm->host] wasi_snapshot_preview1.random_get(86928, 32)
[vm<-host] wasi_snapshot_preview1.random_get return: 0
[vm->host] env.proxy_log(2, 87776, 18)
{{< /text >}}

这对于在运行时调试 Wasm 程序的执行特别有用，比如，验证其是否存在恶意系统调用操作。

### 在任意 Prometheus 命名空间中的内置 Wasm 指标 {#arbitrary-prometheus-namespace-for-in-wasm-metrics}

最后一项更新是关于指标的。Wasm 扩展已经能够像其他任何指标一样，
定义自己的自定义指标并将其暴露在 Envoy 中，但在 Istio 1.12 之前，
所有这些自定义指标都需要以 `envoy_` Prometheus 命名空间名称为前缀，
用户无法使用他们自己的命名空间进行命名。而现在，您可以选择所需的任何命名空间，
您的指标将按原样在 Envoy 中暴露，而不会再带有 `envoy_` 前缀。

请注意，为了真实的暴露这些自定义指标，您必须在 `meshConfig` 中使用
[`ProxyConfig.proxyStatsMatcher`](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig-ProxyStatsMatcher)
进行全局配置，或使用 `proxy.istio.io/config` 针对每个代理进行配置。
有关详细信息，请参阅 [`Envoy Statistics`](/zh/docs/ops/configuration/telemetry/envoy-stats/)。

## 后续的工作以及期待反馈 {#future-work-and-looking-for-feedback}

尽管我们已经发布了 Wasm 插件的 Alpha 版本，但仍有很多工作要做。
其中一个重要的工作内容是在 Wasm API 中支持“镜像拉取 Secret”，
这将允许您轻松使用私有仓库中的 OCI 镜像。其他工作还包括对 L4
过滤器的推荐支持、Wasm 二进制文件的签名验证、Envoy 中的运行时改进、
Proxy-Wasm SDK 改进、文档等内容。

这只是我们在 Istio 中提供推荐 Wasm 支持计划的开始。
我们很乐意听到您的反馈，用于在 Istio 未来版本中改善 Wasm 插件开发人员的使用体验！

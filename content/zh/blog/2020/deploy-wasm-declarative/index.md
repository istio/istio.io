---
title: 在 Istio 中进行 WebAssembly 声明式部署
subtitle: 使用声明式模型将扩展部署到 Istio 中的 Envoy ，以与 GitOps 工作流保持一致
description: 以声明方式为 Envoy 和 Istio 配置 Wasm 扩展。
publishdate: 2020-03-16
attribution: "Christian Posta (Solo.io)"
keywords: [wasm,extensibility,alpha,operator]
---

正如 [Istio 2020——为了商用](/zh/blog/2020/tradewinds-2020/)以及最近的 [Istio 1.5 发布公告](/zh/news/releases/1.5.x/announcing-1.5/)中指出的那样，WebAssembly (Wasm) 现在是用于扩展 Istio 服务代理（ Envoy 代理）功能的（alpha）选项。使用 Wasm，用户可以建立对新协议、自定义指标、日志和其他过滤器的支持。我们的社区（[Solo.io](https://solo.io)) 与 Google 紧密合作，专注于提升为 Istio 构建、交流和部署 Wasm 扩展的用户体验。我们发布了 [WebAssembly Hub](https://webassemblyhub.io) 和[相关工具](https://docs.solo.io/web-assembly-hub/latest/installation/)，以便在使用 Wasm 时可以获得“类似 docker ”的体验。

## 背景{#background}

借助 WebAssembly Hub 工具，我们可以使用 `wasme` CLI 轻松为 Envoy 创建一个 Wasm 项目，将其推送到存储库，然后将其提取或部署到 Istio。例如，要使用 `wasme` 将 Wasm 扩展部署到 Istio，我们可以运行以下命令：

{{< text bash >}}
$  wasme deploy istio webassemblyhub.io/ceposta/demo-add-header:v0.2 \
  --id=myfilter \
  --namespace=bookinfo \
  --config 'tomorrow'
{{< /text >}}

这会将 `demo-add-header` 扩展添加到在 `bookinfo` 命名空间中运行的所有工作负载中。我们可以通过使用 `--labels` 参数来更精细地控制哪些工作负载获得扩展：

{{< text bash >}}
$  wasme deploy istio webassemblyhub.io/ceposta/demo-add-header:v0.2 \
  --id=myfilter  \
  --namespace=bookinfo  \
  --config 'tomorrow' \
  --labels app=details
{{< /text >}}

这比手动创建 `EnvoyFilter` 资源并尝试将 Wasm 模块发送到每个 pod（您的目标工作负载的一部分）要容易得多。不管怎么说，这是与 Istio 进行交互的非常必要的方法。就像用户通常不直接在生产环境中使用 `kubectl` ，而是喜欢声明式的、基于资源的工作流一样，我们也希望对 Istio 代理进行自定义。

## 声明式方法{#a-declarative-approach}

WebAssembly Hub 工具还包括[用于将 Wasm 扩展部署到 Istio 工作负载的 Operator](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/wasme_operator/)。[Operator](https://kubernetes.io/zh-cn/docs/concepts/extend-kubernetes/operator/) 允许用户使用声明式的格式定义其 WebAssembly 扩展，
并将其交给 Operator 以修正部署状态。例如，我们使用 `FilterDeployment` 资源来定义需要扩展的镜像和工作负载：

{{< text yaml >}}
apiVersion: wasme.io/v1
kind: FilterDeployment
metadata:
  name: bookinfo-custom-filter
  namespace: bookinfo
spec:
  deployment:
    istio:
      kind: Deployment
      labels:
        app: details
  filter:
    config: 'world'
    image: webassemblyhub.io/ceposta/demo-add-header:v0.2
{{< /text >}}

然后，我们可以获取这个 `FilterDeployment` 文档，并使用其余的 Istio 资源对其进行版本控制。您可能想知道在 Istio 已经具有 `EnvoyFilter` 资源的情况下，为什么还需要这个自定义资源来配置 Istio 的服务代理以使用 Wasm 扩展。

让我们来看看所有这一切在幕后的工作原理。

## 工作原理{#how-it-works}

在后台，operator 正在做一些有助于将 Wasm 扩展部署和配置到 Istio 服务代理（ Envoy 代理）中的事情。

- 设置 Wasm 扩展的本地缓存
- 将所需的 Wasm 扩展提取到本地缓存中
- 将 `wasm-cache` 挂载到适当的工作负载中
- 使用 `EnvoyFilter` CRD 配置 Envoy 以使用 Wasm 过滤器

{{< image width="75%"
    link="./how-it-works.png"
    alt="wasme operator 工作原理"
    caption="理解 wasme operator 的工作原理"
    >}}

目前，Wasm 镜像需要发布到一个 registry 中，以便 operator 能够正确缓存它。缓存 pod 作为 DaemonSet 运行在每个节点上，以便可以将缓存挂载到 Envoy 容器中。它并不是最理想的机制，我们正在对其进行改进。理想情况下，我们无需处理任何挂载，而是可以直接通过 HTTP 将模块流式传输到代理，因此请随时关注更新（应在接下来的几天内完成）。使用 `sidecar.istio.io/userVolume` 和 `sidecar.istio.io/userVolumeMount` 注释后，挂载将会建立。有关其工作原理的更多信息，请参见[有关 Istio 资源注释的文档](/zh/docs/reference/config/annotations/)。

一旦 Wasm 模块被正确缓存并挂载入工作负载的服务代理中，operator 即可配置 `EnvoyFilter` 资源。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: details-v1-myfilter
  namespace: bookinfo
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        filterChain:
          filter:
            name: envoy.http_connection_manager
            subFilter:
              name: envoy.router
    patch:
      operation: INSERT_BEFORE
      value:
        config:
          config:
            configuration: tomorrow
            name: myfilter
            rootId: add_header
            vmConfig:
              code:
                local:
                  filename: /var/local/lib/wasme-cache/44bf95b368e78fafb663020b43cf099b23fc6032814653f2f47e4d20643e7267
              runtime: envoy.wasm.runtime.v8
              vmId: myfilter
        name: envoy.filters.http.wasm
  workloadSelector:
    labels:
      app: details
      version: v1
{{< /text >}}

您可以看到 `EnvoyFilter` 资源配置了代理以添加 `envoy.filter.http.wasm` 过滤器并从 `wasme-cache` 加载 Wasm 模块。

一旦将 Wasm 扩展加载到 Istio 服务代理，它将使用您引入的任意自定义代码来扩展代理的功能。

## 下一步{#next-steps}

在此博客中，我们探讨了将 Wasm 扩展安装到 Istio 工作负载中的选项。在 Istio 上开始使用 WebAssembly 的最简单方法是使用 `wasme` 工具[创建一个新的 Wasm 项目](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/getting_started/)，可使用 C++，AssemblyScript [或即将推出的 Rust！]。例如，要设置 C++ Wasm 模块，可以运行：

{{< text bash >}}
$ wasme init ./filter --language cpp --platform istio --platform-version 1.5.x
{{< /text >}}

如果没有额外的参数，则 `wasme init` 将进入交互模式，引导您选择正确的值。

查看 [WebAssembly Hub wasme 工具](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/getting_started/)，以在 Istio 上开始使用 Wasm。

## 了解更多{#learn-more}

-   [重新定义代理的扩展性](/zh/blog/2020/wasm-announce/)

-   WebAssembly SF talk (video): [网络代理的扩展](https://www.youtube.com/watch?v=OIUPf8m7CGA), by John Plevyak

-   [Solo 博客](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)

-   [Proxy-Wasm ABI 规范](https://github.com/proxy-wasm/spec)

-   [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/master/docs/wasm_filter.md) 以及 [开发者文档](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/master/docs/wasm_filter.md)

-   [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)

-   [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)

-   [教程](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)

-   [Solo.io 的 YouTube 频道](https://www.youtube.com/channel/UCuketWAG3WqYjjxtQ9Q8ApQ)里的视频

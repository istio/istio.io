---
title: "在 Istio 中使用 MOSN：另一个数据平面"
subtitle: "用于边缘或服务网格的云原生代理"
description: "Istio 的另一个 Sidecar 代理。"
publishdate: 2020-07-29
attribution: "王发康 (mosn.io)"
keywords: [mosn,sidecar,proxy]
---

MOSN（Modular Open Smart Network）是用 Go 编写的网络代理服务器。它是 [蚂蚁集团](https://www.antfin.com/) 为 Sidecar、API Gateway、云原生 Ingress、Layer 4 或 Layer 7 负载均衡器等场景构建的。随着时间的推移，我们添加了额外的功能，例如多协议框架，多进程插件机制，DSL 和对 [xDS API](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol) 的支持。支持 xDS 意味着我们现在可以将 MOSN 用作 Istio 的数据平面。Istio 项目不支持此配置。如需帮助，请参阅下面的[了解更多](#了解更多)。

## 背景

在 Service Mesh 领域，使用 Istio 作为控制平面已成为主流。由于 Istio 的数据面默认是基于 Envoy 构建的，因此它使用了 Envoy 的数据平面 API（统称为 xDS API）。这些 API 已与 Envoy 分开并进行了标准化，因此，通过在 MOSN 中实现它们，我们就可以使用 MOSN 替代 Envoy。Istio 的第三方数据平面集成可以通过以下三个步骤实现：

- 实现 xDS 协议，对齐数据面相关服务治理能力;
- 使用 Istio 的脚本并设置相关 `SIDECAR` 等参数构建 `proxyv2` 镜像;
- 通过 istioctl 工具并设置 proxy 相关配置指定具体的数据面;

## MOSN 架构

MOSN 是一个分层的体系结构，其系统分为 NET/IO、Protocol、Stream、Proxy 四层，如下图所示：

{{< image width="80%"
    link="./mosn-arch.png"
    caption="MOSN 架构图"
    >}}

- NET/IO 作为网络层，监测连接和数据包的到来，同时作为 listener filter 和 network filter 的挂载点;
- Protocol 作为多协议引擎层，对数据包进行检测，并使用对应协议做 decode/encode 处理;
- Stream 对 decode 的数据包做二次封装为 stream，作为 stream filter 的挂载点;
- Proxy 作为 MOSN 的转发框架，对封装的 stream 做 proxy 处理;

## 为什么要使用 MOSN ？

蚂蚁集团在进行 Mesh 改造前，已经预料到作为下一代蚂蚁集团的基础架构，Mesh 化势必带来革命性的变革以及演进成本，我们有非常宏大的蓝图：准备将原有的网络和中间件方面的各种能力重新沉淀和打磨，打造成为未来新一代架构的底层平台，承载各种服务通讯的职责。

这是一个需要多年时间打造，满足未来五年乃至十年需求的长期规划项目，合作共建团队跨业务、SRE、中间件、基础架构等部门。我们必须有一个具备灵活扩展、高性能、满足长期演进的网络代理转发平面。Nginx、Envoy 在网络代理领域有非常长期的能力积累和活跃的社区，我们也同时借鉴了 Nginx、Envoy 等其他优秀的开源网络代理，同时在研发效率、灵活扩展等方面进行了加强，同时整个 Mesh 改造涉及到非常多的部门和研发人员，必须考虑到跨团队合作的落地成本，所以我们基于 Go 自研了云原生场景下的新型网络代理 MOSN。对于 Go 的性能，我们前期也做了充分的调研和测试，满足蚂蚁集团业务对性能的要求。

同时我们从社区用户方面收到了很多的反馈和需求，大家有同样的需求以及思考，所以我们结合社区与自身的实际情况，从满足社区以及用户角度出发进行了 MOSN 的研发工作，我们认为开源的竞争主要是标准与规范的竞争，我们需要基于开源标准做最适合自身的实现选择。

## MOSN 和 Istio 默认的 Proxy 的不同点是什么？

### 语言栈的不同

MOSN 使用 Go 语言编写，Go 语言在生产效率，内存安全上有比较强的保障，同时 Go 在云原生时代有广泛的库生态系统，性能在 Mesh 场景下我们评估以及实践是可以接受的。另外 MOSN 对于使用 Go、Java 等语言的公司和个人的心智成本更低。

### 核心能力的差异化

- MOSN 支持多协议框架，用户可以比较容易的接入私有协议，具有统一的路由框架；
- 多进程的插件机制，可以通过插件框架很方便的扩展独立 MOSN 进程的插件，做一些其他管理，旁路等的功能模块扩展；
- 具备中国密码合规的传输层国密算法支持；

### MOSN 的不足

- 由于 MOSN 是用 Go 编写的，因此它的性能不如 Istio 的默认代理（默认代理使用的是 C++ 语言），但是在服务网格场景中该性能是可以接受的并且可以使用；
- 与 Istio 默认代理相比，不完全支持某些功能，例如 WASM、HTTP3、Lua 等。但是，这些功能在 MOSN 的 [roadmap](https://docs.google.com/spreadsheets/d/1fALompY9nKZNImOuxQw23xtMD-5rCBrXWziJZkj76bo/edit?usp=sharing) 计划之中，我们的目标是和 Istio 完全兼容；

## MOSN 结合 Istio

下面介绍如何将 MOSN 设置为 Istio 的数据平面。

## 安装 Istio

您可以在 [Istio release](https://github.com/istio/istio/releases/tag/1.5.2) 页面下载与您操作系统匹配的压缩文件，该文件中包含：安装文件、示例和 istioctl 命令行工具。使用如下命令来下载 Istio（本文示例使用的是 Istio 1.5.2）：

{{< text bash >}}
$ export ISTIO_VERSION=1.5.2 && curl -L https://istio.io/downloadIstio | sh -
{{< /text >}}

下载的 Istio 包名为 `istio-1.5.2`，包含：

- `install/kubernetesi`：包含 Kubernetes 相关的 YAML 安装文件;
- `examples/`：包含示例应用程序;
- `bin/`：包含 istioctl 的客户端文件;

切换到 Istio 包所在目录：

{{< text bash >}}
$ cd istio-$ISTIO_VERSION/
{{< /text >}}

使用如下命令将 istioctl 客户端路径加入 $PATH 中：

{{< text bash >}}
$ export PATH=$PATH:$(pwd)/bin
{{< /text >}}

截止目前，我们已经可以通过 istioctl 命令行工具来灵活的自定义 Istio 控制平面和数据平面配置参数。

## 设置 MOSN 作为 Istio 的 Sidecar

通过 istioctl 命令的参数指定 MOSN 作为 Istio 中的数据面：

{{< text bash >}}
$ istioctl manifest apply  --set .values.global.proxy.image="mosnio/proxyv2:1.5.2-mosn"   --set meshConfig.defaultConfig.binaryPath="/usr/local/bin/mosn"
{{< /text >}}

检查 Istio 相关 pod 服务是否部署成功：

{{< text bash >}}
$ kubectl get svc -n istio-system
{{< /text >}}

如果服务状态 STATUS 为 Running，则表示 Istio 已经成功安装，后面就可以部署 Bookinfo 示例了。

## Bookinfo 示例

可以通过 [MOSN with Istio](https://katacoda.com/mosn/courses/istio/mosn-with-istio) 的教程来进行 Bookinfo 示例的演示操作，另外在该教程中您也可以找到更多关于使用 MOSN 和 Istio 的说明。

## 展望

接下来，MOSN 不仅会持续兼容适配新版本的 Istio 的功能，而且还将在以下几个方面进行发展：

- 作为微服务运行时，使得面向 MOSN 编程的服务更轻、更小、更快;
- 可编程，如支持 WASM;
- 更多场景 mesh 化方案支持，缓存/消息/区块链 mesh 化等;

MOSN 是一个开源项目，社区中的任何人都可以使用，参与和改进。我们希望您能加入我们！可以通过[这里](https://github.com/mosn/community)介绍的几种方式了解 MOSN 正在做的事情并参与其中。

## 了解更多

- [MOSN 官方博客](https://mosn.io)
- [MOSN 开源社区](https://mosn.io/en/docs/community/)
- [MOSN 教程](https://katacoda.com/mosn)

---
title: "基于 gRPC 的无代理服务网格"
description: 介绍 Istio 对 gRPC 无代理服务网格功能的支持。
publishdate: 2021-10-28
attribution: "Steven Landow (Google); Translated by Wilson Wu (DaoCloud)"
---

在 Istio 中，通过使用一组发现 API 对其 Envoy Sidecar 代理进行动态配置，
这组 API 统称为 [xDS API](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/dynamic_configuration)。
这些 API 也希望成为[通用数据平面 API](https://blog.envoyproxy.io/the-universal-data-plane-api-d15cec7a?gi=64aa2eea0283)。
gRPC 项目对 xDS API 提供了重要支持，这意味着您无需为其部署
Envoy Sidecar 就可以对 gRPC 工作负载进行管理。您可以在
[Megan Yahya 的 KubeCon EU 2021 演讲](https://www.youtube.com/watch?v=cGJXkZ7jiDk)中了解相关集成的更多信息。
有关 gRPC 支持的最新更新以及实施状态可以在其[提案](https://github.com/grpc/proposal/search?q=xds)中找到。

Istio 1.11 中新增了直接向网格添加 gRPC 服务的实验性支持。
我们提供基本的服务发现、一些基于 VirtualService 的流量策略以及双向 TLS 支持。

## 支持的功能 {#supported-features}

与 Envoy 相比，当前 xDS API 在 gRPC 中的实现在某些领域仍受到限制。
尽管以下功能列表并不详尽，而且某些功能可能仅包含部分实现，但这些功能都可以被正常使用：

* 基本服务发现。您的 gRPC 服务可以正常访问网格中注册的其他 Pod 和虚拟机。
* [`DestinationRule`](/zh/docs/reference/config/networking/destination-rule/)：
    * Subset：您的 gRPC 服务可以根据标签选择器将流量拆分到不同的实例组。
    * Istio 目前唯一支持的 `loadBalancer` 策略是 `ROUND_ROBIN`，
      而在 Istio 未来版本中将添加 `consistencyHash` 策略（gRPC 已经支持）。
    * `tls` 设置仅针对 `DISABLE` 或 `ISTIO_MUTUAL` 生效。其他模式下将被视为 `DISABLE`。
* [`VirtualService`](/zh/docs/reference/config/networking/virtual-service/)：
    * 头匹配和 URI 匹配格式为 `/ServiceName/RPCName`。
    * 覆盖目标主机和 Subset。
    * 基于权重的流量转移。
* [`PeerAuthentication`](/zh/docs/reference/config/security/peer_authentication/)：
    * 仅支持 `DISABLE` 和 `STRICT`。其他模式将被视为 `DISABLE`。
    * 未来版本中可能会支持自动 mTLS。

未来版本可能会支持包括：故障、重试、超时、镜像和重写规则等其他功能。
其中部分功能正在等待基于 gRPC 的实现，另外一部分功能则需要 Istio 来支持。
gRPC 中 xDS 功能的状态可以在[此处](https://github.com/grpc/grpc/blob/master/doc/grpc_xds_features.md)找到。
Istio 的相关支持状态将在未来的官方文档中发布。

{{< warning >}}
此功能是[实验性](/zh/docs/releases/feature-stages/)功能。
对应的标准 Istio 功能将随着时间推移和整体设计的改进得到支持。
{{< /warning >}}

## 架构概述 {#architecture-overview}

{{< image width="80%"
  link="./architecture.svg"
  caption="gRPC 服务与 istiod 通信架构"
  >}}

尽管进行数据平面通信时不使用代理，但进行初始化以及与控制平面通信时仍然需要通过代理实现。
首先，代理在启动时生成一个 [Bootstrap 文件](https://github.com/grpc/proposal/blob/master/A27-xds-global-load-balancing.md#xdsclient-and-bootstrap-file)，
利用同样的方式也会为 Envoy 生成引导程序。它会告诉 `gRPC`
库如何连接到 `istiod`，在哪里可以找到数据平面通信证书，
以及将哪些元数据发送到控制平面。接下来，代理将充当 `xDS` 角色，
代表应用程序与 `istiod` 进行数据转发、连接和身份验证。
最后，代理将获取并轮转数据平面流量中使用的证书。

## 修改应用程序代码 {#changes-to-application-code}

{{< tip >}}
本节内容涵盖了在 Go 语言中 gRPC 对 xDS 的支持。其他语言中也存在类似 API。
{{< /tip >}}

要在 gRPC 中启用 xDS 功能，您的应用程序必须进行一些必要的修改。
您的 gRPC 版本最低应为 `1.39.0`。

### 客户端中 {#in-the-client}

在向 gRPC 中注册 xDS 解析器和平衡器时会引发下面的副作用。
该引用应该被添加到您的 `main` 包或与调用 `grpc.Dial` 代码处于相同位置的包中。

{{< text go >}}
import _ "google.golang.org/grpc/xds"
{{< /text >}}

创建 gRPC 连接时，URL 必须使用 `xds:///` 格式。

{{< text go >}}
conn, err := grpc.DialContext(ctx, "xds:///foo.ns.svc.cluster.local:7070")
{{< /text >}}

此外，对于 (m)TLS 的支持，必须将特殊的 `TransportCredentials`
选项传递到 `DialContext` 中。在 istiod 不发送安全配置时 `FallbackCreds` 将对相关操作视为成功。

{{< text go >}}
import "google.golang.org/grpc/credentials/xds"

...

creds, err := xds.NewClientCredentials(xds.ClientOptions{
FallbackCreds: insecure.NewCredentials()
})
// handle err
conn, err := grpc.DialContext(
ctx,
"xds:///foo.ns.svc.cluster.local:7070",
grpc.WithTransportCredentials(creds),
)
{{< /text >}}

### 服务端中 {#on-the-server}

为了支持服务端的各项配置（例如 mTLS），需要进行一些必要的修改。

首先，我们使用一个特殊的构造函数来创建 `GRPCServer`：

{{< text go >}}
import "google.golang.org/grpc/xds"

...

server = xds.NewGRPCServer()
RegisterFooServer(server, &fooServerImpl)
{{< /text >}}

如果您通过 `protoc` 生成的 Go 代码已过期，可能需要重新生成来与
xDS 服务器兼容。您生成的 `RegisterFooServer` 函数应如下所示：

{{< text go >}}
func RegisterFooServer(s grpc.ServiceRegistrar, srv FooServer) {
s.RegisterService(&FooServer_ServiceDesc, srv)
}
{{< /text >}}

最后，与客户端修改一样，我们必须启用安全支持：

{{< text go >}}
creds, err := xds.NewServerCredentials(xdscreds.ServerOptions{FallbackCreds: insecure.NewCredentials()})
// handle err
server = xds.NewGRPCServer(grpc.Creds(creds))
{{< /text >}}

### 在您的 Kubernetes Deployment 中 {#in-your-kubernetes-deployment}

假设您的应用程序代码是兼容的，在 Pod 中只需要添加
`inject.istio.io/templates: grpc-agent` 注解。
该操作会为应用程序添加一个运行上述代理的 Sidecar 容器，以及一些
gRPC 用于查找引导文件并启用某些功能的环境变量。

对于 gRPC 服务器，您的 Pod 还需要添加 `proxy.istio.io/config: '{"holdApplicationUntilProxyStarts": true}'`
注解，以确保在初始化 gRPC 服务器之前其中的 xDS 代理和引导文件已准备就绪。

## 示例 {#example}

在本指南中，您将部署 `echo` 程序，它是一个已经支持服务端和客户端无代理
gRPC 的应用程序。使用此应用程序，您可以尝试一些已被支持的基于 mTLS 的流量策略。

### 先决条件 {#prerequisites}

本指南[需要安装](/zh/docs/setup/install/) Istio（1.11+）控制平面才能继续。

### 部署应用程序 {#deploy-the-application}

创建一个开启注入的命名空间 `echo-grpc`。接下来部署包含两个实例的 `echo` 应用程序及其 Service。

{{< text bash >}}
$ kubectl create namespace echo-grpc
$ kubectl label namespace echo-grpc istio-injection=enabled
$ kubectl -n echo-grpc apply -f samples/grpc-echo/grpc-echo.yaml
{{< /text >}}

确保两个 Pod 都正在运行：

{{< text bash >}}
$ kubectl -n echo-grpc get pods
NAME                       READY   STATUS    RESTARTS   AGE
echo-v1-69d6d96cb7-gpcpd   2/2     Running   0          58s
echo-v2-5c6cbf6dc7-dfhcb   2/2     Running   0          58s
{{< /text >}}

### 测试 gRPC 解析器 {#test-the-grpc-resolver}

首先，将 `17171` 端口转发到其中一个 Pod。此端口是无 xDS
支持的 gRPC 服务器，允许来自转发端口的 Pod 请求。

{{< text bash >}}
$ kubectl -n echo-grpc port-forward $(kubectl -n echo-grpc get pods -l version=v1 -ojsonpath='{.items[0].metadata.name}') 17171 &
{{< /text >}}

接下来，我们可以批量发送 5 个请求：

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc.cluster.local:7070", "count": 5}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join("")'  | grep Hostname
Handling connection for 17171
[0 body] Hostname=echo-v1-7cf5b76586-bgn6t
[1 body] Hostname=echo-v2-cf97bd94d-qf628
[2 body] Hostname=echo-v1-7cf5b76586-bgn6t
[3 body] Hostname=echo-v2-cf97bd94d-qf628
[4 body] Hostname=echo-v1-7cf5b76586-bgn6t
{{< /text >}}

针对短名称，您还可以使用类似 Kubernetes 的名称进行解析：

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join
("")'  | grep Hostname
[0 body] Hostname=echo-v1-7cf5b76586-ltr8q
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r
'.output | join("")'  | grep Hostname
[0 body] Hostname=echo-v1-7cf5b76586-ltr8q
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r
'.output | join("")'  | grep Hostname
[0 body] Hostname=echo-v2-cf97bd94d-jt5mf
{{< /text >}}

### 通过 DestinationRule 创建 Subset {#creating-subsets-with-destination-rule}

首先，为每个版本的工作负载分别创建 Subset。

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: echo-versions
  namespace: echo-grpc
spec:
  host: echo.echo-grpc.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF
{{< /text >}}

### 流量转移 {#traffic-shifting}

使用上面定义的 Subset，您可以将 80% 的流量发送到一个特定版本：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: echo-weights
  namespace: echo-grpc
spec:
  hosts:
  - echo.echo-grpc.svc.cluster.local
  http:
  - route:
    - destination:
        host: echo.echo-grpc.svc.cluster.local
        subset: v1
      weight: 20
    - destination:
        host: echo.echo-grpc.svc.cluster.local
        subset: v2
      weight: 80
EOF
{{< /text >}}

现在，发送 10 个为一组的请求：

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc.cluster.local:7070", "count": 10}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join("")'  | grep ServiceVersion
{{< /text >}}

在所有响应中，应该以 `v2` 的响应居多：

{{< text plain >}}
[0 body] ServiceVersion=v2
[1 body] ServiceVersion=v2
[2 body] ServiceVersion=v1
[3 body] ServiceVersion=v2
[4 body] ServiceVersion=v1
[5 body] ServiceVersion=v2
[6 body] ServiceVersion=v2
[7 body] ServiceVersion=v2
[8 body] ServiceVersion=v2
[9 body] ServiceVersion=v2
{{< /text >}}

### 启用 mTLS {#enabling-mtls}

由于在 gRPC 中启用安全性需要对应用程序本身进行修改，因此
Istio 自动检测 mTLS 支持的传统方法并不可靠。基于这个原因，
针对该初始版本，需要在客户端和服务端上显式启用 mTLS。

要在客户端启用 mTLS，请使用带有 `tls` 设置的 `DestinationRule` 资源：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: echo-mtls
  namespace: echo-grpc
spec:
  host: echo.echo-grpc.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

现在，尝试调用尚未配置 mTLS 的服务端将会失败。

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc.cluster.local:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join("")'
Handling connection for 17171
ERROR:
Code: Unknown
Message: 1/1 requests had errors; first error: rpc error: code = Unavailable desc = all SubConns are in TransientFailure
{{< /text >}}

需要在服务端启用 mTLS，请使用 `PeerAuthentication` 资源。

{{< warning >}}
以下策略将对整个命名空间强制开启 STRICT mTLS。
{{< /warning >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: echo-mtls
  namespace: echo-grpc
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

应用该策略后，请求将被成功发送。

{{< text bash >}}
$ grpcurl -plaintext -d '{"url": "xds:///echo.echo-grpc.svc.cluster.local:7070"}' :17171 proto.EchoTestService/ForwardEcho | jq -r '.output | join("")'
Handling connection for 17171
[0] grpcecho.Echo(&{xds:///echo.echo-grpc.svc.cluster.local:7070 map[] 0  5s false })
[0 body] x-request-id=0
[0 body] Host=echo.echo-grpc.svc.cluster.local:7070
[0 body] content-type=application/grpc
[0 body] user-agent=grpc-go/1.39.1
[0 body] StatusCode=200
[0 body] ServiceVersion=v1
[0 body] ServicePort=17070
[0 body] Cluster=
[0 body] IP=10.68.1.18
[0 body] IstioVersion=
[0 body] Echo=
[0 body] Hostname=echo-v1-7cf5b76586-z5p8l
{{< /text >}}

## 限制 {#limitations}

在该初始版本中存在一些限制，可能会在未来版本中修复：

* 不支持自动 mTLS，也不支持容忍模式。我们需要在服务端使用 `STRICT`
  以及在客户端使用 `ISTIO_MUTUAL` 进行显式 mTLS 配置。
  在迁移到 `STRICT` 期间可以使用 Envoy 过渡。
* 在写入引导程序或 xDS 代理准备就绪之前调用 `grpc.Serve(listener)`
  或 `grpc.Dial("xds:///...")` 可能会导致失败。可以使用`holdApplicationUntilProxyStarts` 来解决此问题，
  或者可以通过加固应用程序本身来应对这些问题。
* 如果启用 xDS 的 gRPC 服务器开启并使用 mTLS，
  那么需要确保您的健康检查机制可以正常工作。可以使用单独的端口，
  或者在健康检查客户端通过一种方法来获取正确的客户端证书。
* gRPC 中 xDS 的实现与 Envoy 不匹配。这将造成某些行为可能与预期不同，
  并且可能导致某些功能缺失。在 [gRPC 的功能状态](https://github.com/grpc/grpc/blob/master/doc/grpc_xds_features.md)中提供了更多详细信息。
  请确保任何 Istio 配置实际应用于您的无代理 gRPC 应用程序前做足测试工作。

## 性能 {#performance}

### 实验设置 {#experiment-setup}

* 使用 Fortio，一个基于 Go 语言实现的压力测试应用程序
    * 稍作修改，使其支持 gRPC 的 xDS 功能（PR）
* 资源：
    * GKE 1.20 集群，具有 3 个 `e2-standard-16` 节点（每个节点 16 CPU + 64 GB 内存）
    * Fortio 客户端和服务端应用程序：1.5 vCPU、1000 MiB 内存
    * Sidecar（istio-agent 及可能会用到的 Envoy 代理）：1 vCPU，512 MiB 内存
* 测试的工作负载类型：
    * 基线：常规 gRPC，不使用 Envoy 代理或无代理 xDS
    * Envoy：标准 istio-agent + Envoy 代理 Sidecar
    * 无代理：gRPC 使用 xDS gRPC 服务器实现以及客户端中的 `xds:///` 解析器
    * 通过 `PeerAuthentication` 和 `DestinationRule` 开启/禁用 mTLS

### 延迟 {#latency}

{{< image width="80%"
  link="./latencies_p50.svg"
  caption="p50 延迟对比图"
  >}}
{{< image width="80%"
  link="./latencies_p99.svg"
  caption="p99 延迟对比图"
  >}}

使用无代理 gRPC 解析器时，延迟会略有增加。与 Envoy 相比，
这是一个巨大的改进，并且仍然允许高级流量管理和 mTLS 功能。

### istio-proxy 容器资源使用情况 {#istio-proxy-container-resource-usage}

|                     | 客户端 `mCPU` | 客户端内存（`MiB`） | 服务端 `mCPU` | 服务端内存（`MiB`）|
|---------------------|--------------|-------------------|--------------|------------------|
| Envoy 纯文本         | 320.44       | 66.93             | 243.78      | 64.91                |
| Envoy mTLS          | 340.87       | 66.76             | 309.82      | 64.82                |
| 无代理纯文本          | 0.72         | 23.54             | 0.84      | 24.31                |
| 无代理 mTLS          | 0.73         | 25.05             | 0.78      | 25.43                |

尽管我们仍然需要代理，但代理使用的完整 vCPU 不到 0.1%，
并且仅使用 25 MiB 内存，不到运行 Envoy 所需内存的一半。

这些指标不包括应用程序容器中 gRPC 的额外资源使用情况，
仅用于演示在此模式下对 istio-agent 的资源使用影响。

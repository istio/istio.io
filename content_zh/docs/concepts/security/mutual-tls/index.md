---
title: 双向 TLS 认证
description: 描述 Istio 的双向 TLS 认证架构，这一功能在服务之间提供了强认证以及加密通讯的能力。
keywords: [security,mutual-tls]
weight: 10
---

Istio 希望在不变更服务代码的情况下增强微服务自身及其通信的安全性，它负责：

* 为每个服务提供可靠的、代表其角色的身份认证，以实现跨集群和云的互通性

* 加密服务间通信和终端用户到服务的通信

* 提供密钥管理系统来自动执行密钥和证书的生成、分发、轮换和撤销

## 架构

下图展示 Istio 安全相关的架构，其中包括三个主要组件：认证、密钥管理和通信安全。服务 `frontend` 使用的 Service account 是 frontend-team；而 `backend` 服务的 Service account 是 backend-team，Istio 在这两个服务之间的通信过程中进行了加密。不论服务是运行在 Kubernetes 的容器之中，还是运行在虚拟机/裸机上，都能获得 Istio 的支持。

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/auth.svg"
    alt="构成 Istio 认证模型的组件"
    caption="Istio 安全架构"
    >}}

如图所示，Istio 使用 Volume 加载 Secret，用这样的方式完成从 Citadel 到 Kubernetes 容器的证书以及密钥的分发。对于在虚拟机或裸机上运行的服务，需要在每个虚拟机和裸机上运行节点代理。它在本地生成私钥和 CSR（证书签名请求），将 CSR 发送给 Citadel 进行签名，并将生成的证书与私钥一起交给 Envoy。

## 组件

### 身份

Istio 使用 [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) 来识别谁在运行服务：

* Istio 中的 Service account格式为 `spiffe://<domain>/ns/<namespace>/sa/<serviceaccount>`
  * _domain_ 目前是 _cluster.local_ ，我们将很快支持域的定制化。
  * _namespace_ 是 Kubernetes service account 所在的命名空间。
  * _serviceaccount_ 是Kubernetes service account 的名称。

* Service account 是**工作负载运行的身份（或角色）**，表示该工作负载的权限。对于需要强大安全性的系统，工作负载的权限不应由随机字符串（如服务名称，标签等）或部署的二进制文件来标识。
  * 例如，假设有一个从多租户数据库中提取数据的工作负载。Alice 和 Bob 都能运行这个工作负载，从中获取数据，但是两个用户最终得到的数据是不同的。

* Service account 能够灵活的识别机器、用户、工作负载或一组工作负载（不同的工作负载可以使用同一 Service account 运行），从而实现强大的安全策略。

* Service account 在工作负载的整个生命周期中不会发生变化。

* 结合域名的约束，能保证 Service account 的唯一性。

### 通信安全

Istio 中，客户端和服务端的 [Envoy](https://envoyproxy.github.io/envoy/) 形成通信隧道，服务间的的通信就是通过这些隧道完成的。端到端通信通过以下方式加密：

* 服务与 Envoy 之间的本地 TCP 连接

* 代理之间的双向 TLS 连接

* 安全命名：在握手过程中，客户端 Envoy 检查服务器端证书提供的 Service account 是否允许运行目标服务

### 密钥管理

Istio 从 0.2 版本开始支持运行于 Kubernetes、虚拟机以及裸机之上的服务。对于每个场景，会使用不同的密钥配置机制。

对于运行在 Kubernetes 集群中的服务，

每个集群的 Citadel（证书颁发机构）

负责自动化执行密钥和证书管理流程。

它主要执行四个关键操作：

* 为每个 Service account 生成一个 [SPIFFE](https://spiffe.github.io/docs/svid) 密钥和证书

* 根据 Service account 将密钥和证书分发给每个 Pod

* 定期轮换密钥和证书

* 必要时撤销特定的密钥和证书对

对于运行在虚拟机或裸机上的服务，上述四个操作会由 Citadel 和节点代理协作完成。

## 工作流

Istio 安全工作流由部署和运行两阶段组成。Kubernetes 和虚拟机/裸机两种情况下的部署阶段是不一致的，因此我们需要分别讨论；然而一旦证书和密钥部署完成，运行阶段就是一致的了。这里主要讨论这一流程。

### Kubernetes 的部署阶段

1. Citadel 观察 Kubernetes API Server，为每个现有和新的 Service account 创建一个 [SPIFFE](https://spiffe.github.io/docs/svid) 密钥和证书对，并将其发送到 API Server。

1. 当创建 Pod 时，API Server 会根据 Service account 使用 [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/) 来挂载密钥和证书对。

1. [Pilot](/docs/concepts/traffic-management/pilot/) 使用适当的密钥和证书以及安全命名信息生成配置，该信息定义各个 Service account 的可运行服务，并将其传递给 Envoy。

### 虚拟机/裸机的部署阶段

1. Citadel 创建 gRPC 服务来处理 CSR 请求。

1. 节点代理创建私钥和 CSR，发送 CSR 到 Citadel 进行签署。

1. Citadel 验证 CSR 中携带的证书，并签署 CSR 以生成证书。

1. 节点代理将从 Citadel 接收到的证书和私钥发送给 Envoy。

1. 上述 CSR 流程定期重复，从而完成证书的轮转过程。

### 运行时阶段

1. 来自客户端服务的出站流量被重新路由到它本地的 Envoy。

1. 客户端 Envoy 与服务器端 Envoy 开始进行双向 TLS 的握手。在握手期间，它还进行安全的命名检查，以验证服务器证书中显示的服务帐户是否可以运行这一服务。

1. mTLS 连接成功以后，流量将转发到服务器端 Envoy，然后通过本地 TCP 连接转发到服务器服务。

## 最佳实践

在本节中，我们提供了一些部署指南，然后讨论了一个现实世界的场景。

### 部署指南

* 如果有多个服务运维人员（也称为 [SRE](https://en.wikipedia.org/wiki/Site_reliability_engineering)） 在集群中部署不同的服务（通常在中型或大型集群中），我们建议为每个 SRE 团队创建一个单独的 [namespace](https://en.wikipedia.org/wiki/Site_reliability_engineering)，来进行访问隔离。例如，您可以为 team1 创建一个 "team1-ns" 命名空间，为 team2 创建 "team2-ns" 命名空间，这样两个团队就无法访问对方的服务。

* 如果 Citadel 受到威胁，则可能会在集群中暴露它管理的所有密钥和证书。我们**强烈**建议在专门的只有集群管理员才能访问的命名空间（例如istio-citadel-ns）上运行 Citadel。

### 示例

我们设想一个三层的应用程序，其中有三个服务：照片前端，照片后端和数据存储。照片前端和照片后端服务由照片 SRE 团队管理，而数据存储服务由数据存储 SRE 团队管理。照片前端可以访问照片后端，照片后端可以访问数据存储。但是，照片前端无法访问数据存储。

在这种情况下，集群管理员创建 3 个命名空间：istio-citadel-ns、photo-ns 以及 datastore-ns。管理员可以访问所有命名空间，每个团队只能访问自己的命名空间。照片 SRE 团队创建了两个 Service account，在命名空间 photo-ns 中运行照片前端和照片后端。数据存储 SRE 团队创建一个 Service account 以在命名空间 datastore-ns 中运行数据存储服务。此外，我们需要在 [Istio Mixer](/docs/concepts/policies-and-telemetry/) 中强制执行服务访问控制，以使照片前端无法访问数据存储。

在此设置中，Citadel 能够为所有命名空间提供密钥和证书管理，并隔离彼此的微服务部署。

## 未来工作展望

* 跨集群的服务间认证

* 强大的认证机制：ABAC, RBAC等

* 支持单一服务的认证启用

* 为 Istio 组件（Mixer, Pilot）提供安全加固

* 使用 JWT/OAuth2/OpenID_Connect 提供终端用户和服务之间的认证

* 支持 GCP Service account

* 为服务和 Envoy 之间的本地通信提供 Unix 套接字支持

* 中间代理支持

* 可插拔密钥管理组件

---
title: 安全
description: 描述 Istio 的授权与鉴权功能。
weight: 30
keywords: [安全,认证,鉴权,rbac,访问控制]
---

将单一应用程序分解为微服务可提供各种好处，包括更好的灵活性、可伸缩性以及服务复用的能力。但是，微服务也有特殊的安全需求：

- 为了抵御中间人攻击，需要流量加密。
- 为了提供灵活的服务访问控制，需要双向 TLS 和细粒度的访问策略。
- 要审核谁在什么时候做了什么，需要审计工具。

Istio Security 尝试提供全面的安全解决方案来解决所有这些问题。

本页概述了如何使用 Istio 的安全功能来保护您的服务，无论您在何处运行它们。特别是 Istio 安全性可以缓解针对您的数据，端点，通信和平台的内部和外部威胁。

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/overview.svg"
    alt="Istio 安全模型的组件构成。"
    caption="Istio 安全概述"
    >}}

Istio 安全功能提供强大的身份，强大的策略，透明的 TLS 加密以及用于保护您的服务和数据的身份验证，授权和审计（AAA）工具。 Istio 安全的目标是：

- **默认安全** : 应用程序代码和基础结构无需更改

- **深度防御** : 与现有安全系统集成，提供多层防御

- **零信任网络** : 在不受信任的网络上构建安全解决方案

访问我们的[Mutual TLS Migration docs](/zh/docs/tasks/security/mtls-migration/)，开始在部署的服务中使用Istio安全功能。
请访问我们的[安全任务](/zh/docs/tasks/security/)，有关使用安全功能的详细说明。

如图所示，Istio 的 Citadel 用加载 Secret 卷的方式在 Kubernetes 容器中完成证书和密钥的分发。如果服务运行在虚拟机或物理机上，则会使用运行在本地的 Node agent，它负责在本地生成私钥和 CSR（证书签发申请），把 CSR 发送给 Citadel 进行签署，并把生成的证书和私钥分发给 Envoy。

## 高级架构

Istio 中的安全性涉及多个组件：

- **Citadel** 用于密钥和证书管理

- **Sidecar 和周边代理** 实现客户端和服务器之间的安全通信

- **Pilot** 将[授权策略](/zh/docs/concepts/security/#授权策略)和[安全命名信息](/zh/docs/concepts/security/#安全命名)分发给代理

- **Mixer** 管理授权和审计

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/architecture.svg"
    caption="Istio 安全架构"
    >}}

在下面的部分中，我们将详细介绍 Istio 安全功能。

## Istio 身份

身份是任何安全基础架构的基本概念。在服务到服务通信开始时，双方必须与其身份信息交换凭证以用于相互认证目的。
在客户端，根据[安全命名](/zh/docs/concepts/security/#安全命名)信息检查服务器的标识，以查看它是否是该服务的授权运行程序。
在服务器端，服务器可以根据[授权策略](/zh/docs/concepts/security/#授权策略) 确定客户端可以访问哪些信息，审核谁在什么时间访问了什么，根据服务向客户收费他们使用并拒绝任何未能支付账单的客户访问服务。

在 Istio 身份模型中，Istio 使用一流的服务标识来确定服务的身份。
这为表示人类用户，单个服务或一组服务提供了极大的灵活性和粒度。
在没有此类身份的平台上，Istio 可以使用可以对服务实例进行分组的其他身份，例如服务名称。

不同平台上的 Istio 服务标识：

- **Kubernetes**: Kubernetes 服务帐户

- **GKE/GCE**: 可以使用 GCP 服务帐户

- **GCP**: GCP 服务帐户

- **AWS**: AWS IAM 用户/角色 帐户

- **On-premises （非 Kubernetes）**: 用户帐户、自定义服务帐户、服务名称、istio 服务帐户或 GCP 服务帐户。

自定义服务帐户引用现有服务帐户，就像客户的身份目录管理的身份一样。

### Istio 安全与 SPIFFE

[SPIFFE](https://spiffe.io/) 标准提供了一个框架规范，该框架能够跨异构环境引导和向服务发布身份。

Istio 和 SPIFFE 共享相同的身份文件：[SVID](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md)（SPIFFE 可验证身份证件）。
例如，在 Kubernetes 中，X.509 证书的 URI 字段格式为 `spiffe://<domain>/ns/<namespace>/sa/<serviceaccount>`。
这使 Istio 服务能够建立和接受与其他 SPIFFE 兼容系统的连接。

Istio 安全性和 [SPIRE](https://spiffe.io/spire/)，它是 SPIFFE 的实现，在 PKI 实现细节上有所不同。
Istio 提供更全面的安全解决方案，包括身份验证、授权和审计。

## PKI

Istio PKI 建立在 Istio Citadel 之上，可为每个工作负载安全地提供强大的工作负载标识。
Istio 使用 X.509 证书来携带 [SPIFFE](https://spiffe.io/) 格式的身份。
PKI 还可以大规模自动化密钥和证书轮换。

Istio 支持在 Kubernetes pod 和本地计算机上运行的服务。
目前，我们为每个方案使用不同的证书密钥配置机制。

### Kubernetes 方案

1. Citadel 监视 Kubernetes `apiserver`，为每个现有和新的服务帐户创建 SPIFFE 证书和密钥对。Citadel 将证书和密钥对存储为 [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/)。

1. 创建 pod 时，Kubernetes 会根据其服务帐户通过 [Kubernetes secret volume](https://kubernetes.io/docs/concepts/storage/volumes/#secret) 将证书和密钥对挂载到 pod。

1. Citadel 监视每个证书的生命周期，并通过重写 Kubernetes 秘密自动轮换证书。

1. Pilot 生成[安全命名](/zh/docs/concepts/security/#安全命名)信息，该信息定义了哪些 Service Account 可以运行哪些服务。Pilot 然后将安全命名信息传递给 envoy sidecar。

### 本地机器方案

1. Citadel 创建 gRPC 服务以获取[证书签名请求](https://en.wikipedia.org/wiki/Certificate_signing_request)（CSR）。

1. 节点代理生成私钥和 CSR，并将 CSR 及其凭据发送给 Citadel 进行签名。

1. Citadel 验证 CSR 承载的凭证，并签署 CSR 以生成证书。

1. 节点代理将从 Citadel 接收的证书和私钥发送给 Envoy。

1. 上述 CSR 过程会定期重复进行证书和密钥轮换。

### 代理程序代理节点（开发中）

在不久的将来，Istio 将在 Kubernetes 中使用节点代理进行证书和密钥分配，如下图所示。请注意，本地计算机的标识提供流程是相同的，因此我们仅描述 Kubernetes 方案。

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/node_agent.svg"
    caption="PKI 与 Kubernetes 中的节点代理"
    >}}

流程如下：

1. Citadel 创建一个 gRPC 服务来接受 CSR 请求。

1. Envoy 通过 Envoy secret 发现服务（SDS）API 发送证书和密钥请求。

1. 收到 SDS 请求后，节点代理会创建私钥和 CSR，并将 CSR 及其凭据发送给 Citadel 进行签名。

1. Citadel 验证 CSR 中携带的凭证，并签署 CSR 以生成证书。

1. 节点代理通过 Envoy SDS API 将从 Citadel 接收的证书和私钥发送给 Envoy。

1. 上述 CSR 过程会定期重复进行证书和密钥轮换。

## 最佳实践

在本节中，我们提供了一些部署指南并讨论了一个真实的场景。

### 部署指南

如果有多个服务运维团队（又名[SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering)）在中型或大型集群中部署不同的服务，我们建议创建一个单独的[Kubernetes命名空间](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/)让每个 SRE 团队隔离他们的访问权限。例如，您可以为 `team1` 创建 `team1-ns` 命名空间，为 `team2` 创建 `team2-ns` 命名空间，这样两个团队都无法访问彼此的服务。

> {{<warning_icon>}}如果 Citadel 遭到入侵，则可能会暴露集群中的所有托管密钥和证书。我们强烈建议在专用命名空间中运行 Citadel（例如，`istio-citadel-ns`），以便仅限管理员访问群集。

### 示例

让我们考虑一个带有三种服务的三层应用程序：`photo-frontend`，`photo-backend` 和 `datastore`。照片 SRE 团队管理 `photo-frontend` 和 `photo-backend` 服务，而数据存储 SRE 团队管理 `datastore` 服务。 `photo-frontend`服务可以访问`photo-backend`，`photo-backend` 服务可以访问 `datastore`。但是，`photo-frontend`服务无法访问 `datastore`。

在这种情况下，集群管理员创建三个命名空间：`istio-citadel-ns`，`photo-ns`和`datastore-ns`。管理员可以访问所有命名空间，每个团队只能访问自己的命名空间。照片SRE团队创建了两个服务帐户，分别在`photo-ns`命名空间中运行`photo-frontend`和`photo-backend`。数据存储区 SRE 团队创建一个服务帐户，以在`datastore-ns`命名空间中运行`datastore`服务。此外，我们需要在 [Istio Mixer](/zh/docs/concepts/policies-and-telemetry/) 中强制执行服务访问控制，使得`photo-frontend`无法访问数据存储区。

在此设置中，Kubernetes 可以隔离运营商管理服务的权限。 Istio 管理所有命名空间中的证书和密钥，并对服务实施不同的访问控制规则。

## 认证

Istio 提供两种类型的身份验证：

- **传输身份验证**，也称为**服务到服务身份验证**：验证直接客户端进行连接。
  Istio 提供 [双向 TLS](https://en.wikipedia.org/wiki/Mutual_authentication) 作为传输身份验证的完整堆栈解决方案。
  您可以轻松打开此功能，而无需更改服务代码。这个解决方案：

    - 为每个服务提供强大的身份，表示其角色，以实现跨群集和云的互操作性。
    - 保护服务到服务通信和最终用户到服务通信。
    - 提供密钥管理系统，以自动执行密钥和证书生成，分发和轮换。

- **来源身份认证**，也称为**最终用户身份验证**：验证原始客户端将请求作为最终用户或设备。Istio 通过 JSON Web Token（JWT）验证和 [`Auth0`](https://auth0.com/)、[`Firebase Auth`](https://firebase.google.com/docs/auth/) 、[`Google Auth`](https://developers.google.com/identity/protocols/OpenIDConnect) 和自定义身份验证来简化开发人员体验，并且轻松实现请求级别的身份验证。

在这两种情况下，Istio 都通过自定义 Kubernetes API 将身份认证策略存储在 `Istio 配置存储`中。 Pilot 会在适当的时候为每个代理保持最新状态以及密钥。此外，Istio 支持在许可模式下进行身份验证，以帮助您了解策略更改在其生效之前如何影响您的安全状态。

### 双向 TLS 认证

Istio 隧道通过客户端和服务器端进行服务到服务通信 [Envoy 代理](https://envoyproxy.github.io/envoy/)。对于客户端调用服务器，遵循的步骤是：

1. Istio 将出站流量从客户端重新路由到客户端的本地 sidecar Envoy。

1. 客户端 Envoy 和服务器端 Envoy 建立了一个双向的 TLS 连接，Istio 将流量从客户端 Envoy 转发到服务器端 Envoy。

1. 授权后，服务器端 Envoy 通过本地 TCP 连接将流量转发到服务器服务。

#### 安全命名

安全命名信息包含来自服务器标识的 *N 到 N* 映射，这些映射在证书中编码到由发现服务或 DNS 引用的服务名称。从身份 `A` 到服务名称 `B` 的映射意味着“允许 `A` 并授权其运行服务 `B` ”。Pilot 监视 Kubernetes `apiserver`，生成安全的命名信息，并将其安全地分发给 sidecar Envoy。以下示例说明了为什么安全命名在身份验证中至关重要。

假设运行服务 `datastore` 的合法服务器仅使用 `infra-team` 标识。恶意用户拥有 `test-team` 身份的证书和密钥。恶意用户打算模拟服务以检查从客户端发送的数据。恶意用户使用证书和 `test-team` 身份的密钥部署伪造服务器。假设恶意用户成功攻击了发现服务或 DNS，以将 `datastore` 服务名称映射到伪造服务器。

当客户端调用 `datastore` 服务时，它从服务器的证书中提取 `test-team` 标识，并检查是否允许 `test-team` 运行带有安全命名信息的 `datastore`。客户端检测到 `test-team` 不允许运行 `datastore` 服务，并且验证失败。

### 认证架构

您可以使用身份认证策略为在 Istio 网格中接收请求的服务指定身份验证要求。网格操作者使用 `.yaml` 文件来指定策略。部署后，策略将保存在 `Istio Config Store`。 Pilot、Istio 控制器监视配置存储。一有任何的策略变更，Pilot 会将新策略转换为适当的配置，告知 Envoy sidecar 代理如何执行所需的身份验证机制。Pilot 可以获取公钥并将其附加到 JWT 验证配置。或者，Pilot 提供 Istio 系统管理的密钥和证书的路径，并将它们挂载到应用程序 pod 以进行双向 TLS。您可以在 [PKI 部分](/zh/docs/concepts/security/#pki)中找到更多信息。Istio 异步发送配置到目标端点。代理收到配置后，新的身份验证要求会立即生效。

发送请求的客户端服务负责遵循必要的身份验证机制。对于源身份验证（JWT），应用程序负责获取 JWT 凭据并将其附加到请求。对于双向 TLS，Istio 提供[目标规则](/zh/docs/concepts/traffic-management/#目标规则)。运维人员可以使用目标规则来指示客户端代理使用 TLS 与服务器端预期的证书进行初始连接。您可以在 [PKI 和身份部分](/zh/docs/concepts/security/#双向-TLS-认证)中找到有关双向 TLS 如何在 Istio 中工作的更多信息。

{{< image width="60%" ratio="67.12%"
    link="/docs/concepts/security/authn.svg"
    caption="认证架构"
    >}}

Istio 将两种类型的身份验证以及凭证中的其他声明（如果适用）输出到下一层：[授权](/zh/docs/concepts/security/#授权和鉴权)。此外，运维人员可以指定将传输或原始身份验证中的哪个身份作为`委托人`使用。

### 认证策略

本节中提供了更多 Istio 认证策略方面的细节。正如[认证架构](/zh/docs/concepts/security#认证架构)中所说的，认证策略是对服务收到的请求生效的。要在双向 TLS 中指定客户端认证策略，需要在 `DetinationRule` 中设置 `TLSSettings`。[TLS 设置参考文档](/docs/reference/config/istio.networking.v1alpha3/#TLSSettings)中有更多这方面的信息。和其他的 Istio 配置一样，可以用 `.yaml` 文件的形式来编写认证策略，然后使用 `istioctl` 进行部署。

下面例子中的认证策略要求 `reviews` 服务必须使用双向 TLS：

{{< text yaml >}}
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "reviews"
spec:
  targets:
  - name: reviews
    peers:
  - mtls: {}
{{< /text >}}

#### 策略存储范围

Istio 可以在命名空间范围或网络范围存储中存储身份认证策略：

- 为 `kind` 字段指定了网格范围策略，其值为 `MeshPolicy`，名称为 `default`。例如：

    {{< text yaml >}}
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "MeshPolicy"
    metadata:
      name: "default"
    spec:
      peers:
      - mtls: {}
    {{< /text >}}

- 为 `kind` 字段和指定的命名空间指定命名空间范围策略，其值为 `Policy`。如果未指定，则使用默认命名空间。例如，命名空间 `ns1`：

    {{< text yaml >}}
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "ns1"
    spec:
      peers:
      - mtls: {}
    {{< /text >}}

命名空间范围存储中的策略只能影响同一命名空间中的服务。网格范围内的策略可以影响网格中的所有服务。为防止冲突和滥用，只能在网状范围存储中定义一个策略。该策略必须命名为 `default` 并且有一个空的 `targets:` 部分。您可以在我们的[目标选择器部分](/zh/docs/concepts/security/#目标选择器)中找到更多信息。

#### 目标选择器

身份认证策略的目标指定策略适用的服务。以下示例展示的是一个 `targets:` 部分，指定该策略适用于：

- 任何端口上的 `product-page` 服务。
- 端口 `9000` 上的评论服务。

{{< text yaml >}}
targets:

 - name: product-page
 - name: reviews
   ports:
   - number: 9000
{{< /text >}}

如果您未提供 `targets:` 部分，则 Istio 将策略与策略存储范围内的所有服务匹配。因此，`targets:` 部分可以帮助您指定策略的范围：

- 网格范围策略：在网格范围存储中定义的策略，没有目标选择器部分。**网格中**最多只能有**一个**网格范围的策略。

- 命名空间范围的策略：在命名空间范围存储中定义的策略，名称为 `default` 且没有目标选择器部分。**每个命名空间**最多只能有**一个**命名空间范围的策略。

- 特定于服务的策略：在命名空间范围存储中定义的策略，具有非空目标选择器部分。命名空间可以具有**零个，一个或多个**特定于服务的策略。

对于每项服务，Istio 都应用最窄的匹配策略。顺序是：**特定服务>命名空间范围>网格范围**。如果多个特定于服务的策略与服务匹配，则 Istio 随机选择其中一个。运维人员在配置其策略时必须避免此类冲突。

为了强制网格范围和命名空间范围的策略的唯一性，Istio 每个网格只接受一个身份认证策略，每个命名空间只接受一个身份认证策略。Istio 还要求网格范围和命名空间范围的策略具有特定名称`default`。

#### 传输认证

`peers:` 部分定义了策略中传输身份验证支持的身份验证方法和相关参数。该部分可以列出多个方法，并且只有一个方法必须满足认证才能通过。但是，从 Istio 0.7 版本开始，当前支持的唯一传输身份验证方法是双向 TLS。如果您不需要传输身份验证，请完全跳过此部分。

以下示例显示了使用双向 TLS 启用传输身份验证的 `peers:` 部分。

{{< text yaml >}}
peers:
  - mtls: {}
{{< /text >}}

目前，双向 TLS 设置不需要任何参数。因此，`-mtls: {}`、`- mtls:` 或 `- mtls: null` 声明被视为相同。将来，双向 TLS 设置可以携带参数以提供不同的双向 TLS 实现。

#### 来源身份认证

`origins:` 部分定义了原始身份验证支持的身份验证方法和相关参数。Istio 仅支持 JWT 原始身份验证。但是，策略可以列出不同发行者的多个 JWT。与传输身份验证类似，只有一种列出的方法必须满足身份验证才能通过。

以下示例策略为原始身份验证指定了一个 `origin:` 部分，该部分接受 Google 发布的 JWT：

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
{{< /text >}}

#### 主认证绑定

主认证关系用键值对的方式存储绑定关系。默认情况下，Istio 使用 `peers:` 部分中配置的身份验证。如果在 `peers:` 部分中未配置身份验证，则 Istio 将保留身份验证。策略编写者可以使用 `USE_ORIGIN` 值覆盖此行为。此值将 Istio 配置为使用 origin 的身份验证作为主体身份验证。将来，我们将支持条件绑定，例如：当传输体为 X 时为 `USE_PEER`，否则为 `USE_ORIGIN` 。

以下示例显示了 `principalBinding` 键，其值为 `USE_ORIGIN`：

{{< text yaml >}}
principalBinding: USE_ORIGIN
{{< /text >}}

### 更新认证策略

您可以随时更改身份认证策略，Istio 几乎实时地将更改推送到端点。但是，Istio 无法保证所有端点同时收到新策略。以下是在更新身份认证策略时避免中断的建议：

- 启用或禁用双向 TLS：使用带有 `mode:` 键和 `PERMISSIVE` 值的临时策略。这会将接收服务配置为接受两种类型的流量：纯文本和 TLS。因此，不会丢弃任何请求。一旦所有客户端切换到预期协议，无论是否有双向 TLS，您都可以将 `PERMISSIVE` 策略替换为最终策略。有关更多信息，请访问[双向 TLS 的迁移](/zh/docs/tasks/security/mtls-migration)。

{{< text yaml >}}
peers:
- mtls:
    mode: PERMISSIVE
{{< /text >}}

- 对于 JWT 身份验证迁移：在更改策略之前，请求应包含新的 JWT。一旦服务器端完全切换到新策略，旧 JWT（如果有的话）可以被删除。需要更改客户端应用程序才能使这些更改生效。

## 授权和鉴权

Istio 的授权功能也称为基于角色的访问控制（RBAC）——为 Istio Mesh 中的服务提供命名空间级别、服务级别和方法级别的访问控制。它的特点是：

- **基于角色的语义**，简单易用。
- **服务间和最终用户对服务的授权**。
- **通过自定义属性支持的灵活性**，例如条件、角色和角色绑定。
- **高性能**，因为 Istio 授权是在 Envoy 本地强制执行的。

### 授权架构

{{< image width="90%" ratio="56.25%"
    link="./authz.svg"
    alt="Istio Authorization"
    caption="Istio 授权架构"
    >}}

上图显示了基本的 Istio 授权架构。运维人员使用 `.yaml` 文件指定 Istio 授权策略。部署后，Istio 将策略保存在 `Istio Config Store` 中。

Pilot 监督 Istio 授权策略的变更。如果发现任何更改，它将获取更新的授权策略。 Pilot 将 Istio 授权策略分发给与服务实例位于同一位置的 Envoy 代理。

每个 Envoy 代理都运行一个授权引擎，该引擎在运行时授权请求。当请求到达代理时，授权引擎根据当前授权策略评估请求上下文，并返回授权结果 `ALLOW` 或 `DENY`。

### 启用授权

您可以使用 `RbacConfig` 对象启用 Istio Authorization。`RbacConfig` 对象是一个网格范围的单例，其固定名称值为 `default`。您只能在网格中使用一个`RbacConfig` 实例。与其他 Istio 配置对象一样，`RbacConfig` 被定义为Kubernetes `CustomResourceDefinition` [(CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)对象。

在 `RbacConfig` 对象中，运算符可以指定 `mode` 值，它可以是：

- **`OFF`**：禁用 Istio 授权。
- **`ON`**：为网格中的所有服务启用了 Istio 授权。
- **`ON_WITH_INCLUSION`**：仅对`包含`字段中指定的服务和命名空间启用 Istio 授权。
- **`ON_WITH_EXCLUSION`**：除了`排除`字段中指定的服务和命名空间外，网格中的所有服务都启用了 Istio 授权。

 在以下示例中，为 `default` 命名空间启用了 Istio 授权。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["default"]
{{< /text >}}

### 授权策略

要配置 Istio 授权策略，请指定 `ServiceRole` 和 `ServiceRoleBinding`。与其他 Istio 配置对象一样，它们被定义为 Kubernetes `CustomResourceDefinition`（ [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)）对象。

- **`ServiceRole`** 定义了一组访问服务的权限。
- **`ServiceRoleBinding`** 向特定主题授予 `ServiceRole`，例如用户、组或服务。

`ServiceRole` 和 `ServiceRoleBinding` 的组合规定： 允许**谁**在**哪些条件**下**做什么** 。特别：

- **谁**指的是 `ServiceRoleBinding` 中的 `subject` 部分。
- **做什么**指的是 `ServiceRole` 中的 `permissions` 部分。
- **哪些条件**指的是你可以在 `ServiceRole` 或 `ServiceRoleBinding` 中使用 [Istio 属性](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)指定的 `conditions` 部分。

#### `ServiceRole`

`ServiceRole` 规范包括`规则`、所谓的权限列表。每条规则都有以下标准字段：

- **`services`**：服务名称列表。您可以将值设置为 `*` 以包括指定命名空间中的所有服务。

- **`methods`**：HTTP 方法名称列表，对于 gRPC 请求的权限，HTTP 动词始终是 `POST` 。您可以将值设置为 `*` 以包含所有 HTTP 方法。

- **`paths`**：HTTP 路径或 gRPC 方法。 gRPC 方法必须采用 `/packageName.serviceName/methodName` 的形式，并且区分大小写。

`ServiceRole` 规范仅适用于 `metadata` 部分中指定的命名空间。规则中需要 `services` 和 `methods` 字段。 `paths` 是可选的。如果未指定规则或将其设置为 `*`，则它适用于任何实例。

下面的示例显示了一个简单的角色：`service-admin`，它可以完全访问 `default` 命名空间中的所有服务。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: service-admin
  namespace: default
spec:
  rules:
  - services: ["*"]
    methods: ["*"]
{{< /text >}}

这是另一个角色：`products-viewer`，它有读取，`GET` 和 `HEAD`，访问 `default` 命名空间中的`products.default.svc.cluster.local` 服务。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: products-viewer
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
{{< /text >}}

此外，我们支持规则中所有字段的前缀匹配和后缀匹配。例如，您可以在 `default`命名空间中定义具有以下权限的 `tester` 角色：

- 完全访问前缀为 `test-*` 的所有服务，例如：`test-bookstore`、`test-performance`、`test-api.default.svc.cluster.local`。
- 阅读（`GET`）使用 `*/reviews` 后缀访问所有路径，例如：`/books/reviews`、`/events/booksale/reviews`、`/reviews` in service`bookstore .default.svc.cluster.local`。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: tester
  namespace: default
spec:
  rules:
  - services: ["test-*"]
    methods: ["*"]
  - services: ["bookstore.default.svc.cluster.local"]
    paths: ["*/reviews"]
    methods: ["GET"]
{{< /text >}}

在 `ServiceRole` 中，`namespace` + `services` + `paths`  + `methods` 的组合定义了**如何访问服务**。在某些情况下，您可能需要为规则指定其他条件。例如，规则可能仅适用于服务的某个**版本**，或仅适用于具有特定**标签**的服务，如 `foo`。您可以使用 `constraints` 轻松指定这些条件。

例如，下面的 `ServiceRole` 定义在以前的 `products-viewer` 角色基础之上添加了一个约束：`request.headers[version]` 为 `v1` 或 `v2` 。在[约束和属性页面](/docs/reference/config/authorization/constraints-and-properties/)中列出了约束支持的`key`值。在属性值是 `map` 类型的情况下，例如 `request.headers`，`key` 是 map 中的一个条目，例如 `request.headers[version]`。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: products-viewer-version
  namespace: default
spec:
  rules:

  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
    constraints:
    - key: request.headers[version]
      values: ["v1", "v2"]
{{< /text >}}

#### `ServiceRoleBinding`

`ServiceRoleBinding` 规范包括两部分：

- **`roleRef`** 指的是同一命名空间中的 `ServiceRole` 资源。
- **`subjects`** 分配给角色的列表。

您可以使用 `user` 或一组 `properties` 显式指定 *subject*。`ServiceRoleBinding`  *subject* 中的 *property* 类似于`ServiceRole` 规范中的 *constraint* 。 *property* 还允许您使用条件指定分配给此角色的一组帐户。它包含一个 `key` 及其允许的*值*。约束支持的 `key` 值列在[约束和属性页面](/docs/reference/config/authorization/constraints-and-properties/)中。

下面的例子显示了一个名为 `test-binding-products` 的 `ServiceRoleBinding`，它将两个 `subject` 绑定到名为 `product-viewer` 的 `ServiceRole` 并具有以下 `subject`

- 代表服务的服务帐户 **a**，``service-account-a``。
- 代表 Ingress 服务的服务帐户 `istio-ingress-service-account` **并且** JWT中的 `mail` 项声明为 `a@foo.com`。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: test-binding-products
  namespace: default
spec:
  subjects:

  - user: "service-account-a"
  - user: "istio-ingress-service-account"
    properties:
      request.auth.claims[email]: "a@foo.com"
    roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

如果您想要公开访问服务，可以将 `subject` 设置为 `user："*"` 。此值将 `ServiceRole` 分配给**所有（经过身份验证和未经身份验证的）**用户和服务，例如：

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: binding-products-allusers
  namespace: default
spec:
  subjects:
  - user: "*"
    roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

要将 `ServiceRole` 分配给**经过身份验证的**用户和服务，请使用 `source.principal："*"` 代替，例如：

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
kind: ServiceRoleBinding
metadata:
  name: binding-products-all-authenticated-users
  namespace: default
spec:
  subjects:
  - properties:
      source.principal: "*"
    roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

### 使用其他授权机制

虽然我们强烈建议使用 Istio 授权机制，但 Istio 足够灵活，允许您通过 Mixer 组件插入自己的身份验证和授权机制。
要在 Mixer 中使用和配置插件，请访问我们的[策略和遥测适配器文档](/zh/docs/concepts/policies-and-telemetry/#适配器)。

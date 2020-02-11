---
title: 安全
description: 描述 Istio 的授权与鉴权功能。
weight: 25
keywords: [security,policy,policies,authentication,authorization,rbac,access-control]
aliases:
    - /zh/docs/concepts/network-and-auth/auth.html
    - /zh/docs/concepts/security/authn-policy/
    - /zh/docs/concepts/security/mutual-tls/
    - /zh/docs/concepts/security/rbac/
    - /zh/docs/concepts/security/mutual-tls.html
---

将单一应用程序分解为微服务可提供各种好处，包括更好的灵活性、可伸缩性以及服务复用的能力。但是，微服务也有特殊的安全需求：

- 为了抵御中间人攻击，需要流量加密。

- 为了提供灵活的服务访问控制，需要双向 TLS 和细粒度的访问策略。

- 要审核谁在什么时候做了什么，需要审计工具。

Istio Security 尝试提供全面的安全解决方案来解决所有这些问题。

本页概述了如何使用 Istio 的安全功能来保护您的服务，无论您在何处运行它们。特别是 Istio 安全性可以缓解针对您的数据、端点、通信和平台的内部和外部威胁。

{{< image width="80%" link="./overview.svg" caption="Istio 安全概述" >}}

Istio 安全功能提供强大的身份，强大的策略，透明的 TLS 加密以及用于保护您的服务和数据的身份验证，授权和审计（AAA）工具。 Istio 安全的目标是：

- **默认安全**： 应用程序代码和基础结构无需更改

- **深度防御**： 与现有安全系统集成，提供多层防御

- **零信任网络**： 在不受信任的网络上构建安全解决方案

请访问我们的[双向 TLS 迁移](/zh/docs/tasks/security/authentication/mtls-migration/)相关文章，开始在部署的服务中使用 Istio 安全功能。
请访问我们的[安全任务](/zh/docs/tasks/security/)，以获取有关使用安全功能的详细说明。

## 高级架构{#high-level-architecture}

Istio 中的安全性涉及多个组件：

- **Citadel** 用于密钥和证书管理

- **Sidecar 和周边代理** 实现客户端和服务器之间的安全通信

- **Pilot** 将[授权策略](/zh/docs/concepts/security/#authorization-policy)和[安全命名信息](/zh/docs/concepts/security/#secure-naming)分发给代理

- **Mixer** 管理授权和审计

{{< image width="80%" link="./architecture.svg" caption="Istio 安全架构" >}}

在下面的部分中，我们将详细介绍 Istio 安全功能。

## Istio 身份{#istio-identity}

身份是任何安全基础架构的基本概念。在服务间通信开始时，双方必须与其身份信息交换凭证以用于相互认证目的。在客户端，根据[安全命名](/zh/docs/concepts/security/#secure-naming)信息检查服务器的标识，以查看它是否是该服务的授权运行程序。在服务器端，服务器可以根据[授权策略](/zh/docs/concepts/security/#authorization-policy)确定客户端可以访问哪些信息，审核谁在什么时间访问了什么，根据服务向客户收费并拒绝任何未能支付账单的客户访问服务。

在 Istio 身份模型中，Istio 使用一流的服务标识来确定服务的身份。这为表示人类用户，单个服务或一组服务提供了极大的灵活性和粒度。在没有此类身份的平台上，Istio 可以使用可以对服务实例进行分组的其他身份，例如服务名称。

不同平台上的 Istio 服务标识：

- **Kubernetes**： Kubernetes 服务帐户

- **GKE/GCE**： 可以使用 GCP 服务帐户

- **GCP**： GCP 服务帐户

- **AWS**： AWS IAM 用户/角色帐户

- **本地（非 Kubernetes）**： 用户帐户、自定义服务帐户、服务名称、Istio 服务帐户或 GCP 服务帐户。

自定义服务帐户引用现有服务帐户，就像客户的身份目录管理的身份一样。

### Istio 安全与 SPIFFE{#Istio-security-SPIFFE}

[SPIFFE](https://spiffe.io/) 标准提供了一个框架规范，该框架能够跨异构环境引导和向服务发布身份。

Istio 和 SPIFFE 共享相同的身份文件：[SVID](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md)（SPIFFE 可验证身份证件）。例如，在 Kubernetes 中，X.509 证书的 URI 字段格式为 `spiffe://<domain>/ns/<namespace>/sa/<serviceaccount>`。
这使 Istio 服务能够建立和接受与其他 SPIFFE 兼容系统的连接。

Istio 安全性和 [SPIRE](https://spiffe.io/spire/)，它是 SPIFFE 的实现，在 PKI 实现细节上有所不同。

Istio 提供更全面的安全解决方案，包括身份验证、授权和审计。

## PKI{#PKI}

Istio PKI 建立在 Istio Citadel 之上，可为每个工作负载安全地提供强大的工作负载标识。Istio 使用 X.509 证书来携带 [SPIFFE](https://spiffe.io/) 格式的身份。PKI 还可用于大规模自动化密钥和证书轮换。

Istio 支持在 Kubernetes pod 和本地计算机上运行的服务。目前，我们为每个方案使用不同的证书密钥配置机制。

### Kubernetes 方案{#Kubernetes-scenario}

1. Citadel 监视 Kubernetes `apiserver`，为每个现有和新的服务帐户创建 SPIFFE 证书和密钥对。Citadel 将证书和密钥对存储为 [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/)。

1. 创建 pod 时，Kubernetes 会根据其服务帐户通过 [Kubernetes secret volume](https://kubernetes.io/docs/concepts/storage/volumes/#secret) 将证书和密钥对挂载到 pod 上。

1. Citadel 监视每个证书的生命周期，并通过重写 Kubernetes secret 自动轮换证书。

1. Pilot 生成[安全命名](/zh/docs/concepts/security/#secure-naming)信息，该信息定义了哪些 Service Account 可以运行哪些服务。Pilot 然后将安全命名信息传递给 envoy sidecar。

### 本地机器方案{#on-premises-machines-scenario}

1. Citadel 创建 gRPC 服务来接受[证书签名请求](https://en.wikipedia.org/wiki/Certificate_signing_request)（CSR）。

1. 节点代理生成私钥和 CSR，并将 CSR 及其凭据发送给 Citadel 进行签名。

1. Citadel 验证 CSR 承载的凭证，并签署 CSR 以生成证书。

1. 节点代理将从 Citadel 接收的证书和私钥发送给 Envoy。

1. 上述 CSR 过程会定期重复进行证书和密钥轮换。

### Kubernetes 中的代理节点{#node-agent-in-Kubernetes}

Istio 提供了在 Kubernetes 中使用节点代理进行证书和密钥分配的选项，如下图所示。请注意，本地计算机的标识提供流程是相同的，因此我们仅描述 Kubernetes 方案。

{{< image width="80%" link="./node_agent.svg" caption="PKI 与 Kubernetes 中的节点代理" >}}

流程如下：

1. Citadel 创建一个 gRPC 服务来接受 CSR 请求。

1. Envoy 通过 Envoy secret 发现服务（SDS）API 发送证书和密钥请求。

1. 收到 SDS 请求后，节点代理会创建私钥和 CSR，并将 CSR 及其凭据发送给 Citadel 进行签名。

1. Citadel 验证 CSR 中携带的凭证，并签署 CSR 以生成证书。

1. 节点代理通过 Envoy SDS API 将从 Citadel 接收的证书和私钥发送给 Envoy。

1. 上述 CSR 过程会定期重复进行证书和密钥轮换。

{{< idea >}}
使用节点代理调试端点可以查看节点代理当前正在为其客户端代理提供服务的  secret。访问代理程序 `8080` 端口上的 `/debug/sds/workload` 以获取当前工作负载 secret，或访问 `/debug/sds/gateway` 以获取当前网关 secret。
{{< /idea >}}

## 认证{#authentication}

Istio 提供两种类型的身份验证：

- **传输身份验证**，也称为**服务间身份验证**：验证建立连接的直接客户端。
  Istio 提供 [双向 TLS](https://en.wikipedia.org/wiki/Mutual_authentication) 作为传输身份验证的完整堆栈解决方案。
  您可以轻松打开此功能，而无需更改服务代码。这个解决方案：

    - 为每个服务提供强大的身份，表示其角色，以实现跨群集和云的互操作性。
    - 保护服务到服务通信和最终用户到服务的通信。
    - 提供密钥管理系统，以自动执行密钥和证书生成，分发和轮换。

- **来源身份认证**，也称为**最终用户身份验证**：验证作为最终用户或设备发出请求的原始客户端。Istio 通过 JSON Web Token（JWT）验证和 [ORY Hydra](https://www.ory.sh)、[Keycloak](https://www.keycloak.org)、[Auth0](https://auth0.com/)、[Firebase Auth](https://firebase.google.com/docs/auth/)、[Google Auth](https://developers.google.com/identity/protocols/OpenIDConnect) 和自定义身份验证来简化开发人员体验，并且轻松实现请求级别的身份验证。

在这两种情况下，Istio 都通过自定义 Kubernetes API 将身份认证策略存储在 Istio 配置存储中。Pilot 会在适当的时候为每个代理保持最新状态以及密钥。此外，Istio 支持在宽容模式（permissive mode）下进行身份验证，以帮助您了解策略更改在其生效之前如何影响您的安全状态。

### 双向 TLS 认证{#mutual-TLS-authentication}

Istio 隧道通过客户端和服务器端进行服务间（service-to-service）通信 [Envoy 代理](https://envoyproxy.github.io/envoy/)。为了使客户端通过双向 TLS 调用服务端，请遵循以下步骤：

1. Istio 将出站流量从客户端重新路由到客户端的本地 sidecar Envoy。

1. 客户端 Envoy 与服务器端 Envoy 开始双向 TLS 握手。在握手期间，客户端 Envoy 还做了[安全命名](/zh/docs/concepts/security/#secure-naming)检查，以验证服务器证书中显示的服务帐户是否被授权运行到目标服务。

1. 客户端 Envoy 和服务器端 Envoy 建立了一个双向的 TLS 连接，Istio 将流量从客户端 Envoy 转发到服务器端 Envoy。

1. 授权后，服务器端 Envoy 通过本地 TCP 连接将流量转发到服务器服务。

#### 宽容模式{#permissive-mode}

Istio 双向 TLS 具有一个宽容模式（permissive mode），允许 service 同时接受纯文本流量和双向 TLS 流量。这个功能极大的提升了双向 TLS 的入门体验。

在运维人员希望将服务移植到启用了双向 TLS 的 Istio 上时，许多非 Istio 客户端和非 Istio 服务端通信时会产生问题。通常情况下，运维人员无法同时为所有客户端安装 Istio sidecar，甚至没有这样做的权限。即使在服务端上安装了 Istio sidecar，运维人员也无法在不中断现有连接的情况下启用双向 TLS。

启用宽容模式后，服务可以同时接受纯文本和双向 TLS 流量。这个模式为入门提供了极大的灵活性。服务中安装的 Istio sidecar 立即接受双向 TLS 流量而不会打断现有的纯文本流量。因此，运维人员可以逐步安装和配置客户端 Istio sidecar 发送双向 TLS 流量。一旦客户端配置完成，运维人员便可以将服务端配置为仅 TLS 模式。更多信息请访问[双向 TLS 迁移向导](/zh/docs/tasks/security/authentication/mtls-migration)。

#### 安全命名{#secure-naming}

安全命名信息包含从编码在证书中的服务器标识到被发现服务或 DNS 引用的服务名称的 *N-到-N* 映射。从身份 `A` 到服务名称 `B` 的映射意味着“允许 `A` 并授权其运行服务 `B`。Pilot 监视 Kubernetes `apiserver`，生成安全的命名信息，并将其安全地分发给 sidecar Envoy。以下示例说明了为什么安全命名在身份验证中至关重要。

假设运行服务 `datastore` 的合法服务器仅使用 `infra-team` 标识。恶意用户拥有 `test-team` 身份的证书和密钥。恶意用户打算模拟服务以检查从客户端发送的数据。恶意用户使用证书和 `test-team` 身份的密钥部署伪造服务器。假设恶意用户成功攻击了发现服务或 DNS，以将 `datastore` 服务名称映射到伪造服务器。

当客户端调用 `datastore` 服务时，它从服务器的证书中提取 `test-team` 标识，并检查是否允许 `test-team` 运行带有安全命名信息的 `datastore`。客户端检测到 `test-team` 不允许运行 `datastore` 服务，并且验证失败。

安全命名能够防止 HTTPS 流量受到一般性网络劫持，除了 DNS 欺骗外，它还可以保护 TCP 流量免受一般网络劫持。如果攻击者劫持了 DNS 并修改了目的地的 IP 地址，它将无法用于 TCP 通信。这是因为 TCP 流量不包含主机名信息，我们只能依靠 IP 地址进行路由，而且甚至在客户端 Envoy 收到流量之前，也可能发生 DNS 劫持。

### 认证架构{#authentication-architecture}

您可以使用身份认证策略为在 Istio 网格中接收请求的服务指定身份验证要求。网格操作者使用 `.yaml` 文件来指定策略。部署后，策略将保存在 Istio 配置存储中。Pilot、Istio 控制器监视配置存储。一有任何的策略变更，Pilot 会将新策略转换为适当的配置，告知 Envoy sidecar 代理如何执行所需的身份验证机制。Pilot 可以获取公钥并将其附加到 JWT 验证配置。或者，Pilot 提供 Istio 系统管理的密钥和证书的路径，并将它们挂载到应用程序 pod 以进行双向 TLS。您可以在 [PKI 部分](/zh/docs/concepts/security/#PKI)中找到更多信息。Istio 异步发送配置到目标端点。代理收到配置后，新的身份验证要求会立即生效。

发送请求的客户端服务负责遵循必要的身份验证机制。对于源身份验证（JWT），应用程序负责获取 JWT 凭据并将其附加到请求。对于双向 TLS，Istio 提供[目标规则](/zh/docs/concepts/traffic-management/#destination-rules)。运维人员可以使用目标规则来指示客户端代理使用 TLS 与服务器端预期的证书进行初始连接。您可以在 [双向 TLS 认证](/zh/docs/concepts/security/#mutual-TLS-authentication)中找到有关双向 TLS 如何在 Istio 中工作的更多信息。

{{< image width="60%" link="./auth.svg" caption="认证架构" >}}

Istio 将两种类型的身份验证以及凭证中的其他声明（如果适用）输出到下一层：[授权](/zh/docs/concepts/security/#authorization)。此外，运维人员可以指定将传输或原始身份验证中的哪个身份作为`委托人`使用。

### 认证策略{#authentication-policies}

本节中提供了更多 Istio 认证策略方面的细节。正如[认证架构](/zh/docs/concepts/security/#authentication-architecture)中所说的，认证策略是对服务收到的请求生效的。要在双向 TLS 中指定客户端认证策略，需要在 `DetinationRule` 中设置 `TLSSettings`。[TLS 设置参考文档](/zh/docs/reference/config/networking/destination-rule/#TLSSettings)中有更多这方面的信息。和其他的 Istio 配置一样，可以用 `.yaml` 文件的形式来编写认证策略，然后使用 `istioctl` 进行部署。

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

#### 策略存储范围{#policy-storage-scope}

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

命名空间范围存储中的策略只能影响同一命名空间中的服务。网格范围内的策略可以影响网格中的所有服务。为防止冲突和滥用，只能在网格范围存储中定义一个策略。该策略必须命名为 `default` 并且有一个空的 `targets:` 部分。您可以在我们的[目标选择器部分](/zh/docs/concepts/security/#target-selectors)中找到更多信息。

#### 目标选择器{#target-selectors}

身份认证策略的目标指定策略适用的服务。以下示例展示的是一个 `targets:` 部分，指定该策略适用于：

- 任何端口上的 `product-page` 服务。
- `9000` 端口上的 reviews 服务。

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

为了强制网格范围和命名空间范围的策略的唯一性，Istio 每个网格只接受一个身份认证策略，每个命名空间只接受一个身份认证策略。Istio 还要求网格范围和命名空间范围的策略具有特定名称 `default`。

#### 传输认证{#transport-authentication}

`peers:` 部分定义了策略中传输身份验证支持的身份验证方法和相关参数。该部分可以列出多个方法，并且只有一个方法必须满足认证才能通过。但是，从 Istio 0.7 版本开始，当前支持的唯一传输身份验证方法是双向 TLS。如果您不需要传输身份验证，请完全跳过此部分。

以下示例显示了使用双向 TLS 启用传输身份验证的 `peers:` 部分。

{{< text yaml >}}
peers:
  - mtls: {}
{{< /text >}}

默认的双向 TLS 模式为 `STRICT`。因此，`mode: STRICT` 等效于以下内容：

- `- mtls: {}`
- `- mtls:`
- `- mtls: null`

如果不指定双向 TLS 模式，则对等方无法使用 Transport 身份验证，并且 Istio 拒绝绑定到 Sidecar 的双向 TLS 连接。在应用程序层，服务仍可以处理它们自己的双向 TLS 会话。

#### 来源身份认证{#origin-authentication}

`origins:` 部分定义了原始身份验证支持的身份验证方法和相关参数。Istio 仅支持 JWT 原始身份验证。但是，策略可以列出不同发行者的多个 JWT。与传输身份验证类似，要想通过身份验证必须通过其中的一个。

以下示例策略为原始身份验证指定了一个 `origin:` 部分，该部分接受 Google 发布的 JWT。路径的 JWT 身份验证 `/health` 已禁用。

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
    trigger_rules:
    - excluded_paths:
      - exact: /health
{{< /text >}}

#### 主认证绑定{#principal-binding}

主认证关系用键值对的方式存储绑定关系。默认情况下，Istio 使用 `peers:` 部分中配置的身份验证。如果在 `peers:` 部分中未配置身份验证，则 Istio 将保留身份验证。策略编写者可以使用 `USE_ORIGIN` 值覆盖此行为。此值将 Istio 配置为使用 origin 的身份验证作为主体身份验证。将来，我们将支持条件绑定，例如：当传输体为 X 时为 `USE_PEER`，否则为 `USE_ORIGIN` 。

以下示例显示了 `principalBinding` 键，其值为 `USE_ORIGIN`：

{{< text yaml >}}
principalBinding: USE_ORIGIN
{{< /text >}}

### 更新认证策略{#updating-authentication-policies}

您可以随时更改身份认证策略，Istio 几乎实时地将更改推送到端点。但是，Istio 无法保证所有端点同时收到新策略。以下是在更新身份认证策略时避免中断的建议：

- 启用或禁用双向 TLS：使用带有 `mode:` 键和 `PERMISSIVE` 值的临时策略。这会将接收服务配置为接受两种类型的流量：纯文本和 TLS。因此，不会丢弃任何请求。一旦所有客户端切换到预期协议，无论是否有双向 TLS，您都可以将 `PERMISSIVE` 策略替换为最终策略。有关更多信息，请访问[双向 TLS 的迁移](/zh/docs/tasks/security/authentication/mtls-migration)。

{{< text yaml >}}
peers:
- mtls:
    mode: PERMISSIVE
{{< /text >}}

- 对于 JWT 身份验证迁移：在更改策略之前，请求应包含新的 JWT。一旦服务器端完全切换到新策略，旧 JWT（如果有的话）可以被删除。需要更改客户端应用程序才能使这些更改生效。

## 授权{#authorization}

Istio 的授权功能为 Istio 网格中的工作负载提供网格级别、命名空间级别和工作负载级别的访问控制。它提供了：

- **工作负载间和最终用户到工作负载的授权**。
- **一个简单的 API**，它包括一个单独的并且很容易使用和维护的 [`AuthorizationPolicy` CRD](/zh/docs/reference/config/security/authorization-policy/)。
- **灵活的语义**，运维人员可以在 Istio 属性上自定义条件。
- **高性能**，因为 Istio 授权是在 Envoy 本地强制执行的。
- **高兼容性**，原生支持 HTTP、HTTPS 和 HTTP2，以及任意普通 TCP 协议。

### 授权架构{#authorization-architecture}

{{< image width="90%"  link="./authz.svg"
    alt="Istio 授权"
    caption="Istio 授权架构"
    >}}

上图显示了基本的 Istio 授权架构。运维人员使用 `.yaml` 文件指定 Istio 授权策略。

每个 Envoy 代理都运行一个授权引擎，该引擎在运行时授权请求。当请求到达代理时，授权引擎根据当前授权策略评估请求上下文，并返回授权结果 `ALLOW` 或 `DENY`。

### 隐式启用{#implicit-enablement}

无需显式启用 Istio 的授权功能，只需在**工作负载**上应用 `AuthorizationPolicy` 即可实现访问控制。

如果没有对工作负载应用 `AuthorizationPolicy`，则不会执行访问控制，也就是说，将允许所有请求。

如果有任何 `AuthorizationPolicy` 应用到工作负载，则默认情况下将拒绝对该工作负载的访问，除非策略中声明的规则明确允许了。

目前，`AuthorizationPolicy` 仅支持 `ALLOW` 动作。
这意味着，如果将多个授权策略应用于同一工作负载，它们的效果是累加的。

### 授权策略{#authorization-policy}

要配置 Istio 授权策略，请创建一个 [`AuthorizationPolicy` 资源](/zh/docs/reference/config/security/authorization-policy/)。

授权策略包括选择器和规则列表。
选择器指定策略所适用的**目标**，而规则指定什么**条件**下允许**谁**做**什么**。
具体来说：

- **目标** 请参考 `AuthorizationPolicy` 中的 `selector` 部分。
- **谁** 请参考 `AuthorizationPolicy` 的 `rule` 中的 `from` 部分。
- **什么** 请参考 `AuthorizationPolicy` 的 `rule` 中的 `to` 部分。
- **条件** 请参考 `AuthorizationPolicy` 的 `rule` 中的 `when` 部分。

每个规则都有以下标准字段：

- **`from`**：来源列表。
- **`to`**：操作列表。
- **`when`**：自定义条件列表。

下例显示了一个 `AuthorizationPolicy`，它允许两个来源（服务帐户 `cluster.local/ns/default/sa/sleep` 和命名空间 `dev`）在使用有效的 JWT 令牌发送请求时，可以访问命名空间 foo 中的带有标签 `app: httpbin` 和 `version: v1` 的工作负载。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep"]
   - source:
       namespaces: ["dev"]
   to:
   - operation:
       methods: ["GET"]
   when:
   - key: request.auth.claims[iss]
     values: ["https://accounts.google.com"]
{{< /text >}}

#### 策略目标{#policy-target}

策略范围（目标）由 `metadata/namespace` 和可选的 `selector` 确定。

`metadata/namespace` 告诉该策略适用于哪个命名空间。如果设置为根命名空间，则该策略将应用于网格中的所有命名空间。根命名空间的值是可配置的，默认值为 `istio-system`。
如果设置为普通命名空间，则该策略将仅适用于指定的命名空间。

工作负载 `selector` 可用于进一步限制策略的应用范围。
`selector` 使用 pod 标签来选择目标工作负载。
工作负载选择器包含 `{key: value}` 对的列表，其中 `key` 是标签的名称。
如果未设置，则授权策略将应用于与授权策略相同的命名空间中的所有工作负载。

以下示例策略 `allow-read` 允许对 `default` 命名空间中带有标签 `app: products` 的工作负载的 `"GET"` 和 `"HEAD"` 访问。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-read
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  rules:
  - to:
    - operation:
         methods: ["GET", "HEAD"]
{{< /text >}}

#### 值匹配{#value-matching}

大部分字段都支持完全匹配、前缀匹配、后缀匹配和存在匹配，但有一些例外情况（例如，`when` 部分下的`key` 字段，`source` 部分下的 `ipBlocks` 和 `to` 部分下的 `ports` 字段仅支持完全匹配）。

- **完全匹配**。即完整的字符串匹配。
- **前缀匹配**。`"*"` 结尾的字符串。例如，`"test.abc.*"` 匹配 `"test.abc.com"`、`"test.abc.com.cn"`、`"test.abc.org"` 等等。
- **后缀匹配**。`"*"` 开头的字符串。例如，`"*.abc.com"` 匹配 `"eng.abc.com"`、`"test.eng.abc.com"` 等等。
- **存在匹配**。`*` 用于指定非空的任意内容。您可以使用格式 `fieldname: ["*"]` 指定必须存在的字段。
这意味着该字段可以匹配任意内容，但是不能为空。请注意这与不指定字段不同，后者意味着包括空的任意内容。

以下示例策略允许访问前缀为 `"/test/"` 或后缀为 `"/info"` 的路径。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: tester
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  rules:
  - to:
    - operation:
        paths: ["/test/*", "*/info"]
{{< /text >}}

#### 全部允许和全部拒绝{#allow-all-and-deny-all}

下例展示了一个简单的策略 `allow-all`，它允许到 `default` 命名空间的所有工作负载的全部访问。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-all
  namespace: default
spec:
  rules:
  - {}
{{< /text >}}

下例展示了一个简单的策略 `deny-all`，它拒绝对 `admin` 命名空间的所有工作负载的任意访问。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: admin
spec:
  {}
{{< /text >}}

#### 自定义条件{#custom-conditions}

您还可以使用 `when` 部分指定其他条件。
例如，下面的 `AuthorizationPolicy` 定义包括以下条件：`request.headers[version]` 是 `v1` 或 `v2`。
在这种情况下，key 是 `request.headers[version]`，它是 Istio 属性 `request.headers`（是个字典）中的一项。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep"]
   to:
   - operation:
       methods: ["GET"]
   when:
   - key: request.headers[version]
     values: ["v1", "v2"]
{{< /text >}}

[条件页面](/zh/docs/reference/config/security/conditions/)中列出了支持的条件 `key` 值。

#### 认证与未认证身份{#authenticated-and-unauthenticated-identity}

如果要使工作负载可公开访问，则需要将 `source` 部分留空。
这允许来自**所有（经过身份验证和未经身份验证）**的用户和工作负载的源，例如：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - to:
   - operation:
       methods: ["GET", "POST"]
{{< /text >}}

要仅允许**经过身份验证**的用户，请将 `principal` 设置为 `"*"`，例如：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - from:
   - source:
       principals: ["*"]
   to:
   - operation:
       methods: ["GET", "POST"]
{{< /text >}}

### 在普通 TCP 协议上使用 Istio 授权{#using-Istio-authorization-on-plain-TCP-protocols}

Istio 授权支持工作负载使用任意普通 TCP 协议，如 MongoDB。
在这种情况下，您可以按照与 HTTP 工作负载相同的方式配置授权策略。
不同之处在于某些字段和条件仅适用于 HTTP 工作负载。
这些字段包括：

- 授权策略对象 `source` 部分中的 `request_principals` 字段
- 授权策略对象 `operation` 部分中的 `hosts`、`methods` 和 `paths` 字段

 [条件页面](/zh/docs/reference/config/security/conditions/)中列出了支持的条件。

如果您在授权策略中对 TCP 工作负载使用了任何只适用于 HTTP 的字段，Istio 将会忽略它们。

假设您在端口 27017 上有一个 MongoDB 服务，下例配置了一个授权策略，只允许 Istio 网格中的 `bookinfo-ratings-v2` 服务访问该 MongoDB 工作负载。

{{< text yaml >}}
apiVersion: "security.istio.io/v1beta1"
kind: AuthorizationPolicy
metadata:
  name: mongodb-policy
  namespace: default
spec:
 selector:
   matchLabels:
     app: mongodb
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/bookinfo-ratings-v2"]
   to:
   - operation:
       ports: ["27017"]
{{< /text >}}

### 对双向 TLS 的依赖{#dependency-on-mutual-TLS}

Istio 使用双向 TLS 将某些信息从客户端安全地传递到服务器。在使用授权策略中的以下任何字段之前，必须先启用双向 TLS：

- `source` 部分下的 `principals` 字段
- `source` 部分下的 `namespaces` 字段
- `source.principal` 自定义条件
- `source.namespace` 自定义条件
- `connection.sni` 自定义条件

如果您不使用授权策略中的上述任何字段，则双向 TLS 不是必须的。

### 使用其他授权机制{#using-other-authorization-mechanisms}

虽然我们强烈建议使用 Istio 授权机制，但 Istio 足够灵活，允许您通过 Mixer 组件插入自己的身份验证和授权机制。
要在 Mixer 中使用和配置插件，请访问我们的[策略和遥测适配器文档](/zh/docs/reference/config/policy-and-telemetry/adapters)。

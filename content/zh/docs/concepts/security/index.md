---
title: 安全
description: 描述 Istio 的授权与认证功能。
weight: 30
keywords: [security,policy,policies,authentication,authorization,rbac,access-control]
aliases:
    - /zh/docs/concepts/network-and-auth/auth.html
    - /zh/docs/concepts/security/authn-policy/
    - /zh/docs/concepts/security/mutual-tls/
    - /zh/docs/concepts/security/rbac/
    - /zh/docs/concepts/security/mutual-tls.html
    - /zh/docs/concepts/policies/
owner: istio/wg-security-maintainers
test: n/a
---

将单一应用程序分解为微服务可提供各种好处，包括更好的灵活性、
可伸缩性以及服务复用的能力。但是，微服务也有特殊的安全需求：

- 为了抵御中间人攻击，需要流量加密。
- 为了提供灵活的服务访问控制，需要双向 TLS 和细粒度的访问策略。
- 要确定谁在什么时候做了什么，需要审计工具。

Istio Security 尝试提供全面的安全解决方案来解决所有这些问题。
本页概述了无论您在何处运行服务都能使用 Istio 的安全功能来保护这些服务。
特别是 Istio 安全性可以减轻针对您的数据、端点、通信和平台的内外威胁。

{{< image width="75%"
    link="./overview.svg"
    caption="安全概述"
    >}}

Istio 安全功能提供了强大的身份、强大的策略、透明的 TLS 加密、
认证/授权/审计（AAA）工具来保护您的服务和数据。Istio 安全的目标是：

- 默认安全：应用程序代码和基础设施无需更改
- 深度防御：与现有安全系统集成以提供多层防御
- 零信任网络：在不受信任的网络上构建安全解决方案

请访问我们的[双向 TLS 迁移](/zh/docs/tasks/security/authentication/mtls-migration/)相关文章，
开始在已部署的服务中使用 Istio 安全功能。请访问我们的[安全任务](/zh/docs/tasks/security/)，
以获取有关使用安全功能的详细说明。

## 高层架构 {#high-level-architecture}

Istio 中的安全性涉及多个组件：

- 用于密钥和证书管理的证书颁发机构（CA）
- 配置 API 服务器分发给代理：

    - [认证策略](/zh/docs/concepts/security/#authentication-policies)
    - [授权策略](/zh/docs/concepts/security/#authorization-policies)
    - [安全命名信息](/zh/docs/concepts/security/#secure-naming)

- Sidecar 和边缘代理作为[策略执行点](https://www.jerichosystems.com/technology/glossaryterms/policy_enforcement_point.html)（PEP）
  以保护客户端和服务器之间的通信安全。
- 一组 Envoy 代理扩展，用于管理遥测和审计

控制面处理来自 API server 的配置，并且在数据面中配置 PEP。
PEP 用 Envoy 实现。下图显示了架构。

{{< image width="75%"
    link="./arch-sec.svg"
    caption="安全架构"
    >}}

在下面的部分中，我们将详细介绍 Istio 安全功能。

## Istio 身份 {#istio-identity}

身份是任何安全基础架构的基本概念。在工作负载间通信开始时，
双方必须交换包含身份信息的凭证以进行双向验证。在客户端，
根据[安全命名](/zh/docs/concepts/security/#secure-naming)信息检查服务器的标识，
以查看它是否是工作负载授权的运行程序。在服务器端，
服务器可以根据[授权策略](/zh/docs/concepts/security/#authorization-policies)确定客户端可以访问哪些信息，
审计谁在什么时间访问了什么，根据他们使用的工作负载向客户收费，
并拒绝任何未能支付账单的客户访问工作负载。

Istio 身份模型使用经典的 `service identity`（服务身份）来确定一个请求源端的身份。
这种模型有极好的灵活性和粒度，可以用服务身份来标识人类用户、单个工作负载或一组工作负载。
在没有服务身份的平台上，Istio 可以使用其它可以对服务实例进行分组的身份，例如服务名称。

下面的列表展示了在不同平台上可以使用的服务身份：

- Kubernetes：Kubernetes 服务帐户
- GKE/GCE：GCP 服务帐户
- 本地（非 Kubernetes）：用户帐户、自定义服务帐户、服务名称、
  Istio 服务帐户或 GCP 服务帐户。自定义服务帐户引用现有服务帐户，
  就像客户的身份目录管理的身份一样。

## 身份和证书管理 {#PKI}

Istio PKI 使用 X.509 证书为每个工作负载都提供强大的身份标识。
`istio-agent` 与每个 Envoy 代理一起运行，与 `istiod`
一起协作来自动化的进行大规模密钥和证书轮换。下图显示了这个机制的运行流程。

{{< tip >}}
译者注：这里用 `istio-agent` 来表述，是因为下图及对图的相关解读中反复用到了 "Istio agent"
这个术语，这样的描述更容易理解。另外，在实现层面，`istio-agent` 是指 Sidecar 容器中的
`pilot-agent` 进程，它有很多功能，这里不表，
只特别提一下：它通过 Unix socket 的方式在本地提供 SDS 服务供 Envoy 使用，
这个信息对了解 Envoy 与 SDS 之间的交互有意义。
{{< /tip >}}

{{< image width="75%"
    link="./id-prov.svg"
    caption="身份供应流程"
    >}}

Istio 通过以下流程提供密钥和证书：

1. `istiod` 提供 gRPC 服务以接受[证书签名请求](https://en.wikipedia.org/wiki/Certificate_signing_request)（CSR）。
1. `istio-agent` 在启动时创建私钥和 CSR，然后将 CSR 及其凭据发送到 `istiod` 进行签名。
1. `istiod` CA 验证 CSR 中携带的凭据，成功验证后签署 CSR 以生成证书。
1. 当工作负载启动时，Envoy 通过 [Secret 发现服务（SDS）](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#secret-discovery-service-sds)API 向同容器内的 `istio-agent` 发送证书和密钥请求。
1. `istio-agent` 通过 Envoy SDS API 将从 `istiod` 收到的证书和密钥发送给 Envoy。
1. `istio-agent` 监控工作负载证书的过期时间。上述过程会定期重复进行证书和密钥轮换。

## 认证 {#authentication}

Istio 提供两种类型的认证：

- 对等认证：用于服务到服务的认证，以验证建立连接的客户端。
  Istio 提供[双向 TLS](https://en.wikipedia.org/wiki/Mutual_authentication)
  作为传输认证的全栈解决方案，无需更改服务代码就可以启用它。这个解决方案：
    - 为每个服务提供强大的身份，表示其角色，以实现跨集群和云的互操作性。
    - 保护服务到服务的通信。
    - 提供密钥管理系统，以自动进行密钥和证书的生成、分发和轮换。

- 请求认证：用于终端用户认证，以验证附加到请求的凭据。
  Istio 使用 JSON Web Token（JWT）验证启用请求级认证，
  并使用自定义认证实现或任何 OpenID Connect 的认证实现（例如下面列举的）来简化的开发人员体验。
    - [ORY Hydra](https://www.ory.sh/)
    - [Keycloak](https://www.keycloak.org/)
    - [Auth0](https://auth0.com/)
    - [Firebase Auth](https://firebase.google.com/docs/auth/)
    - [Google Auth](https://developers.google.com/identity/protocols/OpenIDConnect)

在所有情况下，Istio 都通过自定义 Kubernetes API 将认证策略存储在 `Istio config store`。
{{< gloss >}}Istiod{{< /gloss >}} 使每个代理保持最新状态，
并在适当时提供密钥。此外，Istio 的认证机制支持宽容模式（permissive mode），
以帮助您在强制实施前了解策略更改将如何影响您的安全状况。

### 双向 TLS 认证 {#mutual-TLS-authentication}

Istio 通过客户端和服务器端 PEP 建立服务到服务的通信通道，
PEP 被实现为 [Envoy 代理](https://www.envoyproxy.io/)。
当一个工作负载使用双向 TLS 认证向另一个工作负载发送请求时，
该请求的处理方式如下：

1. Istio 将出站流量从客户端重新路由到客户端的本地 Sidecar Envoy。
1. 客户端 Envoy 与服务器端 Envoy 开始双向 TLS 握手。在握手期间，
   客户端 Envoy 还做了[安全命名](/zh/docs/concepts/security/#secure-naming)检查，
   以验证服务器证书中显示的服务帐户是否被授权运行目标服务。
1. 客户端 Envoy 和服务器端 Envoy 建立了一个双向的 TLS 连接，Istio 将流量从客户端 Envoy 转发到服务器端 Envoy。
1. 服务器端 Envoy 授权请求。如果获得授权，它将流量转发到通过本地 TCP 连接的后端服务。

Istio 将 `TLSv1_2` 作为最低支持的 TLS 版本为客户端和服务器配置了如下的加密套件：

- `ECDHE-ECDSA-AES256-GCM-SHA384`

- `ECDHE-RSA-AES256-GCM-SHA384`

- `ECDHE-ECDSA-AES128-GCM-SHA256`

- `ECDHE-RSA-AES128-GCM-SHA256`

- `AES256-GCM-SHA384`

- `AES128-GCM-SHA256`

#### 宽容模式 {#permissive-mode}

Istio 双向 TLS 具有一个宽容模式（permissive mode），
允许服务同时接受纯文本流量和双向 TLS 流量。这个功能极大地提升了双向 TLS 的入门体验。

在运维人员希望将服务移植到启用了双向 TLS 的 Istio 上时，
许多非 Istio 客户端与非 Istio 服务器端之间的通信会产生问题。
通常情况下，运维人员无法同时为所有客户端安装 Istio Sidecar，
甚至在某些客户端上没有这样做的权限。即使在服务器端上安装了 Istio Sidecar，
运维人员也无法在不中断现有连接的情况下启用双向 TLS。

启用宽容模式后，服务可以同时接受纯文本和双向 TLS 流量。
这个模式为入门提供了极大的灵活性。服务器中安装的 Istio Sidecar
立即接受双向 TLS 流量而不会打断现有的纯文本流量。因此，
运维人员可以逐步安装和配置客户端 Istio Sidecar 发送双向 TLS 流量。
一旦客户端配置完成，运维人员便可以将服务器端配置为仅 TLS 模式。
更多信息请访问[双向 TLS 迁移向导](/zh/docs/tasks/security/authentication/mtls-migration)。

#### 安全命名 {#secure-naming}

服务器身份（Server identity）被编码在证书里，
但服务名称（service name）通过服务发现或 DNS 被检索。
安全命名信息将服务器身份映射到服务名称。身份 `A` 到服务名称 `B`
的映射表示"授权 `A` 运行服务 `B`"。控制平面监视 `apiserver`，
生成安全命名映射，并将其安全地分发到 PEP。
以下示例说明了为什么安全命名对身份验证至关重要。

假设运行服务 `datastore` 的合法服务器仅使用 `infra-team` 身份。
恶意用户拥有 `test-team` 身份的证书和密钥。
恶意用户打算模拟合法服务以检查从客户端发送的数据。
恶意用户使用证书和 `test-team` 身份的密钥部署伪造服务器。
假设恶意用户成功劫持（通过 DNS 欺骗、BGP/路由劫持、ARP 欺骗等）发送到
`datastore` 的流量并将其重定向到伪造的服务器。

当客户端调用 `datastore` 服务时，它从服务器的证书中提取 `test-team` 身份，
并用安全命名信息检查 `test-team` 是否被允许运行 `datastore`。
客户端检测到 `test-team` 不允许运行 `datastore` 服务，认证失败。

请注意，对于非 HTTP/HTTPS 流量，安全命名不能保护其免于 DNS 欺骗，
如攻击者劫持了 DNS 并修改了目的地 IP 地址。这是因为 TCP 流量不包含主机名信息，
Envoy 只能依靠目的地 IP 地址进行路由，因此 Envoy 有可能将流量路由到劫持
IP 地址所在的服务上。这种 DNS 欺骗甚至可以在客户端 Envoy 接收到流量之前发生。

### 认证架构 {#authentication-architecture}

您可以使用对等认证策略和请求认证策略为在 Istio 网格中接收请求的工作负载指定认证要求。
网格运维人员使用 `.yaml` 文件来指定策略。部署后，策略将保存在 Istio 配置存储中。
Istio 控制器监视配置存储。

在任何的策略变更时，新策略都会转换为适当的配置，告知 PEP 如何执行所需的认证机制。
控制平面可以获取公钥并将其附加到 JWT 验证的配置中。作为替代方案，
Istiod 提供了 Istio 系统管理的密钥和证书的路径，并将它们安装到应用程序 Pod 用于双向 TLS。
您可以在 [PKI 部分](/zh/docs/concepts/security/#PKI)中找到更多信息。

Istio 异步发送配置到目标端点。代理收到配置后，新的认证要求会立即生效。

发送请求的客户端服务负责遵循必要的认证机制。
对于请求认证，应用程序负责获取 JWT 凭证并将其附加到请求。
对于对等认证，Istio 自动将两个 PEP 之间的所有流量升级为双向 TLS。
如果认证策略禁用了双向 TLS 模式，则 Istio 将继续在 PEP 之间使用纯文本。要覆盖此行为，
请使用[目标规则](/zh/docs/concepts/traffic-management/#destination-rules)显式禁用双向 TLS 模式。
您可以在[双向 TLS 认证](/zh/docs/concepts/security/#mutual-TLS-authentication)中找到有关双向
TLS 如何工作的更多信息。

{{< image width="75%"
    link="./authn.svg"
    caption="认证架构"
    >}}

Istio 将这两种认证类型以及凭证中的其他声明（如果适用）输出到下一层：
[授权](/zh/docs/concepts/security/#authorization)。

### 认证策略 {#authentication-policies}

本节中提供了更多 Istio 认证策略方面的细节。
正如[认证架构](/zh/docs/concepts/security/#authentication-architecture)中所说的，
认证策略是对服务收到的请求生效的。要在双向 TLS 中指定客户端认证策略，
需要在 `DetinationRule` 中设置 `TLSSettings`。
[TLS 设置参考文档](/zh/docs/reference/config/networking/destination-rule/#TLSSettings)中有更多这方面的信息。

和其他的 Istio 配置一样，可以用 `.yaml` 文件的形式来编写认证策略，使用 `kubectl`
应用策略。下面例子中的认证策略要求：与带有 `app: reviews` 标签的工作负载的传输层认证，
必须使用双向 TLS：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "example-peer-policy"
  namespace: "foo"
spec:
  selector:
    matchLabels:
      app: reviews
  mtls:
    mode: STRICT
{{< /text >}}

#### 策略存储 {#policy-storage}

Istio 将网格范围的策略存储在根命名空间。这些策略使用一个空的 selector
应用到网格中的所有工作负载。具有命名空间范围的策略存储在相应的命名空间中。
它们仅适用于其命名空间内的工作负载。如果您配置了 `selector` 字段，
则认证策略仅适用于与您配置的条件匹配的工作负载。

对等认证策略和请求认证策略用 kind 字段区分，
分别是 `PeerAuthentication` 和 `RequestAuthentication`。

#### Selector 字段 {#selector-field}

对等认证策略和请求认证策略使用 `selector` 字段来指定该策略适用的工作负载的标签。
以下示例显示适用于带有 `app: product-page` 标签的工作负载的策略的 selector 字段：

{{< text yaml >}}
selector:
  matchLabels:
    app: product-page
{{< /text >}}

如果您没有为 `selector` 字段提供值，
则 Istio 会将策略与策略存储范围内的所有工作负载进行匹配。
因此，`selector` 字段可帮助您指定策略的范围：

- 网格范围策略：为根命名空间指定的策略，不带或带有空的 `selector` 字段。
- 命名空间范围的策略：为非root命名空间指定的策略，不带有或带有空的 `selector` 字段。
- 特定于工作负载的策略：在常规命名空间中定义的策略，带有非空 `selector` 字段。

对等认证策略和请求认证策略对 `selector` 字段遵循相同的层次结构原则，
但是 Istio 以略微不同的方式组合和应用这些策略。

只能有一个网格范围的对等认证策略，
每个命名空间也只能有一个命名空间范围的对等认证策略。
当您为同一网格或命名空间配置多个网格范围或命名空间范围的对等认证策略时，
Istio 会忽略较新的策略。当多个特定于工作负载的对等认证策略匹配时，
Istio 将选择最旧的策略。

Istio 按照以下顺序为每个工作负载应用最窄的匹配策略：

1. 特定的工作负载
1. 命名空间范围
1. 网格范围

Istio 可以将所有匹配的请求认证策略组合起来，
就像它们来自单个请求认证策略一样。因此，
您可以在网格或命名空间中配置多个网格范围或命名空间范围的策略。
但是，避免使用多个网格范围或命名空间范围的请求认证策略仍然是一个好的实践。

#### 对等认证 {#peer-authentication}

对等认证策略指定 Istio 对目标工作负载实施的双向 TLS 模式。支持以下模式：

- PERMISSIVE：工作负载接受双向 TLS 和纯文本流量。
  此模式在迁移因为没有 Sidecar 而无法使用双向 TLS 的工作负载的过程中非常有用。
  一旦工作负载完成 Sidecar 注入的迁移，应将模式切换为 STRICT。
- STRICT：工作负载仅接收双向 TLS 流量。
- DISABLE：禁用双向 TLS。从安全角度来看，除非您提供自己的安全解决方案，否则请勿使用此模式。

如果模式为 unset，将继承父作用域的模式。unset 模式的网格范围的对等认证策略默认使用 `PERMISSIVE` 模式。

下面的对等认证策略要求命名空间 `foo` 中的所有工作负载都使用双向 TLS：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "example-policy"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
{{< /text >}}

对于特定于工作负载的对等认证策略，可以为不同的端口指定不同的双向 TLS 模式。
您只能将端口范围的双向 TLS 配置在工作负载声明过的端口上。
以下示例为 `app:example-app` 工作负载禁用了端口 80 上的双向 TLS，
并对所有其他端口使用命名空间范围的对等认证策略的双向 TLS 设置：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "example-workload-policy"
  namespace: "foo"
spec:
  selector:
     matchLabels:
       app: example-app
  portLevelMtls:
    80:
      mode: DISABLE
{{< /text >}}

上面的对等认证策略仅在有如下 Service 定义时工作，
将流向 `example-service` 服务的请求绑定到 `example-app`
工作负载的 `80` 端口

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: example-service
  namespace: foo
spec:
  ports:
  - name: http
    port: 8000
    protocol: TCP
    targetPort: 80
  selector:
    app: example-app
{{< /text >}}

#### 请求认证 {#request-authentication}

请求认证策略指定验证 JSON Web Token（JWT）所需的值。这些值包括：

- token 在请求中的位置
- 请求的 issuer
- 公共 JSON Web Key Set（JWKS）

Istio 会根据请求认证策略中的规则检查提供的令牌（如果已提供），
并拒绝令牌无效的请求。当请求不带有令牌时，默认将接受这些请求。
要拒绝没有令牌的请求，请提供授权规则，该规则指定对特定操作（例如，路径或操作）的限制。

如果请求认证策略使用唯一的位置，则可以在这些策略中指定多个 JWT。
当多个策略与一个工作负载匹配时，Istio 会将所有规则组合起来，
就好像这些规则被指定为单个策略一样。此行为对于开发接受来自不同 JWT 提供者的工作负载时很有用。
但是，不支持具有多个有效 JWT 的请求，因为此类请求的输出主体未被定义。

#### Principal {#principals}

使用对等认证策略和双向 TLS 时，Istio 将身份从对等认证提取到 `source.principal` 中。
同样，当您使用请求认证策略时，Istio 会将 JWT 中的身份赋值给 `request.auth.principal`。
使用这些 principal 设置授权策略并作为遥测的输出。

### 更新认证策略 {#updating-authentication-policies}

您可以随时更改认证策略，Istio 几乎实时将新策略推送到工作负载。
但是，Istio 无法保证所有工作负载都同时收到新政策。
以下建议有助于避免在更新认证策略时造成干扰：

- 将对等认证策略的模式从 `DISABLE` 更改为 `STRICT` 时，
  请使用 `PERMISSIVE` 模式来过渡，反之亦然。当所有工作负载成功切换到所需模式时，
  您可以将策略应用于最终模式。您可以使用 Istio 遥测技术来验证工作负载已成功切换。
- 将请求认证策略从一个 JWT 迁移到另一个 JWT 时，
  将新 JWT 的规则添加到该策略中，而不删除旧规则。这样，
  工作负载将接受两种类型的 JWT，当所有流量都切换到新的 JWT 时，
  您可以删除旧规则。但是，每个 JWT 必须使用不同的位置。

## 授权 {#authorization}

Istio 的授权功能为网格中的工作负载提供网格、
命名空间和工作负载级别的访问控制。这种控制层级提供了以下优点：

- 工作负载到工作负载以及最终用户到工作负载的授权。
- 一个简单的 API：它包括一个单独的并且很容易使用和维护的
  [`AuthorizationPolicy` CRD](/zh/docs/reference/config/security/authorization-policy/)。
- 灵活的语义：运维人员可以在 Istio 属性上定义自定义条件，并使用 DENY 和 ALLOW 动作。
- 高性能：Istio 授权是在 Envoy 本地强制执行的。
- 高兼容性：原生支持 HTTP、HTTPS 和 HTTP2，以及任意普通 TCP 协议。

### 授权架构 {#authorization-architecture}

授权策略对服务器端 Envoy 代理的入站流量实施访问控制。
每个 Envoy 代理都运行一个授权引擎，该引擎在运行时授权请求。
当请求到达代理时，授权引擎根据当前授权策略评估请求上下文，
并返回授权结果 `ALLOW` 或 `DENY`。
运维人员使用 `.yaml` 文件指定 Istio 授权策略。

{{< image width="50%"
    link="./authz.svg"
    caption="授权架构"
    >}}

### 隐式启用 {#implicit-enablement}

您无需显式启用 Istio 的授权功能；它们在安装之后可用。
要对您的工作负载实施访问控制，您需要应用授权策略。

对于没有应用授权策略的工作负载，Istio 允许所有请求。

授权策略支持 `ALLOW`、`DENY` 和 `CUSTOM` 操作。
您可以根据需要应用多个策略，每个策略具有不同的操作，
以确保对工作负载的访问安全。

Istio 按以下顺序检查层中的匹配策略：`CUSTOM`、`DENY`，
然后是 `ALLOW`。对于每种类型的操作，Istio 首先检查是否有策略的操作已被应用，
然后检查请求是否匹配策略的规则。如果请求与其中一层中的策略不匹配，
则检查将继续到下一层。

下图详细显示了策略优先级：

{{< image width="50%" link="./authz-eval.png" caption="授权策略优先级">}}

当您将多个授权策略应用于同一工作负载时，Istio 会累加地应用它们。

### 授权策略 {#authorization-policies}

要配置授权策略，请创建一个 [`AuthorizationPolicy` 自定义资源](/zh/docs/reference/config/security/authorization-policy/)。
一个授权策略包括选择器（selector）、动作（action）和一个规则（rules）列表：

- `selector` 字段指定策略的目标
- `action` 字段指定允许还是拒绝请求
- `rules` 指定何时触发动作
    - `rules` 下的 `from` 字段指定请求的来源
    - `rules` 下的 `to` 字段指定请求的操作
    - `rules` 下的 `when` 字段指定应用规则所需的条件

以下示例显示了一个授权策略，该策略允许两个源（服务帐户 `cluster.local/ns/default/sa/sleep`
和命名空间 `dev`），在使用有效的 JWT 令牌发送请求时，可以访问命名空间 `foo`
中带有标签 `app: httpbin` 和 `version: v1` 的工作负载。

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
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

下例显示了一个授权策略，如果请求来源不是命名空间 `foo`，请求将被拒绝。

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin-deny
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: DENY
 rules:
 - from:
   - source:
       notNamespaces: ["foo"]
{{< /text >}}

拒绝策略优先于允许策略。如果请求同时匹配上允许策略和拒绝策略，请求将被拒绝。
Istio 首先评估拒绝策略，以确保允许策略不能绕过拒绝策略。

#### 策略目标 {#policy-target}

您可以通过 `metadata/namespace` 字段和可选的 `selector` 字段来指定策略的范围或目标。
`metadata/namespace` 告诉该策略适用于哪个命名空间。如果将其值设置为根命名空间，
则该策略将应用于网格中的所有命名空间。根命名空间的值是可配置的，默认值为 `istio-system`。
如果设置为任何其他命名空间，则该策略仅适用于指定的命名空间。

您可以使用 `selector` 字段来进一步限制策略以应用于特定工作负载。
`selector` 使用标签选择目标工作负载。`slector` 包含 `{key: value}` 对的列表，
其中 `key` 是标签的名称。如果未设置，则授权策略将应用于与授权策略相同的命名空间中的所有工作负载。

以下示例策略 `allow-read` 允许对 `default` 命名空间中带有标签
`app: products` 的工作负载执行 `"GET"` 和 `"HEAD"` 操作。

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-read
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  action: ALLOW
  rules:
  - to:
    - operation:
         methods: ["GET", "HEAD"]
{{< /text >}}

#### 值匹配 {#value-matching}

授权策略中的大多数字段都支持以下所有匹配模式：

- 完全匹配：即完整的字符串匹配。
- 前缀匹配：`"*"` 结尾的字符串。例如，`"test.abc.*"`
  匹配 `"test.abc.com"`、`"test.abc.com.cn"`、`"test.abc.org"` 等等。
- 后缀匹配：`"*"` 开头的字符串。例如，`"*.abc.com"`
  匹配 `"eng.abc.com"`、`"test.eng.abc.com"` 等等。
- 存在匹配：`*` 用于指定非空的任意内容。您可以使用格式 `fieldname: ["*"]`
  指定必须存在的字段。这意味着该字段可以匹配任意内容，但是不能为空。
  请注意这与不指定字段不同，后者意味着匹配包括空的任意内容。

有一些例外。例如，以下字段仅支持完全匹配：

- `when` 部分下的 `key` 字段
- `source` 部分下的 `ipBlocks`
- `to` 部分下的 `ports` 字段

以下示例策略允许访问前缀为 `/test/*` 或后缀为 `*/info` 的路径。

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: tester
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  action: ALLOW
  rules:
  - to:
    - operation:
        paths: ["/test/*", "*/info"]
{{< /text >}}

#### 排除匹配 {#exclusion-matching}

为了匹配诸如 `when` 字段中的 `notValues`、
`source` 字段中的 `notIpBlocks`、`to` 字段中的 `notPorts`
之类的否定条件，Istio 支持排除匹配。

以下示例：如果请求路径不是 `/healthz`，则要求从请求的 JWT 认证中导出的主体是有效的。
因此，该策略从 JWT 身份验证中排除对 `/healthz` 路径的请求：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: disable-jwt-for-healthz
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  action: ALLOW
  rules:
  - to:
    - operation:
        notPaths: ["/healthz"]
    from:
    - source:
        requestPrincipals: ["*"]
{{< /text >}}

下面的示例拒绝到 `/admin` 路径且不带请求主体的请求：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: enable-jwt-for-admin
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  action: DENY
  rules:
  - to:
    - operation:
        paths: ["/admin"]
    from:
    - source:
        notRequestPrincipals: ["*"]
{{< /text >}}

#### `allow-nothing`、`deny-all` 和 `allow-all` 策略 {#allow-nothing-deny-all-and-allow-all-policy}

以下示例显示了不匹配任何内容的 `ALLOW` 策略。如果没有其他 `ALLOW` 策略，
请求将因"默认拒绝"行为被始终拒绝。

请注意，"默认拒绝"行为仅适用于工作负载随着 `ALLOW`
操作至少有一个授权策略的情况。

{{< tip >}}
从 `allow-nothing` 策略开始并逐步添加更多 `ALLOW`
策略以开放对工作负载的更多访问权限是一种良好的安全实践。
{{< /tip >}}

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-nothing
spec:
  action: ALLOW
  # 若不指定 rules 字段，则策略将从不匹配。
{{< /text >}}

以下示例显示了显式拒绝所有访问的 `DENY` 策略。
即使有另一个 `ALLOW` 策略允许请求，但由于 `DENY` 策略优先于 `ALLOW` 策略，所以将始终拒绝请求。
如果您要临时禁用对工作负载的所有访问，可以使用此策略。

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-all
spec:
  action: DENY
  # rules 字段有一个空白规则，策略将始终匹配。
  rules:
  - {}
{{< /text >}}

以下示例显示了允许完全访问工作负载的 `ALLOW` 策略。
它将使得其他 `ALLOW` 策略无用，因为它将始终允许请求。
如果您要临时暴露工作负载的完全访问权限，可以使用此策略。
请注意，由于 `CUSTOM` 和 `DENY` 策略，请求可能仍被拒绝。

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-all
spec:
  action: ALLOW
  # 这将匹配所有内容。
  rules:
  - {}
{{< /text >}}

#### 自定义条件 {#custom-conditions}

您还可以使用 `when` 部分指定其他条件。
例如，下面的 `AuthorizationPolicy` 定义包括以下条件：
`request.headers [version]` 是 `v1` 或 `v2`。
在这种情况下，key 是 `request.headers [version]`，
它是 Istio 属性 `request.headers`（这是个字典）中的一项。

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
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

#### 认证与未认证身份 {#authenticated-and-unauthenticated-identity}

如果要使工作负载可公开访问，则需要将 `source` 部分留空。
这将允许来自所有（经过认证和未经认证）的用户和工作负载作为请求方，例如：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
 rules:
 - to:
   - operation:
       methods: ["GET", "POST"]
{{< /text >}}

要仅允许经过认证的用户，请将 `principal` 设置为 `"*"`，例如：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["*"]
   to:
   - operation:
       methods: ["GET", "POST"]
{{< /text >}}

### 在普通 TCP 协议上使用 Istio 授权 {#using-Istio-authorization-on-plain-TCP-protocols}

Istio 授权支持工作负载使用任意普通 TCP 协议，如 MongoDB。
在这种情况下，您可以按照与 HTTP 工作负载相同的方式配置授权策略。
不同之处在于某些字段和条件仅适用于 HTTP 工作负载。
这些字段包括：

- 授权策略对象 `source` 部分中的 `request_principals` 字段
- 授权策略对象 `operation` 部分中的 `hosts`、`methods` 和 `paths` 字段

[条件页面](/zh/docs/reference/config/security/conditions/)中列出了支持的条件。
如果您在授权策略中对 TCP 工作负载使用了任何只适用于 HTTP 的字段，Istio 将会忽略它们。

假设您在端口 `27017` 上有一个 MongoDB 服务，下例配置了一个授权策略，
只允许 Istio 网格中的 `bookinfo-ratings-v2` 服务访问该 MongoDB 工作负载。

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: mongodb-policy
  namespace: default
spec:
 selector:
   matchLabels:
     app: mongodb
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/bookinfo-ratings-v2"]
   to:
   - operation:
       ports: ["27017"]
{{< /text >}}

### 对双向 TLS 的依赖 {#dependency-on-mutual-TLS}

Istio 使用双向 TLS 将某些信息从客户端安全地传递到服务器。
在使用授权策略中的以下任何字段之前，必须先启用双向 TLS：

- `source` 部分下的 `principals` 和 `notPrincipals` 字段
- `source` 部分下的 `namespaces` 和 `notNamespaces` 字段
- `source.principal` 自定义条件
- `source.namespace` 自定义条件

请注意，强烈建议始终在 PeerAuthentication 中以 STRICT 双向 TLS 模式使用这些字段，
以避免在 PERMISSIVE 双向 TLS 模式中使用纯文本流量时可能出现的意外请求拒绝或绕过安全策略。

如果您无法启用严格的双向 TLS 模式，
请查看[安全公告](/zh/news/security/istio-security-2021-004)以获取更多详细信息和替代方案。

## 学习更多 {#learn-more}

在学习了上述基本概念之后，您还可以温习下述资料：

- 按照[认证](/zh/docs/tasks/security/authentication/authn-policy)和[授权](/zh/docs/tasks/security/authorization)任务尝试使用安全策略。

- 了解一些可用于提高网格安全性的安全[策略示例](/zh/docs/ops/configuration/security/security-policy-examples)。

- 阅读[常见问题](/zh/docs/ops/common-problems/security-issues/)，
  以便在出现问题时更好地解决安全策略问题。

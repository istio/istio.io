---
title: 安全最佳实践
description: 使用 Istio 保护应用的最佳实践。
force_inline_toc: true
weight: 30
owner: istio/wg-security-maintainers
test: n/a
---

Istio 安全功能提供强大的身份，强大的策略，透明的 TLS 加密，认证，
授权和审计（AAA）工具来保护您的服务和数据。但是，为了更好地使用这些安全特性，
必须按照最佳实践操作。这里建议您在阅读下文前回顾[安全概述](/zh/docs/concepts/security/)。

## 双向 TLS {#mutual-tls}

Istio 会在尽可能[自动](/zh/docs/ops/configuration/traffic-management/tls-configuration/#auto-mtls)
地对流量进行[双向 TLS](/zh/docs/concepts/security/#mutual-tls-authentication) 加密。但是，
默认情况下代理会工作在[宽容模式](/zh/docs/concepts/security/#permissive-mode)下，
这意味着代理会允许双向 TLS 认证的流量以及纯文本流量。

尽管对于渐进式配置或允许流量来自没有 Istio 代理的客户端来说，这个模式是必需的。但这个模式也削弱了安全性，
因此，为了强制在流量进行双向 TLS 认证，
应建议尽早[迁移到 strict 模式](/zh/docs/tasks/security/authentication/mtls-migration/)。

双向 TLS 本身不总是能够保证安全流量，因为它只提供了认证，而不是授权。
这意味着任何拥有有效证书的人都可以访问负载。

为了真正实现安全流量，建议同时配置[授权策略](/zh/docs/tasks/security/authorization/)。
这些配置通过创建细粒度的策略来允许或拒绝流量。例如，您可以配置只允许来自 `app`
命名空间的请求访问 `hello-world` 负载。

## 授权策略 {#authorization-policies}

Istio [授权](/zh/docs/concepts/security/#authorization)在 Istio 安全中扮演了至关重要的角色。
它通过配置正确的授权策略来尽最大可能保护您的集群。因此理解下面这些配置的含义十分重要，因为
Istio 不能替所有的用户决定合适的授权策略。请您完整地阅读以下章节。

### 更安全的授权策略模式 {#safer-authorization-policy-patterns}

#### 使用 default-deny 授权策略模式 {#use-default-deny-patterns}

我们推荐您将 Istio 的策略设置成默认拒绝（default-deny），从而增强您的集群安全性。
default-deny 授权策略意味着您的系统在默认情况下拒绝所有请求，并且您需要定义允许请求的条件。
如果您忘记定义某些条件，对应的流量会被拒绝，而不是被意外的允许。后者是一个典型的安全事故，
而前者只是会可能导致较差的用户体验，或者负载停机，而或者不符合您的服务水平目标（SLO）/服务水平协议（SLA）。

例如，在 [HTTP 流量任务的授权](/zh/docs/tasks/security/authorization/authz-http/)中，命名为
`allow-nothing` 的授权策略确保了所有流量在默认情况下被拒绝。在此之上，
其他的授权策略可以基于特定需求允许流量通过。

#### 使用 `ALLOW-with-positive-matching` 和 `DENY-with-negative-match` 模式 {#use-allow-with-positive-matching-and-deny-with-negative-match-patterns}

尽可能使用 `ALLOW-with-positive-matching` 或 `DENY-with-negative-matching` 授权策略模式。
这些授权策略模式更安全，因为在策略不匹配的情况下，最坏的结果是收到一个意外拒绝403，而不是绕过授权策略。

`ALLOW-with-positive-matching` 授权策略模式是仅对 **positive** 匹配字段（例如
`paths`、`values`）使用 `ALLOW` 动作，而不要使用任何 **negative** 匹配字段（例如
`notPaths`、`notValues`）。

`DENY-with-negative-matching` 授权策略模式是仅对 **negative** 匹配字段（例如
`notPaths`、`notValues`）使用 `DENY` 动作 ，而不要使用任何 **positive**
匹配字段（例如 `paths`、`values`）。

例如，下面的授权策略使用 `ALLOW-with-positive-matching` 模式，允许对路径 `/public` 的请求：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: foo
spec:
  action: ALLOW
  rules:
  - to:
    - operation:
        paths: ["/public"]
{{< /text >}}

上述策略明确列出了允许的路径（`/public`）。这意味着请求路径必须与 `/public`
一致才允许请求。默认情况下将拒绝任何其他请求，从而消除了未知的规范化行为导致策略绕过的风险。

下面是一个使用 `DENY-with-negative-matching` 模式获得相同结果的示例：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: foo
spec:
  action: DENY
  rules:
  - to:
    - operation:
        notPaths: ["/public"]
{{< /text >}}

### 理解授权策略中的路径规范化 {#understand-path-normalization-in-authorization-policy}

授权策略的执行点是 Envoy 代理，而不是后端应用程序中通常的资源访问点。当 Envoy
代理和后端应用程序对请求的解释不同时，就会发生策略不匹配。

策略不匹配会导致意外拒绝或策略绕过。后者通常是一个安全事件，需要立即修复，
这也是我们需要在授权策略中进行路径规范化的原因。

例如，考虑一个授权策略来拒绝路径为 `/data/secret` 的请求。则路径为 `/data//secret`
的请求将不会被拒绝，因为它不符合授权策略中定义的路径，路径中多了一个正斜杠 `/`。

请求通过后端应用程序，后端应用程序返回与路径 `/data/secret` 相同的响应。因为后端应用程序将路径
`/data//secret` 规范化为 `/data/secret`，这是因为它认为双正斜杠 `//` 等同于单个正斜杠 `/`。

在这个例子中，策略执行点（Envoy 代理）对路径的理解与资源访问点（后端应用程序）不同。
这种不同的理解导致了不匹配，随后并绕过了授权策略。

由于以下因素，这成为了一个复杂的问题：

* 缺乏一个明确的规范化标准。

* 不同层的后端和框架有自己特殊的规范化。

* 应用程序甚至可以针对自己的用例进行任意规范化。

Istio 授权策略实现了对各种基本规范化选项的内置支持，以帮助您更好地解决问题：

* 参考[配置路径规范化选项的指南](/zh/docs/ops/best-practices/security/#guideline-on-configuring-the-path-normalization-option)来了解您可能要使用哪些规范化选项。

* 参考[自定义系统的路径规范化](/zh/docs/ops/best-practices/security/#customize-your-system-on-path-normalization)了解每个规范化选项的细节。

* 如果您需要任何不支持的规范化选项，请参阅[不支持的规范化的缓解措施](/zh/docs/ops/best-practices/security/#mitigation-for-unsupported-normalization)，
  了解和选择其他解决方案。

### 配置路径规范化选项的指导原则 {#guideline-on-configuring-the-path-normalization-option}

#### 案例 1：您不需要规范化 {#case-1:-you-do-not-need-normalization-at-all}

在深入了解配置规范化的细节之前，您应该首先确定是否需要规范化。

如果您不使用授权策略或者您的授权策略不使用任何 `path` 字段，
则不需要规范化。

如果您所有的授权策略都遵循[更安全的授权模式](/zh/docs/ops/best-practices/security/#safer-authorization-policy-patterns)，
您可能不需要规范化, 在最坏的情况下，这会导致意外拒绝而不是策略绕过。

#### 案例 2：您需要规范化，但不确定使用哪个规范化选项 {#case-2:-you-need-normalization-but-not-sure-which-normalization-option-to-use}

如果您需要规范化，但不知道要使用哪个选项。最安全的选择是最严格的规范化选项，
它在授权策略中提供了最高级别的规范化。

这种情况经常发生，因为复杂的多层系统使人们实际上不可能弄清楚在一个请求之外究竟发生了什么规范化。

如果它已经满足了您的要求，并且您确信它的含义，您可以使用不太严格的规范化选项。

无论是哪种方案，都要确保您为您的需求编写了正面和负面的测试，以验证规范化是否按预期工作。
这些测试有助于发现由误解引起的潜在旁路问题，或不完全了解您的请求所发生的规范化而造成的潜在绕过问题。

参考[自定义系统的路径规范化](/zh/docs/ops/best-practices/security/#customize-your-system-onpath-normalization)以了解更多配置规范化选项的细节。

#### 案例 3：您需要一个不支持的规范化选项 {#case-3:-you-need-an-unsupported-normalization-option}

如果您需要 Istio 还不支持的特定规范化选项，
请按照[不支持规范化的缓解措施](/zh/docs/ops/best-practices/security/#mitigation-for-unsupported-normalization)来获得自定义规范化支持或为
Istio 社区创建功能请求。

### 在路径规范化上自定义系统 {#customize-your-system-on-path-normalization}

Istio 授权策略能够基于 HTTP 请求的 URL 路径实现。
[路径规范化(即 URI 规范化)](https://en.wikipedia.org/wiki/URI_normalization)修改并标准化了入站请求的路径，
因此规范化后的路径可以按照标准进行处理。语法上来说，不同的路径在规范化之后可能是一致的。

在评估授权策略和路由请求之前， Istio 支持以下的请求路径规范化方案：

| 选项 | 描述 | 示例 |
| --- | --- | --- |
| `NONE` | 没有规范化。Envoy 代理受到的一切都按照原样转发到后端负载。 | `../%2Fa../b` 将被授权策略评估并且发送到您的负载。 |
| `BASE` | 这是目前 Istio 使用的**默认**安装选项。此选项将[规范化路径](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path)应用于 Envoy 代理上。该规范符合 [RFC 3986](https://tools.ietf.org/html/rfc3986) 同时附加规范将反斜线转化为斜线。 | `/a/../b` 规范为 `/b`。 `\da` 规范为 `/da`。 |
| `MERGE_SLASHES` | 在 **BASE** 规范化之后合并斜线。 | `/a//b` 规范为 `/a/b`。 |
| `DECODE_AND_MERGE_SLASHES` | 当您默认允许所有流量时，这为最严格的设置。若您想要详尽地测试您的路由授权策略时，这是推荐选项。在 `MERGE_SLASHES` 之前，被[百分位编码](https://tools.ietf.org/html/rfc3986#section-2.1)的斜线和反斜线字符 (`%2F`, `%2f`, `%5C` and `%5c`) 解码为 `/` 或 `\`。 | `/a%2fb` 规范为 `/a/b`。 |

{{< tip >}}
这项配置声明在 [mesh config](/zh/docs/reference/config/istio.mesh.v1alpha1/)
的 [`pathNormalization`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization)
字段。
{{< /tip >}}

着重强调，规范化算法按照以下顺序执行：
1. 百分位解码 `%2F`, `%2f`, `%5C` 和 `%5c`。
1. [RFC 3986](https://tools.ietf.org/html/rfc3986) 以及其他由
   Envoy [`normalize_path`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path)
   选项实现的规范。
1. 合并斜线。

{{< warning >}}
尽管这些规范化选项是 HTTP 标准和业界推荐设置。应用本身也可能选择使用自定义的 URL。
因此，当使用否定性的策略时，确保理解您的应用。
{{< /warning >}}

完整的所支持规范化列表，请参考[授权策略规范](/zh/docs/reference/config/security/normalization/)。

### 配置示例 {#examples-of-configuration}

确保 Envoy 对于请求路径的规范化能够符合后端负载期望对于您的系统安全十分重要。以下示例能够作为您系统配置的参考。
已经规范化后的 URL 路径，或者因选择了 **NONE** 而保留的原始 URL 路径将会：

1. 用于对授权策略的检查
1. 转发到后端应用

| 您的应用... | 选择... |
| --- | --- |
| 依赖代理完成规范化。 | `BASE`, `MERGE_SLASHES` 或 `DECODE_AND_MERGE_SLASHES` |
| 根据 [RFC 3986](https://tools.ietf.org/html/rfc3986) 规范化请求路径并且不合并斜线 | `BASE` |
| 根据 [RFC 3986](https://tools.ietf.org/html/rfc3986) 规范化请求路径，合并斜线但是不解码被[百分位编码](https://tools.ietf.org/html/rfc3986#section-2.1)的斜线 | `MERGE_SLASHES` |
| 根据 [RFC 3986](https://tools.ietf.org/html/rfc3986) 规范化请求路径，合并斜线并解码被[百分位编码](https://tools.ietf.org/html/rfc3986#section-2.1)的斜线 | `DECODE_AND_MERGE_SLASHES` |
| 采用与 [RFC 3986](https://tools.ietf.org/html/rfc3986) 不兼容的方式处理请求路径。 | `NONE` |

### 如何配置 {#how-to-configure}

您可以使用 `istioctl` 命令来更新[网格配置](/zh/docs/reference/config/istio.mesh.v1alpha1/)：

{{< text bash >}}
$ istioctl upgrade --set meshConfig.pathNormalization.normalization=DECODE_AND_MERGE_SLASHES
{{< /text >}}

或者修改您的 operator 来复写文件

{{< text bash >}}
$ cat <<EOF > iop.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    pathNormalization:
      normalization: DECODE_AND_MERGE_SLASHES
EOF
$ istioctl install -f iop.yaml
{{< /text >}}

或者，如果您想直接修改网格配置，您可以将 [`pathNormalization`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization)
加入[网格配置](/zh/docs/reference/config/istio.mesh.v1alpha1/)中，即修改 `istio-system`
命名空间中的 `istio-<REVISION_ID>` configmap。例如，如果您使用 `DECODE_AND_MERGE_SLASHES`
选项，您需要按照如下修改网格配置：

{{< text yaml >}}
apiVersion: v1
  data:
    mesh: |-
      ...
      pathNormalization:
        normalization: DECODE_AND_MERGE_SLASHES
      ...
{{< /text >}}

### 不支持规范化的缓解措施 {#mitigation-for-unsupported-normalization}

本节介绍了不支持规范化的各种缓解措施。当您需要一个特定的 Istio 不支持的规范化时，这些措施可能很有用。

请确保您彻底理解缓解措施并谨慎使用，因为有些缓解措施依赖于 Istio 范围之外的东西，也不被 Istio 支持。

#### 自定义规范化逻辑 {#custom-normalization-logic}

您可以使用 WASM 或 Lua 过滤器应用自定义规范化逻辑。建议使用 WASM 过滤器，因为 Istio 官方支持并使用它。
您可以使用 Lua 过滤器进行快速概念验证 DEMO，但我们这样做不建议在生产环境中使用 Lua 过滤器，因为 Istio 不支持它。

#### 大小写规范化 {#case-normalization}

在一些环境下，需要不区分授权策略中路径的大小写。
例如，将 `https://myurl/get` 和 `https://myurl/GeT` 视为等效。
在这些情况下，可以使用如下的 `EnvoyFilter`。
此设置将同时改变策略对比所用的以及传递给应用的路径。

{{< text syntax=yaml snip_id=ingress_case_insensitive_envoy_filter >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: ingress-case-insensitive
  namespace: istio-system
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_FIRST
      value:
        name: envoy.lua
        typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
            inlineCode: |
              function envoy_on_request(request_handle)
                local path = request_handle:headers():get(":path")
                request_handle:headers():replace(":path", string.lower(path))
              end
{{< /text >}}

#### 编写主机匹配策略 {#writing-host-match-policies}

Istio 为主机名本身和所有匹配的端口生成主机名。例如，一个虚拟服务或网关生成与 `example.com`
主机匹配的 `example.com` 和 `example.com:*` 的配置。但是，完全匹配授权策略只匹配为
`hosts` 或 `notHosts` 字段中给出的精确字符串。

[授权策略规则](/zh/docs/reference/config/security/authorization-policy/#Rule)匹配的主机应该写成使用前缀匹配而不是完全匹配。
例如，对于匹配 Envoy 配置生成的 `AuthorizationPolicy` 的主机名如 `example.com`，您可以使用
`hosts: ["example.com", "example.com:*"]`，如下面的 `AuthorizationPolicy` 所示：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-host
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - to:
    - operation:
        hosts: ["example.com", "example.com:*"]
{{< /text >}}

此外，`host` 和 `notHosts` 字段通常应该只用在进入网格的外部流量的网关上，而不是在网格内流量的 Sidecar
上，这是因为服务器端的 Sidecar（执行授权策略的地方）在将请求重定向到应用程序时，不使用 `Host` 字段
由于客户端可以使用明确的 IP 地址和任意的 `Host` 头而不是服务名称来访问应用程序，这使得 `host` 和
`notHost` 在 Sidecar 上没有意义。

如果您真的需要基于 sidecar 上的 `Host` 标头执行访问控制，请遵循
[default-deny 授权策略模式](/zh/docs/ops/best-practices/security/#use-default-deny-patterns)，
如果客户端使用任意的 `Host` 标头，它将拒绝该请求。

#### 专门的网络应用防火墙 (WAF) {#specialized-web-application-firewall}

许多专门的 Web 应用程序防火墙 (WAF) 产品提供额外的规范化选项。它们可以部署在 Istio 入口网关的前端，
以规范化进入网格的请求。然后，授权策略将在规范化的请求上执行。请参考您的特定 WAF 产品以配置规范化选项。

#### 对 Istio 的功能请求 {#feature-request-to-istio}

如果您认为 Istio 应该正式支持某个特定的规范化，您可以按照
[报告漏洞](/zh/docs/releases/security-vulnerabilities/#reporting-a-vulnerability)页面，
向 Istio 产品安全工作组发送关于特定规范化的功能请求，以便进行初步评估。

在未与 Istio 产品安全工作组联系之前，请不要公开任何问题，因为该问题可能被视为需要私下修复的安全漏洞。

如果 Istio 产品安全工作组评估该功能请求不属于安全漏洞，将在公开场合打开一个问题，以进一步讨论该功能请求。

### 已知限制 {#known-limitations}

本节列出了授权策略的已知限制。

#### 不支持服务器优先 TCP 协议 {#server-first-tcp-protocols-are-not-supported}

服务器优先 TCP 协议意味着服务器应用程序将在接受 TCP 连接后立即发送第一个字节，然后再从客户端接收任何数据。

目前，授权策略只支持对入站流量实施访问控制，而不支持出站流量。

它也不支持服务器优先 TCP 协议，因为服务器应用程序甚至在收到客户端的任何数据之前就已发送了第一个字节。
在这种情况下，服务器发送的初始第一个字节直接返回给客户端，而无需经过授权策略的访问控制检查。

如果由服务器优先 TCP 协议发送的第一个字节包含任何需要通过适当授权保护的敏感数据，则不应使用授权策略。

如果第一个字节不包含任何敏感数据，您仍然可以在这种情况下使用授权策略，例如，第一个字节是用来与任何客户公开访问的数据协商连接的。
对于客户端在第一个字节之后发送的以下请求，授权策略将照常工作。

## 理解流量拦截的局限性 {#understand-traffic-capture-limitations}

Istio Sidecar 原理为拦截入站和出站流量并将它们转发到 Sidecar 代理。

但是，并不是**全部**的流量都被拦截：

* 转发只针对基于 TCP 的流量。任何 UDP 或 ICMP 包不会被拦截或更改。
* 入站拦截在很多 [Sidecar 使用的端口](/zh/docs/ops/deployment/requirements/#ports-used-by-istio)以及端口
  22 不生效。此列表可以通过例如 `traffic.sidecar.istio.io/excludeInboundPorts` 的设置拓展。
* 出站拦截可以通过类似 `traffic.sidecar.istio.io/excludeOutboundPorts` 的配置以及其他多种方式取消。

总的来说，一个应用和他的 Sidecar 代理之间的安全边界微乎其微。Sidecar 设置基于 Pod 粒度设置，
并且二者运行在同一个网络/进程空间。因此，应用可能移除拦截规则，并且移除，修改，或替换 Sidecar
代理。这允许一个 Pod 将出站流量有意地绕过它的 Sidecar 或者 有意允许入站流量绕过它的 Sidecar。

因此，仅依赖 Istio 来拦截全部流量是不安全的。取而代之，正确的安全边界是，
一个客户端不应该能够绕过**另一个** Pod 的 Sidecar。

例如，如果在端口 `9080` 上运行 `reviews` 应用，便应认为所有从 `productpage`
应用来的流量都应被 `review` Sidecar 代理拦截，在 Sidecar 上便可以进行 Istio 认证和授权策略配置。

### 基于 `NetworkPolicy` 的纵深防御 {#defense-in-depth-with-network-policy}

为了进一步确保流量安全， Istio 策略可以基于 Kubernetes
[网络策略](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)。
这将启动强大的[纵深防御](https://en.wikipedia.org/wiki/Defense_in_depth_(computing))策略来进一步确保您的网格安全性。

例如，您可以只允许流量通过端口 `9080` 进入应用 `reviews`。在存在达不到安全标准的
Pod 或者有安全弱点情况下，这可能限制或者阻止攻击者。

根据实际执行情况，对网络策略的更改可能不会影响 Istio 代理中的现有连接。您可能需要在应用策略后重新启动
Istio 代理，以便现有的连接将被关闭，新的连接将受到新策略的约束。

### 确保 egress 流量安全 {#securing-egress-traffic}

一个常见的误解是类似 [`outboundTrafficPolicy: REGISTRY_ONLY`](/zh/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services)
的设置可以作为安全策略来阻止访问未声明服务。但是如上文所说这并不能作为一个很强的安全边界，
而充其量应视为尽力而为。

尽管上面的设置可以防止意外的依赖，如果您想要确保 egress 的流量安全并强制所有的出站流量都通过代理，
您应该使用 [Egress Gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/)。
当结合[网络策略](/zh/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies)一起使用时，
您可以强制所有出站流量，或者部分通过 egress 网关。这确保了即使客户端因意外或者被恶意绕过它的代理，请求将会被阻止。

## 当使用 TLS 源时在目标规则上配置 TLS 验证 {#configure-TLS-verification-in-destination-rule-when-using-TLS-origination}

Istio 提供了从 Sidecar 代理或者网关上[发起 TLS](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)
的能力。这使得从应用发出的纯文本 HTTP 流量可以透明地“升级”到 HTTPS。

当进行 `DestinationRule` 中的 `tls` 字段配置时，应格外注意 `caCertificates`、`subjectAltNames` 和 `sni` 字段。
通过在 Istiod 上启用环境变量 `VERIFY_CERTIFICATE_AT_CLIENT=true` ，可以从系统证书存储的 CA 证书自动设置 `caCertificate` 。
如果自动使用的操作系统 CA 证书只适用于特定的主机，环境变量 `VERIFY_CERTIFICATE_AT_CLIENT=false` 在 Istiod 上，
`caCertificates` 可以被设置为 `system` 在所需的 `DestinationRule` 中。
在 `DestinationRule` 中指定 `caCertificates` 将被优先考虑，操作系统 CA 证书将不被使用。
默认情况下，出口流量在 TLS 握手期间不发送 SNI。
SNI必须在 `DestinationRule` 中设置，以确保主机正确处理请求。

{{< warning >}}
为了验证服务器的证书，必须同时设置 `caCertificates` 和 `subjectAltNames`。

仅仅根据 CA 验证服务器提交的证书是不够的，因为还必须验证主题替代名称。

如果 `VERIFY_CERTIFICATE_AT_CLIENT` 被设置，但 `subjectAltNames` 没有被设置，那么您就没有验证所有证书。

如果服务器未使用 CA 证书，则无论是否设置 `subjectAltNames` 都将不使用。
{{< /warning >}}

例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: google-tls
spec:
  host: google.com
  trafficPolicy:
    tls:
      mode: SIMPLE
      caCertificates: /etc/ssl/certs/ca-certificates.crt
      subjectAltNames:
      - "google.com"
      sni: "google.com"
{{< /text >}}

## 网关 {#gateways}

当运行一个 Istio [网关](/zh/docs/tasks/traffic-management/ingress/)时候，以下的资源都将参与：

* `Gateway` 控制了网关的端口和 TLS 设置。
* `VirtualService` 控制了路由逻辑。虚拟服务通过 `Gateway` 资源的 `gateways` 的字段直接被引用。
   并且`Gateway` 和 `VirtualService` 资源中的 `hosts` 字段需保持一致。

### 限制 `Gateway` 创建权限 {#restrict-gateway-creation-privileges}

Istio 推荐将网关资源创建权限只分配给信任的集群管理员。这可以通过
[Kubernetes RBAC 策略](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/rbac/)
或者类似 [Open Policy Agent](https://www.openpolicyagent.org/) 的工具实现。

### 避免过于宽泛的 `hosts` 配置 {#avoid-overly-broad-hosts-configurations}

如果可能，请避免将 `Gateway` 资源的 `hosts` 字段定义地过于宽泛。

例如，以下的配置将允许任意的 `VirtualService` 绑定到 `Gateway` 之上，
很有可能暴露出不应暴露的域：

{{< text yaml >}}
servers:
- port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "*"
{{< /text >}}

以上设置应该限制于只允许特定的域或命名空间：

{{< text yaml >}}
servers:
- port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "foo.example.com" # Allow only VirtualServices that are for foo.example.com
  - "default/bar.example.com" # Allow only VirtualServices in the default namespace that are for bar.example.com
  - "route-namespace/*" # Allow only VirtualServices in the route-namespace namespace for any host
{{< /text >}}

### 隔离敏感负载 {#isolate-sensitive-services}

有可能存在对敏感负载进行强制的严格物理隔离的情况。例如，您可能希望将敏感的域
`payments.example.com` 运行在[专用的网关实例](/zh/docs/setup/install/istioctl/#configure-gateways)上，
同时在一个共享的网关实例上运行多个较不敏感的域，例如 `blog.example.com` 和 `store.example.com`。
这种方式提供了更好的纵深防御并且利于实现监管准则。

### 显式阻止所有的敏感 http 主机被宽泛的 SNI 匹配 {#explicitly-disable-all-the-sensitive-http-host-under-relaxed-SNI-host-matching}

使用多个 `Gateway` 资源来在不同的主机上定义多个双向或者单向 TLS 是很合理的。
例如，在 SNI 主机 `admin.example.com` 上使用双向 TLS， 在 SNI 主机 `*.example.com` 上使用单向 TLS。

{{< text yaml >}}
kind: Gateway
metadata:
  name: guestgateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "*.example.com"
    tls:
      mode: SIMPLE
---
kind: Gateway
metadata:
  name: admingateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - admin.example.com
    tls:
      mode: MUTUAL
{{< /text >}}

如果以上设置是必要的，那么推荐您显式地将 http 主机 `admin.example.com` 从配置了 `*.example.com`
的虚拟服务中剔除。因为现在 [envoy 代理不要求](https://github.com/envoyproxy/envoy/issues/6767)
http 1 头部 `Host` 或者 http 2 伪头部 `:authority` 字段遵守 SNI 限制。 这意味着攻击者可以复用访客的
SNI TLS 连接来访问管理员`虚拟服务`。而 http 回复代码 421 的设计目的便是 `Host` SNI 不匹配并且可以用于以上阻止目的。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: disable-sensitive
spec:
  hosts:
  - "admin.example.com"
  gateways:
  - guestgateway
  http:
  - match:
    - uri:
        prefix: /
    fault:
      abort:
        percentage:
          value: 100
        httpStatus: 421
    route:
    - destination:
        port:
          number: 8000
        host: dest.default.cluster.local
{{< /text >}}

## 协议探测 {#protocol-detection}

Istio 可以[自动确定流量协议](/zh/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection)。
但为了避免意外或者有意的误检测，从而导致意外流量行为发生。推荐[显式地声明协议](/zh/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)。

## CNI 网络容器接口 {#CNI}

为了透明地劫持所以流量， Istio 依赖 通过 `istio-init` `initContainer` 配置 `iptables` 规则。
这增加了一个[要求](/zh/docs/ops/deployment/requirements/)，即需要提供给 Pod `NET_ADMIN`
和 `NET_RAW` [兼容性](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)。

为了减少给予 Pods 的权限， Istio 提供了 [CNI 插件](/zh/docs/setup/additional-setup/cni/)功能，
即不再需要以上权限。

## 使用精简 docker 镜像 {#use-hardened-docker-images}

Istio 默认 docker 镜像，包括那些控制面，网关， Sidecar 代理正在使用的镜像，都是基于 `ubuntu`。
这提供了多种工具，例如 `bash` 以及 `curl`，这权衡了提供便利和增加攻击接口之间的利弊。

同时 Istio 也提供了更精简的基于 [distroless images](/zh/docs/ops/configuration/security/harden-docker-images/)
的镜像，此镜像减少了其中的依赖。

{{< warning >}}
Distroless 镜像目前仍是 alpha 特性。
{{< /warning >}}

## 发布以及安全策略 {#release-and-security-policy}

为了确保您的集群拥有针对安全漏洞的最新的安全补丁，保持和最新的 Istio 补丁同步至关重要。
同时应该确保您使用的是仍在接收安全补丁的[支持发布版本](/zh/docs/releases/supported-releases)。

## 检测无效配置 {#detect-invalid-configurations}

尽管 Istio 在创建资源时提供了验证，但是这些检查不能够涵盖所有可能的配置问题，从而导致不能在网格中生效。
这可能导致配置的策略被意外地忽略了，从而导致意外错误。

* 在配置前后均运行 `istioctl analyze` 来确保有效性。
* 监测控制面是否有被拒绝配置。被拒绝信息会在日志以及 `pilot_total_xds_rejects` 指标中显示。
* 测试您的配置确保出现的是您期待的结果。对于安全策略来说，您可以运行正向和反向的测试来确保您不会意外地对流量进行过多或者过少的约束。

## 避免使用 alpha 或者实验阶段特性 {#avoid-alpha-and-experimental-features}

所有的 Istio 特性以及 APIs 都定义了[特性阶段](/zh/docs/releases/feature-stages/)，
即定义了它的稳定性，弃用策略以及安全策略。

因为 alpha 以及实验阶段特性没有有力的安全保障，因此推荐尽量避免使用它们。
使用这些特性导致的安全问题可能不会马上被修复或者不符合标准[安全漏洞](/zh/docs/releases/security-vulnerabilities/)流程。

为了确定您集群中使用的特性所在的阶段，请参考 [Istio 特性](/zh/docs/releases/feature-stages/#istio-features)列表。

<!-- In the future, we should document the `istioctl` command to check this when available. -->

## 锁定的端口 {#lock-down-ports}

Istio 配置了[一系列锁定的端口](/zh/docs/ops/deployment/requirements/#ports-used-by-istio)为了增强安全性。

### 控制面 {#control-plane}

Istiod 为了便利暴露了几个未认证的纯本文端口。理想情况下，他们应该被关闭：

* 端口 `8080` 暴露了调试接口，提供了针对集群状态细节的读取权限。
  这可以通过在 Istiod 设置环境变量 `ENABLE_DEBUG_ON_HTTP=false` 来关闭。警告：许多 `istioctl`
  命令依赖该接口并且可能无法运行如果该接口被关闭。
* 端口 `15010` 将 XDS 服务暴露为纯文本。这可以通过在 Istiod 部署中添加 `--grpcAddr=""` 标示来关闭。
  注释：高度敏感的服务，例如证书签发和分发服务，绝不允许运行在纯文本上。

### 数据面 {#data-plane}

代理暴露了一系列端口。暴露给外部的是端口 `15090` (遥测) 和 端口 `15021` (健康检测)。
端口 `15020` 和 `15000` 提供了调试终端。这两者只暴露给 `localhost`。
因此结果是，应用运行在了代理也有访问权限的同一个 Pod 中，即 Sidecar 和应用之间没有信任边界。

## 配置第三方服务账户 tokens {#configure-third-party-service-account-tokens}

为了认证 Istio 数据面， Istio 代理使用服务账户 tokens。 Kubernetes 支持两种类型的 tokens ：

* 第三方 tokens，拥有有范围限制的受众以及有效期。
* 第一方 tokens，没有有效期以及挂在到全部 Pods 上。

因为第一方 token 的性质较为不安全， Istio 默认使用第三方 tokens。但是该特性并未在全部的 Kubernetes 平台上启用。

如果您使用 `istioctl` 来安装，将会自动检测是否支持第三方 tokens。同时这也可以进行手动配置
`--set values.global.jwtPolicy=third-party-jwt` 或 `--set values.global.jwtPolicy=first-party-jwt`。

为了确定您的集群是否支持第三方 tokens，可以查找 `TokenRequest` API。如果没有得到以下回复，那么该特性尚未支持：

{{< text bash >}}
$ kubectl get --raw /api/v1 | jq '.resources[] | select(.name | index("serviceaccounts/token"))'
{
    "name": "serviceaccounts/token",
    "singularName": "",
    "namespaced": true,
    "group": "authentication.k8s.io",
    "version": "v1",
    "kind": "TokenRequest",
    "verbs": [
        "create"
    ]
}
{{< /text >}}

尽管大多数云供应商现已支持该特性，许多的本地开发工具以及自定义安装还在 Kubernetes 1.20 之前的版本。
因此为了启用该特性，请参考 [Kubernetes 文档](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection)。

## 配置下游连接数限制 {#configure-a-limit-on-downstream-connections}

默认情况，Istio（以及 Envoy）没有对下游连接数的限制。但这可能被恶意活动所利用(见
[security bulletin 2020-007](/zh/news/security/istio-security-2020-007/))。
为了解决，您需要在您的环境中配置合适的连接数限制。

### 配置 `global_downstream_max_connections` 值 {#configure-global_downstream_max_connections-value}

在安装过程中可以提供以下配置:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    runtimeValues:
      "overload.global_downstream_max_connections": "100000"
{{< /text >}}

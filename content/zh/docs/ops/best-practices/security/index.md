---
title: 安全最佳实践
description: 使用 Istio 保护应用的最佳实践。
force_inline_toc: true
weight: 30
owner: istio/wg-security-maintainers
test: no
---

Istio 安全功能提供强大的身份，强大的策略，透明的 TLS 加密，认证，授权和审计（AAA）工具来保护您的服务和数据。但是，为了更好地使用这些安全特性，必须按照最佳实践操作。这里建议您在阅读下文前回顾[安全概述](/zh/docs/concepts/security/)。

## 双向 TLS{#mutual-tls}

Istio 会在尽可能[自动](/zh/docs/ops/configuration/traffic-management/tls-configuration/#auto-mtls)地对流量进行[双向 TLS](/zh/docs/concepts/security/#mutual-tls-authentication) 加密。但是，默认情况下代理会工作在[宽容模式](/zh/docs/concepts/security/#permissive-mode)下，这意味着代理会允许双向 TLS 认证的流量以及纯文本流量。

尽管对于渐进式配置或允许流量来自没有 Istio 代理的客户端来说，这个模式是必需的。这个模式也削弱了安全。因此，建议尽早[迁移到 strict 模式](/zh/docs/tasks/security/authentication/mtls-migration/)，为了强制在流量进行双向 TLS 认证。

双向 TLS 本身不总是能够保证安全流量，因为它只提供了认证，而不是授权。这意味着任何拥有有效证书的人都可以访问负载。

为了真正实现安全流量，建议同时配置[授权策略](/zh/docs/tasks/security/authorization/)。这些配置通过创建细粒度的策略来允许或拒绝流量。例如，您可以配置只允许来自 `app` 命名空间的请求访问 `hello-world` 负载。

## 授权策略{#authorization-policies}

Istio [授权](/zh/docs/concepts/security/#authorization)在 Istio 安全中扮演了至关重要的角色。它通过配置正确的授权策略来尽最大可能保护您的集群。因此理解下面这些配置的含义十分重要，因为 Istio 不能替所有的用户决定合适的授权策略。请您完整地阅读以下章节。

### 配置 default-deny 授权策略{#apply-default-deny-authorization-policies}

我们推荐您将 Istio 的策略设置成默认拒绝(default-deny)，从而增强您的集群安全性。 default-deny 授权策略意味着您的系统在默认情况下拒绝所有请求，并且您需要定义允许请求的条件。如果您忘记定义某些条件，对应的流量会被拒绝，而不是被意外的允许。后者是一个典型的安全事故，而前者只是会可能导致较差的用户体验，或者负载停机，而或者不符合您的服务水平目标/服务水平协议。

例如，在 [HTTP 流量任务的授权](/zh/docs/tasks/security/authorization/authz-http/)中，命名为 `allow-nothing` 的授权策略确保了所有流量在默认情况下被拒绝。在此之上，其他的授权策略可以基于特定需求允许流量通过。

### 在路径规范化上自定义系统{#customize-your-system-on-path-normalization}

Istio 授权策略能够基于 HTTP 请求的 URL 路径实现。[路径规范化(即 URI 规范化)](https://en.wikipedia.org/wiki/URI_normalization) 修改并标准化了入站请求的路径，因此规范化后的路径可以按照标准进行处理。语法上来说，不同的路径在规范化之后可能是一致的。

在评估授权策略和路由请求之前， Istio 支持以下的请求路径规范化方案：

| 选项 | 描述 | 示例 |
| --- | --- | --- |
| `NONE` | 没有规范化。Envoy 代理受到的一切都按照原样转发到后端负载。 | `../%2Fa../b` 将被授权策略评估并且发送到您的负载。 |
| `BASE` | 这是目前 Istio 使用的*默认*安装选项。此选项将[规范化路径](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path)应用于 Envoy 代理上。该规范符合 [RFC 3986](https://tools.ietf.org/html/rfc3986) 同时附加规范将反斜线转化为斜线。 | `/a/../b` 规范为 `/b`。 `\da` 规范为 `/da`。 |
| `MERGE_SLASHES` | 在 _BASE_ 规范化之后合并斜线。 | `/a//b` 规范为 `/a/b`。 |
| `DECODE_AND_MERGE_SLASHES` | 当您默认允许所有流量时，这为最严格的设置。若您想要详尽地测试您的路由授权策略时，这是推荐选项。在 `MERGE_SLASHES` 之前，被[百分位编码](https://tools.ietf.org/html/rfc3986#section-2.1)的斜线和反斜线字符 (`%2F`, `%2f`, `%5C` and `%5c`) 解码为 `/` 或 `\`。 | `/a%2fb` 规范为 `/a/b`。 |

{{< tip >}}
这项配置声明在 [mesh config](/zh/docs/reference/config/istio.mesh.v1alpha1/) 的 [`pathNormalization`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization) 字段。
{{< /tip >}}

着重强调，规范化算法按照以下顺序执行：
1. 百分位解码 `%2F`, `%2f`, `%5C` 和 `%5c`。
1. [RFC 3986](https://tools.ietf.org/html/rfc3986) 以及其他由 Envoy [`normalize_path`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path) 选项实现的规范。
1. 合并斜线。

{{< warning >}}
尽管这些规范化选项是 HTTP 标准和业界推荐设置。应用本身也可能选择使用自定义的 URL。因此，当使用否定性的策略时，确保理解您的应用。
{{< /warning >}}

完整的所支持规范化列表，请参考[授权策略规范](/zh/docs/reference/config/security/normalization/)。

### 配置示例{#examples-of-configuration}

确保 Envoy 对于请求路径的规范化能够符合后端负载期望对于您的系统安全十分重要。以下示例能够作为您系统配置的参考。
已经规范化后的 URL 路径，或者因选择了 _NONE_ 而保留的原始 URL 路径将会：

1. 用于对授权策略的检查
1. 转发到后端应用

| 您的应用... | 选择... |
| --- | --- |
| 依赖代理完成规范化。 | `BASE`, `MERGE_SLASHES` 或 `DECODE_AND_MERGE_SLASHES` |
| 根据 [RFC 3986](https://tools.ietf.org/html/rfc3986) 规范化请求路径并且不合并斜线 | `BASE` |
| 根据 [RFC 3986](https://tools.ietf.org/html/rfc3986) 规范化请求路径，合并斜线但是不解码被[百分位编码](https://tools.ietf.org/html/rfc3986#section-2.1)的斜线 | `MERGE_SLASHES` |
| 根据 [RFC 3986](https://tools.ietf.org/html/rfc3986) 规范化请求路径，合并斜线并解码被[百分位编码](https://tools.ietf.org/html/rfc3986#section-2.1)的斜线 | `DECODE_AND_MERGE_SLASHES` |
| 采用与 [RFC 3986](https://tools.ietf.org/html/rfc3986) 不兼容的方式处理请求路径。 | `NONE` |

### 如何配置{#how-to-configure}

您可以使用 `istioctl` 命令来更新[网格配置](/zh/docs/reference/config/istio.mesh.v1alpha1/):

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

或者，如果您想直接修改网格配置，您可以将 [`pathNormalization`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization) 加入[网格配置](/zh/docs/reference/config/istio.mesh.v1alpha1/)中，即修改 `istio-system` 命名空间中的 `istio-<REVISION_ID>` configmap。
例如，如果您使用 `DECODE_AND_MERGE_SLASHES` 选项，您需要按照如下修改网格配置：

{{< text yaml >}}
apiVersion: v1
  data:
    mesh: |-
      ...
      pathNormalization:
        normalization: DECODE_AND_MERGE_SLASHES
      ...
{{< /text >}}

### 较不常见规范化配置{#less-common-normalization-configurations}

#### 大小写规范化{#case-normalization}

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
            subFilter:
              name: "envoy.filters.http.router"
    patch:
      operation: INSERT_BEFORE
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

## 理解流量拦截的局限性{#understand-traffic-capture-limitations}

Istio Sidecar 原理为拦截入站和出站流量并将它们转发到 Sidecar 代理。

但是，并不是*全部*的流量都被拦截：

* 转发只针对基于 TCP 的流量。任何 UDP 或 ICMP 包不会被拦截或更改。
* 入站拦截在很多 [Sidecar 使用的端口](/zh/docs/ops/deployment/requirements/#ports-used-by-istio) 以及端口 22 不生效。此列表可以通过例如 `traffic.sidecar.istio.io/excludeInboundPorts` 的设置拓展。
* 出站拦截可以通过类似 `traffic.sidecar.istio.io/excludeOutboundPorts` 的配置以及其他多种方式取消。

总的来说，一个应用和他的 Sidecar 代理之间的安全边界微乎其微。Sidecar 设置基于 Pod 粒度设置，并且二者运行在同一个网络/进程空间。因此，应用可能移除拦截规则，并且移除，修改，或替换 Sidecar 代理。这允许一个 Pod 将出站流量有意地绕过它的 Sidecar 或者 有意允许入站流量绕过它的 Sidecar。

因此，仅依赖 Istio 来拦截全部流量是不安全的。取而代之，正确的安全边界是，一个客户端不应该能够绕过*另一个* Pod 的 Sidecar。

例如，如果在端口 `9080` 上运行 `reviews` 应用，便应认为所有从 `productpage` 应用来的流量都应被 `review` Sidecar 代理拦截，在 Sidecar 上便可以进行 Istio 认证和授权策略配置。

### 基于 `NetworkPolicy` 的纵深防御{#defense-in-depth-with-network-policy}

为了进一步确保流量安全， Istio 策略可以基于 Kubernetes [网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)。这将启动强大的[纵深防御](https://en.wikipedia.org/wiki/Defense_in_depth_(computing))策略来进一步确保您的网格安全性。

例如，您可以只允许流量通过端口 `9080` 进入应用 `reviews`。在存在达不到安全标准的 Pod 或者有安全弱点情况下，这可能限制或者阻止攻击者。

### 确保 egress 流量安全{#securing-egress-traffic}

一个常见的误解是类似 [`outboundTrafficPolicy: REGISTRY_ONLY`](/zh/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services) 的设置可以作为安全策略来阻止访问未声明服务。但是如上文所说这并不能作为一个很强的安全边界，而充其量应视为尽力而为。

尽管上面的设置可以防止意外的依赖，如果您想要确保 egress 的流量安全并强制所有的出站流量都通过代理，您应该使用 [Egress Gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/)。
当结合[网络策略](/zh/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies)一起使用时，您可以强制所有出站流量，或者部分通过 egress 网关。这确保了即使客户端因意外或者被恶意绕过它的代理，请求将会被阻止。

## 当使用 TLS 源时在目标规则上配置 TLS 验证{#configure-TLS-verification-in-destination-rule-when-using-TLS-origination}

Istio 提供了从 Sidecar 代理或者网关上[发起 TLS](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/) 的能力。
这使得从应用发出的纯文本 HTTP 流量可以透明地“升级”到 HTTPS。

当进行 `DestinationRule`中的 `tls` 字段配置时，应格外注意 `caCertificates` 字段。
如果该字段未设置，服务器证书将不会被验证。

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
{{< /text >}}

## 网关{#gateways}

当运行一个 Istio [网关](/zh/docs/tasks/traffic-management/ingress/)时候，以下的资源都将参与：

* `Gateway` 控制了网关的端口和 TLS 设置。
* `VirtualService` 控制了路由逻辑。虚拟服务通过 `Gateway` 资源的 `gateways` 的字段直接被引用。并且`Gateway` 和 `VirtualService` 资源中的 `hosts` 字段需保持一致。

### 限制 `Gateway` 创建权限{#restrict-gateway-creation-privileges}

Istio 推荐将网关资源创建权限只分配给信任的集群管理员。这可以通过 [Kubernetes RBAC policies](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) 或者 类似 [Open Policy Agent](https://www.openpolicyagent.org/) 的工具实现。

### 避免过于宽泛的 `hosts` 配置{#avoid-overly-broad-hosts-configurations}

如果可能，请避免将 `Gateway` 资源的 `hosts` 字段定义地过于宽泛。

例如，以下的配置将允许任意的 `VirtualService` 绑定到 `Gateway` 之上，很有可能暴露出不应暴露的域：

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

### 隔离敏感负载{#isolate-sensitive-services}

有可能存在对敏感负载进行强制的严格物理隔离的情况。例如，您可能希望将敏感的域 `payments.example.com` 运行在[专用的网关实例](/zh/docs/setup/install/istioctl/#configure-gateways)上，同时在一个共享的网关实例上运行多个较不敏感的域，例如 `blog.example.com` 和 `store.example.com`。
这种方式提供了更好的纵深防御并且利于实现监管准则。

### 显式阻止所有的敏感 http 主机被宽泛的 SNI 匹配{#explicitly-disable-all-the-sensitive-http-host-under-relaxed-SNI-host-matching}

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

如果以上设置是必要的，那么推荐您显式地将 http 主机 `admin.example.com` 从配置了 `*.example.com` 的`虚拟服务`中剔除。因为现在 [envoy 代理不要求](https://github.com/envoyproxy/envoy/issues/6767) http 1 头部 `Host` 或者 http 2 伪头部 `:authority` 字段遵守 SNI 限制。 这意味着攻击者可以复用访客的 SNI TLS 连接来访问管理员`虚拟服务`。而 http 回复代码 421 的设计目的便是 `Host` SNI 不匹配并且可以用于以上阻止目的。

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

## 协议探测{#protocol-detection}

Istio 可以[自动确定流量协议](/zh/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection)。但为了避免意外或者有意的误检测，从而导致意外流量行为发生。推荐[显式地声明协议](/zh/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)。

## CNI 网络容器接口{#CNI}

为了透明地劫持所以流量， Istio 依赖 通过 `istio-init` `initContainer` 配置 `iptables` 规则。这增加了一个[要求](/zh/docs/ops/deployment/requirements/)，即需要提供给 Pod `NET_ADMIN` 和 `NET_RAW` [capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)。

为了减少给予 Pods 的权限， Istio 提供了 [CNI plugin](/zh/docs/setup/additional-setup/cni/) 功能，即不再需要以上权限。

## 使用精简 docker 镜像{#use-hardened-docker-images}

Istio 默认 docker 镜像，包括那些控制面，网关， Sidecar 代理正在使用的镜像，都是基于 `ubuntu`。这提供了多种工具，例如 `bash` 以及 `curl`，这权衡了提供便利和增加攻击接口之间的利弊。

同时 Istio 也提供了更精简的基于 [distroless images](/zh/docs/ops/configuration/security/harden-docker-images/) 的镜像，此镜像减少了其中的依赖。

{{< warning >}}
Distroless 镜像目前仍是 alpha 特性。
{{< /warning >}}

## 发布以及安全策略{#release-and-security-policy}

为了确保您的集群拥有针对安全漏洞的最新的安全补丁，保持和最新的 Istio 补丁同步至关重要。同时应该确保您使用的是仍在接收安全补丁的[支持发布版本](/zh/docs/releases/supported-releases)。

## 检测无效配置{#detect-invalid-configurations}

尽管 Istio 在创建资源时提供了验证，但是这些检查不能够涵盖所有可能的配置问题，从而导致不能在网格中生效。
这可能导致配置的策略被意外地忽略了，从而导致意外错误。

* 在配置前后均运行 `istioctl analyze` 来确保有效性。
* 监测控制面是否有被拒绝配置。被拒绝信息会在日志以及 `pilot_total_xds_rejects` 指标中显示。
* 测试您的配置确保出现的是您期待的结果。对于安全策略来说，您可以运行正向和反向的测试来确保您不会意外地对流量进行过多或者过少的约束。

## 避免使用 alpha 或者实验阶段特性{#avoid-alpha-and-experimental-features}

所有的 Istio 特性以及 APIs 都定义了[特性阶段](/zh/docs/releases/feature-stages/)，即定义了它的稳定性，弃用策略以及安全策略。

因为 alpha 以及实验阶段特性没有有力的安全保障，因此推荐尽量避免使用它们。使用这些特性导致的安全问题可能不会马上被修复或者不符合标准[安全漏洞](/zh/docs/releases/security-vulnerabilities/)流程。

为了确定您集群中使用的特性所在的阶段，请参考 [Istio 特性](/zh/docs/releases/feature-stages/#istio-features)列表。

<!-- In the future, we should document the `istioctl` command to check this when available. -->

## 锁定的端口{#lock-down-ports}

Istio 配置了[一系列锁定的端口](/zh/docs/ops/deployment/requirements/#ports-used-by-istio)为了增强安全性。

### 控制面{#control-plane}

Istiod 为了便利暴露了几个未认证的纯本文端口。理想情况下，他们应该被关闭：

* 端口 `8080` 暴露了调试接口，提供了针对集群状态细节的读取权限。
  这可以通过在 Istiod 设置环境变量 `ENABLE_DEBUG_ON_HTTP=false` 来关闭。警告：许多 `istioctl` 命令依赖该接口并且可能无法运行如果该接口被关闭。
* 端口 `15010` 将 XDS 服务暴露为纯文本。这可以通过在 Istiod 部署中添加 `--grpcAddr=""` 标示来关闭。
  注释：高度敏感的服务，例如证书签发和分发服务，绝不允许运行在纯文本上。

### 数据面{#data-plane}

代理暴露了一系列端口。暴露给外部的是端口 `15090` (遥测) 和 端口 `15021` (健康检测)。
端口 `15020` 和 `15000` 提供了调试终端。这两者只暴露给 `localhost`。
因此结果是，应用运行在了代理也有访问权限的同一个 Pod 中，即 Sidecar 和应用之间没有信任边界。

## 配置第三方服务账户 tokens {#configure-third-party-service-account-tokens}

为了认证 Istio 数据面， Istio 代理使用服务账户 tokens。 Kubernetes 支持两种类型的 tokens ：

* 第三方 tokens，拥有有范围限制的受众以及有效期。
* 第一方 tokens，没有有效期以及挂在到全部 Pods 上。

因为第一方 token 的性质较为不安全， Istio 默认使用第三方 tokens。但是该特性并未在全部的 Kubernetes 平台上启用。

如果您使用 `istioctl` 来安装，将会自动检测是否支持第三方 tokens。同时这也可以进行手动配置 `--set values.global.jwtPolicy=third-party-jwt` 或 `--set values.global.jwtPolicy=first-party-jwt`。

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

尽管大多数云供应商现已支持该特性，许多的本地开发工具以及自定义安装还在 Kubernetes 1.20 之前的版本。因此为了启用该特性，请参考 [Kubernetes 文档](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection)。

## 配置下游连接数限制{#configure-a-limit-on-downstream-connections}

默认情况，Istio (以及 Envoy) 没有对下游连接数的限制。但这可能被恶意活动所利用(见 [security bulletin 2020-007](/zh/news/security/istio-security-2020-007/))。为了解决，您需要在您的环境中配置合适的连接数限制。

{{< boilerplate cve-2020-007-configmap >}}

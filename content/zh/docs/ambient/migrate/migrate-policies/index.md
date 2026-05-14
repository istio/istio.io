---
title: 迁移策略
description: 将 Sidecar 流量和授权策略转换为适用于 Ambient 模式的配置。
weight: 3
owner: istio/wg-networking-maintainers
test: no
prev: /zh/docs/ambient/migrate/install-ambient-components
next: /zh/docs/ambient/migrate/enable-ambient-mode
---

{{< tip >}}
**您或许可以跳过此页面。** 如果您仅使用 L4 级别的 `AuthorizationPolicy`
规则（即不包含 `methods`、`paths` 或 `headers` 匹配条件），
且未配置任何 `VirtualService` 或 `DestinationRule` 资源，同时也未配置 `EnvoyFilter`、
`WasmPlugin` 或 `RequestAuthentication` 资源，
那么您现有的策略在 Ambient 模式下将无需任何修改即可正常工作。
请直接跳转至启用 Ambient 模式。
{{< /tip >}}

在 Ambient 模式下，L7 流量管理由 {{< gloss >}}waypoint{{< /gloss >}}
代理而非 Sidecar 代理负责。这改变了策略的表达与执行方式：

- 带有 waypoint 支持的 **`VirtualService`** 功能目前处于 **Alpha** 阶段。
  尽管在有限场景下可能可用，但强烈建议迁移至 `HTTPRoute`。
  针对同一工作负载混用 `VirtualService` 和 `HTTPRoute` 是不受支持的，且会导致未定义的行为。
- **`DestinationRule`** 中的流量策略（包括连接池设置、
  异常点检测及 TLS 配置）均受 Waypoint 支持，无需进行任何修改。
  然而，由于 `HTTPRoute` 在进行路由时，是直接将 Kubernetes Service
  作为其 `backendRefs`（后端引用）对象，而非依赖于 `DestinationRule`
  中的子集（Subsets），因此若要在 `HTTPRoute` 中实现基于版本的流量拆分，
  则必须为每个版本单独配置一个对应的 Service。
- 使用 L7 规则（HTTP 方法、路径或标头），或使用 `action: CUSTOM`
  或 `action: AUDIT` 的 **`AuthorizationPolicy`** 资源，
  必须使用 `targetRefs`（而非工作负载 `selector`）将策略绑定到受支持的资源上；
  欲了解更多信息，请参阅 [AuthorizationPolicy 文档](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-targetRefs)。
- **`RequestAuthentication`** 和 **`WasmPlugin`** 资源需要 waypoint 代理，
  且必须使用 `targetRefs` 进行定位，以指向该 waypoint。
- **`EnvoyFilter`** 资源**不支持应用于 waypoint**。
  如果您配置了用于调整 Sidecar 代理行为的 `EnvoyFilter` 资源，
  这些资源在迁移后将被静默忽略；因此，您必须在继续操作之前妥善处理这些资源：
    - 如果该过滤器添加了自定义的 Envoy 功能，请评估 `WasmPlugin`
      是否能够在 waypoint 上提供等效的行为。
    - 如果不再需要该过滤器，请将其删除。
    - 如果不存在兼容 Ambient 的替代方案，这将构成迁移阻碍。
      在解决该依赖问题之前，请勿继续操作。

## 审计您现有的政策 {#audit-your-existing-policies}

首先，列出集群中的所有 L7 资源：

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule -A
{{< /text >}}

识别需要 waypoint 的 `AuthorizationPolicy` 资源（L7 规则或 `CUSTOM`/`AUDIT` 操作）：

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:|action: CUSTOM|action: AUDIT)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

识别包含子集的 `DestinationRule` 资源（在 Ambient
模式下，这些资源需要特定版本的 Service）：

{{< text syntax=bash snip_id=none >}}
$ kubectl get destinationrule -A --no-headers | while read ns name rest; do
    if kubectl get destinationrule "$name" -n "$ns" -o yaml | grep -q "subsets:"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

## 将 VirtualService 迁移至 HTTPRoute {#migrate-virtualservice-to-httproute}

{{< warning >}}
`VirtualService` 对 waypoint 的支持目前处于 Alpha 阶段，
在未来的版本中可能会发生兼容性中断。请在完成迁移之前，
将您的 `VirtualService` 资源迁移至 `HTTPRoute`。
切勿让 `VirtualService` 和 `HTTPRoute` 资源同时指向同一个工作负载，否则会导致未定义的行为。
{{< /warning >}}

`HTTPRoute` 是 Ambient 模式下稳定且受支持的 L7 路由 API。

{{< tip >}}
社区工具 [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway)
能够自动完成此转换过程中的部分工作。
其 [Istio 提供程序](https://github.com/kubernetes-sigs/ingress2gateway/blob/main/pkg/i2gw/providers/istio/README.md)负责将
`VirtualService` 资源转换为 `HTTPRoute`、`TLSRoute` 和 `TCPRoute` 资源，
并为跨命名空间引用生成相应的 `ReferenceGrant` 资源。
对于无法直接转换的字段，该工具会将其记录下来并予以跳过；
因此，在将生成的配置应用到集群之前，请务必仔细审查其输出结果。
此外请注意，`IngressGateway` 资源也会被转换为 Gateway API 中的 `Gateway` 资源；
因此，该工具既可用于迁移 `VirtualService` 资源，也可用于迁移 `Gateway` 资源。
{{< /tip >}}

### 示例：基于标头的路由 {#example-header-based-routing}

下方的 `VirtualService` 利用子集（subsets）功能，
将带有 `end-user: jason` 标签的请求路由至 `reviews`
服务的版本 2，并将所有其他请求路由至版本 1。

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

由于 `HTTPRoute` 不支持 DestinationRule 子集，因此您必须首先创建特定于版本的 Service：

{{< text syntax=yaml snip_id=none >}}
apiVersion: v1
kind: Service
metadata:
  name: reviews-v1
  namespace: bookinfo
spec:
  selector:
    app: reviews
    version: v1
  ports:
  - port: 9080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: reviews-v2
  namespace: bookinfo
spec:
  selector:
    app: reviews
    version: v2
  ports:
  - port: 9080
    name: http
{{< /text >}}

接下来，将 `VirtualService` 替换为一个直接挂载到 `reviews` Service 上的
`HTTPRoute`（使用 `kind: Service` 作为 `parentRef`）。
这正是 Ambient 模式下正确的挂载模型——即 waypoint 将 Service 作为路由锚点：

{{< text syntax=yaml snip_id=none >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: bookinfo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
      - name: end-user
        value: jason
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
{{< /text >}}

如需关于 `HTTPRoute` 功能的完整参考，
请参阅[流量管理文档](/zh/docs/tasks/traffic-management/)。

## 迁移 L7 规则的 AuthorizationPolicy {#migrate-authorizationpolicy-for-l7-rules}

在 Sidecar 模式下，`AuthorizationPolicy` 资源使用 `selector` 直接定位 Pod。
而在 Ambient 模式下，L7 授权策略必须由 Waypoint 代理强制执行，
因此必须使用 `targetRefs` 来定位该 Waypoint 的父级 `Service` 或 `Gateway` 本身。

### L4 策略（无需更改） {#l4-policies-no-change-required}

仅基于源主体、命名空间或 IP 范围进行匹配的 L4 `AuthorizationPolicy` 资源，
在 Ambient 模式下无需修改即可正常工作。这些策略由 ztunnel 负责执行。

{{< text syntax=yaml snip_id=none >}}
# 此 L4 策略在 Ambient 模式下无需任何更改。
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/bookinfo/sa/productpage"]
{{< /text >}}

### L7 策略 {#l7-policies}

{{< warning >}}
迁移 L7 策略会导致短暂的策略执行空窗期。基于旧式选择器（Selector）的策略必须在
Pod 重启之前或重启之时移除，而基于新式航点（waypoint）的策略一旦创建便会立即生效。
在这两项操作之间，L7 规则将处于未应用状态。如果业务要求 L7 策略必须持续生效，
请务必规划相应的维护窗口。这一空窗期属于已知限制，目前已列入追踪列表，并计划在未来的版本中加以改进。
{{< /warning >}}

凡是基于 HTTP 方法、路径或标头进行匹配，或使用了 `action: CUSTOM`
或 `action: AUDIT` 的策略，都必须以 Waypoint 代理为目标。
请将 `selector` 替换为 `targetRefs`，使其指向该 waypoint 所保护的 `Service`，
或指向 Waypoint 的 `Gateway` 资源本身：

{{< text syntax=yaml snip_id=none >}}
# 之前：Sidecar 风格（基于选择器）
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

{{< text syntax=yaml snip_id=none >}}
# 之后：Ambient 风格（targetRefs 指向 Service）
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: reviews
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

或者，您也可以直接以 waypoint 的 `Gateway` 资源为目标。
这将把策略应用到由该 waypoint 处理的所有流量上，无论其目标 Service 是什么：

{{< text syntax=yaml snip_id=none >}}
# 之后：Ambient 风格（targetRefs 指向 waypoint 网关）
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: waypoint
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

Targeting a `Service` is the more precise option and is recommended when the policy should apply to a single service. Targeting the `Gateway` is useful when the policy should apply to all services in the namespace.
以 `Service` 为目标是更为精确的选项，当策略仅需应用于单个服务时，
推荐采用此方式。而当策略需要应用于命名空间内的所有服务时，以 `Gateway` 为目标则更为适用。

## 防止绕过 waypoint {#prevent-waypoint-bypass}

在使用航点（waypoint）时，请确保无法通过绕过该航点的方式来访问工作负载。
为此，请使用由 **ztunnel**（位于目标 Pod 上）强制执行的工作负载 `selector` DENY 策略。
由于该策略仅检查源主体（一种 L4 属性），ztunnel 能够对其进行正确地强制执行。

{{< warning >}}
请勿为此策略使用 `targetRefs`。基于 `targetRefs` 的 DENY 策略由 waypoint 执行；
在此过程中，waypoint 识别的是原始客户端的身份，而非 waypoint 自身的身份。
这将导致 waypoint 在 ALLOW 策略生效之前，便拒绝所有的客户端流量。
{{< /warning >}}

### 确定何时应用绕过预防措施 {#decide-when-to-apply-bypass-prevention}

在增量迁移过程中，部分源端工作负载可能仍处于 Sidecar 模式。
Sidecar 模式下的工作负载会绕过 waypoint，直接连接至目标端的 ztunnel；
因此，ztunnel 会将 Sidecar 的身份识别为源端主体（Source Principal），
而非 waypoint 的身份。若配置了严格的 waypoint 专属 DENY（拒绝）策略，此类流量将被阻断。

在应用策略之前，请选择以下选项之一：

**选项 1：推迟绕行阻断，直至所有源端完成迁移。**仅当所有调用该服务的工作负载均已切换至
Ambient 模式后，才应用 DENY 策略。如果您能够掌控所有的调用方，这便是更为简便的方案。

**选项 2：允许来自 waypoint 和 Sidecar 主体的流量。**立即应用该策略，
但需将剩余 Sidecar 工作负载的服务账号（连同 waypoint 的主体）一并添加到
`notPrincipals` 例外列表中。随着每个 Sidecar 主体完成迁移，
将其从该列表中移除。一旦所有调用方均已切换至 Ambient 模式，列表中仅需保留 waypoint 主体即可。

### 应用绕过防范策略 {#apply-the-bypass-prevention-policy}

查找 waypoint 所使用的服务账号：

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller \
    -o jsonpath='{.items[0].spec.serviceAccountName}'
{{< /text >}}

对于选项 1，仅在所有调用方迁移完成后应用该策略。

{{< text syntax=yaml snip_id=none >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-waypoint-bypass
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals:
        - "cluster.local/ns/bookinfo/sa/waypoint"
{{< /text >}}

对于选项 2，在迁移期间将 Sidecar 主体包含在例外列表中：

{{< text syntax=yaml snip_id=none >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-waypoint-bypass
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals:
        - "cluster.local/ns/bookinfo/sa/waypoint"
        - "cluster.local/ns/bookinfo/sa/productpage"
{{< /text >}}

{{< warning >}}
请保持现有的 Sidecar `AuthorizationPolicy` 资源处于活跃状态，
直至 Pod 重启且不再包含 Sidecar 为止。然而，**请务必在 Pod 重启完成后立即将其删除**——切勿等待完整的策略验证流程结束。
任何在 Sidecar 被移除后仍处于活跃状态、且使用了工作负载 `selector` 并包含
L7 规则（如 HTTP 方法、路径或标头）的 `AuthorizationPolicy`，
都将被 ztunnel 捕获；由于 ztunnel 无法执行 L7 规则，
它会将此类策略自动转换为针对该工作负载所有流量的 `DENY`（拒绝）策略。
{{< /warning >}}

## 后续步骤 {#next-steps}

请继续执行启用 Ambient 模式，以标记命名空间、激活 waypoint 并移除 Sidecar 注入。

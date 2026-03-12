---
title: 调试端点
description: 访问 istiod 调试端点以进行监控和故障排除。
weight: 30
keywords: [integration,debug,authentication,istiod]
owner: istio/wg-user-experience-maintainers
test: no
---

Istiod 在多个端口上公开调试端点（例如，`/debug/syncz`、`/debug/registryz`、`/debug/config_dump`），
提供对集成有用的监控和状态信息。

## 端口和协议 {#ports-and-protocols}

- **端口 15010**：通过纯文本 gRPC 实现的 XDS 调试端点（`syncz`、`config_dump`）
- **端口 15012**：通过 TLS/mTLS gRPC 实现的 XDS 调试端点（`syncz`、`config_dump`） - 推荐用于生产环境
- **端口 15014**：HTTP 调试端点（纯文本）

## 身份验证要求 {#authentication-requirements}

调试端点需要通过 Kubernetes 服务帐户令牌或有效的 JWT 凭据进行身份验证。
令牌必须具有 `istio-ca` 受众（可通过 istiod 上的 `TOKEN_AUDIENCES` 环境变量进行配置）。

**端口 15010（明文 gRPC）：** 当 `ENABLE_DEBUG_ENDPOINT_AUTH=true` 时，
调试端点需要身份验证。由于此端口为明文（无 TLS），除非禁用身份验证，
否则身份验证检查实际上会阻止访问。对于需要身份验证的 XDS 调试访问，请改用端口 15012。

**端口 15012 (TLS gRPC)：** XDS 调试端点可通过安全的 TLS 端口访问。
身份验证通过 mTLS 证书验证自动执行。

**端口 15014 (HTTP):** 通过 Authorization 标头中的 bearer token 进行身份验证或绕过 localhost。

身份验证由 `ENABLE_DEBUG_ENDPOINT_AUTH` 控制（默认启用）。
要完全禁用身份验证并恢复传统的明文通信行为，请在 istiod 上设置 `ENABLE_DEBUG_ENDPOINT_AUTH=false`。
请注意，禁用身份验证可能会泄露敏感的集群信息。

## 基于命名空间的访问控制 {#namespace-based-access-control}

启用身份验证后：

- 来自**系统命名空间**（通常是`istio-system`）的服务帐户对所有命名空间中所有代理的所有调试端点拥有完全访问权限。
- 来自**非系统命名空间**的服务帐户仅限于：
    - 仅限特定端点：`/debug/config_dump`、`/debug/ndsz`、`/debug/edsz`
    - 仅限同一命名空间内的代理（无法查看其他命名空间的代理）
- 要授予其他命名空间与系统命名空间相同的完全访问权限，请在 istiod 上将
  `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` 环境变量设置为以逗号分隔的命名空间列表。
  {{< tip >}}
  `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` 在 Istio 1.29.1+、1.28.5+ 和 1.27.8+（即将发布的补丁版本）中可用。
  {{< /tip >}}

## 访问方法 {#access-methods}

通过 localhost（推荐）：

将端口转发到 istiod 可以绕过身份验证，因为请求来自本地主机。
这就是 istioctl 的工作原理，也是大多数集成推荐的方法：

{{< text bash >}}
$ kubectl port-forward -n istio-system deploy/istiod 15014:15014
$ curl http://localhost:15014/debug/syncz
{{< /text >}}

直接网络访问（用于集群内工具）：

对于在集群内部运行并通过 Kubernetes 服务网络直接访问 istiod 的工具
（例如 Kiali、自定义监控工具），服务帐户令牌必须：

- 受众为 `istio-ca`（默认）
- 必须来自授权命名空间（`istio-system` 或 `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` 中列出的命名空间）
- 必须作为持有者令牌包含在 Authorization 标头中

{{< text bash >}}
$ TOKEN=$(kubectl create token my-sa --audience istio-ca -n my-namespace)
$ curl -H "Authorization: Bearer $TOKEN" https://istiod.istio-system:15014/debug/syncz
{{< /text >}}

{{< warning >}}
标准集群内服务帐户令牌的受众为 `https://kubernetes.default.svc.cluster.local`，
如果不显式请求 `istio-ca` 受众，则无法直接访问。
{{< /warning >}}

## 示例：配置命名空间访问 {#example-configuring-namespace-access}

要允许在 `monitoring` 命名空间中运行的监控工具访问调试端点，请将该命名空间添加到 istiod 的配置中：

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
  namespace: istio-system
spec:
  template:
    spec:
      containers:
      - name: discovery
        env:
        - name: DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES
          value: "monitoring,kiali-operator"
{{< /text >}}

应用此更改后，`monitoring` 和 `kiali-operator` 命名空间中的服务帐户将与
`istio-system` 服务帐户具有相同的访问级别。

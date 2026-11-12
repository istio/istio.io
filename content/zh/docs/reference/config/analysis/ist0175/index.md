---
title: JwksUriFetchUnrestricted
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当网格中存在 `RequestAuthentication` 资源，但 istiod 没有设置
`BLOCKED_CIDRS_IN_JWKS_URIS` 环境变量时，会出现此消息。

Istiod 会从每个 `RequestAuthentication` 的 `jwksUri` 获取 JSON Web 密钥集（JWKS）。
如果未设置 `BLOCKED_CIDRS_IN_JWKS_URIS`，istiod 可以向所有地址（包括内部地址）发送请求。
这样，能够创建 `RequestAuthentication` 的用户就可以让 istiod 向内部服务发送请求。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Warning [IST0175] (Deployment istio-system/istiod) BLOCKED_CIDRS_IN_JWKS_URIS is not configured but 2 RequestAuthentication resource(s) exist (default/jwt-example, foo/jwt-example). Consider configuring it to restrict JWKS URI fetches to trusted networks.
{{< /text >}}

## 如何修复 {#how-to-resolve}

在 istiod 上将 `BLOCKED_CIDRS_IN_JWKS_URIS` 设置为 istiod 不得连接的 CIDR 范围列表（以逗号分隔）。例如：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      env:
        BLOCKED_CIDRS_IN_JWKS_URIS: "10.0.0.0/8,169.254.169.254/32"
{{< /text >}}

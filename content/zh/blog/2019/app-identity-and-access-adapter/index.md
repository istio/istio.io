---
title: APP 身份和访问适配器
subtitle: 使用 Istio 实现零代码改动保护多云 Kubernetes 应用
description: 使用 Istio 实现零代码改动保护多云 Kubernetes 应用。
publishdate: 2019-09-18
attribution: Anton Aleksandrov (IBM)
keywords: [security,oidc,jwt,policies]
target_release: 1.3
---

如果在 Kubernetes 以容器化的方式运行应用，就可以使用 App 身份和访问适配器获得抽象级别的安全性，而无需更改代码或重新部署。

无论您的运行环境是单云提供商，还是多个云提供商的组合或者遵循混合云的方式，集中式身份管理都可以帮助您维护现有基础设施并避免被云供应商绑定。

有了 [App 身份和访问适配器](https://github.com/ibm-cloud-security/app-identity-and-access-adapter)，就可以使用以下 OAuth2/OIDC 提供商：IBM Cloud App ID、Auth0、Okta、Ping Identity、AWS Cognito、Azure AD B2 等。身份和授权策略可以以高效的方式应用在所有环境（包括前端和后端应用程序），而无需修改代码或重新部署。

## 了解 Istio 和其适配器 {#understanding-Istio-and-the-adapter}

[Istio](/zh/docs/concepts/what-is-istio/) 是一个开源的服务网格，它对分布式应用来说是一个透明层，它可以和 Kubernetes 无缝集成。为了降低布署复杂性 Istio 提供了对整个服务网格的行为洞察和操作控制。详见 [Istio 架构](/zh/docs/ops/deployment/architecture/)。

Istio 使用 [Envoy sidecar 代理] 来调整服务网格中所有 Pod 的入站和出站流量。Istio 从 Envoy sidecar 中提取遥测数据，并将其发送到负责收集遥测数据和执行策略的 Istio 组件 Mixer。

APP 身份和访问适配器通过分析针对服务网格上各种访问控制策略的遥测数据（属性）扩展 Mixer 的功能。访问控制策略可以关联到具体的 Kubernetes 服务，并且可以微调到特定的服务端点。关于策略和遥测信息的详情请看 Istio 的文档。

当 [App 身份和访问适配器](https://github.com/ibm-cloud-security/app-identity-and-access-adapter)结合到 Istio 中后，为多云架构提供可扩展的、集成身份和访问解决方案，而且不需要修改任何应用程序代码。

## 安装 {#installation}

可以直接使用 `github.com` 仓库中的 Helm 来安装 APP 身份和访问适配器。

{{< text bash >}}
$ helm repo add appidentityandaccessadapter https://raw.githubusercontent.com/ibm-cloud-security/app-identity-and-access-adapter/master/helm/appidentityandaccessadapter
$ helm install --name appidentityandaccessadapter appidentityandaccessadapter/appidentityandaccessadapter
{{< /text >}}

另外，可以从 `github.com` 仓库 clone 下来，在本地用 Helm chart 进行安装。

{{< text bash >}}
$ git clone git@github.com:ibm-cloud-security/app-identity-and-access-adapter.git
$ helm install ./helm/appidentityandaccessadapter --name appidentityandaccessadapter.
{{< /text >}}

## 保护 web 应用程序 {#protecting-web-applications}

Web 应用程序通常是由 OpenID Connect (OIDC) 工作流保护，也被叫做 `authorization_code`。当检测到未经认证或未经授权的用户时，它们会自动重定向到所选择的身份服务并展示认证页面。身份验证完成后，浏览器将重定向回适配器拦截的隐式 `/oidc/callback` 端点。此时，适配器从身份服务获取访问和身份令牌，然后将用户重定向回 Web 应用程序中最初请求的 URL。

身份状态和令牌是由适配器维护管理的。适配器处理的每个请求会包含访问和身份令牌的认证头，其格式是：`Authorization: Bearer <access_token> <id_token>`。

开发者可以根据读取令牌（token）信息调整应用程序的用户体验，比如显示用户名，根据用户角色适配用户界面等。

为了终止经过身份验证的会话并且清除令牌（即用户注销），只需将浏览器重定向到受保护服务下的 `/oidc/logout` 端点即可。例如，从 `https://example.com/myapp` 中将应用程序重定向到 `https://example.com/myapp/oidc/logout`。

无论何时访问令牌过期了，系统都会通过刷新令牌自动获取一个新的访问和身份令牌，而无需重新进行身份验证。如果已配置的身份认证提供商返回一个刷新令牌，适配器会将其持久保存，用于老令牌过期时，重新获取新的访问和身份令牌。

### 应用 web 应用程序保护 {#applying-web-application-protection}

保护 web 应用程序需要创建 2 种类型的资源 - `OidcConfig` 资源用于定义各种 OIDC 服务提供商，`Policy` 资源用于定义 web 应用保护策略。

{{< text yaml >}}
apiVersion: "security.cloud.ibm.com/v1"
kind: OidcConfig
metadata:
    name: my-oidc-provider-config
    namespace: sample-namespace
spec:
    discoveryUrl: <discovery-url-from-oidc-provider>
    clientId: <client-id-from-oidc-provider>
    clientSecretRef:
        name: <kubernetes-secret-name>
        key: <kubernetes-secret-key>
{{< /text >}}

{{< text yaml >}}
apiVersion: "security.cloud.ibm.com/v1"
kind: Policy
metadata:
    name: my-sample-web-policy
    namespace: sample-namespace
spec:
    targets:
    - serviceName: <kubernetes-service-name-to-protect>
        paths:
        - prefix: /webapp
            method: ALL
            policies:
            - policyType: oidc
                config: my-oidc-provider-config
                rules: // optional
                - claim: iss
                    match: ALL
                    source: access_token
                    values:
                    - <expected-issuer-id>
                - claim: scope
                    match: ALL
                    source: access_token
                    values:
                    - openid
{{< /text >}}

[阅读更多关于如何保护 web 应用程序](https://github.com/ibm-cloud-security/app-identity-and-access-adapter)。

## 保护后端应用程序和 API {#protecting-backend-application-and-APIs}

后端应用程序和 API 的保护是使用 Bearer Token 工作流，对特定的策略验证传入的令牌。Bearer Token 授权流程需要在请求中包含 `Authorization` 头，这个头以 JWT 格式包含了有效的访问令牌。需要的头结构是：`Authorization: Bearer {access_token}`。如果令牌验证成功请求会被发往被请求的服务。如果令牌验证失败会给客户端返回 HTTP 401 以及访问这个 API 所需要的权限列表。

### 应用后端程序和 API 保护 {#applying-backend-application-and-APIs-protection}

保护后端程序和 API 需要创建 2 种类型的资源 - `JwtConfig` 用于定义各种 JWT 服务提供者，`Policy` 用于定义后端应用保护策略。

{{< text yaml >}}
apiVersion: "security.cloud.ibm.com/v1"
kind: JwtConfig
metadata:
    name: my-jwt-config
    namespace: sample-namespace
spec:
    jwksUrl: <the-jwks-url>
{{< /text >}}

{{< text yaml >}}
apiVersion: "security.cloud.ibm.com/v1"
kind: Policy
metadata:
    name: my-sample-backend-policy
    namespace: sample-namespace
spec:
    targets:
    - serviceName: <kubernetes-service-name-to-protect>
        paths:
        - prefix: /api/files
            method: ALL
            policies:
            - policyType: jwt
                config: my-oidc-provider-config
                rules: // optional
                - claim: iss
                    match: ALL
                    source: access_token
                    values:
                    - <expected-issuer-id>
                - claim: scope
                    match: ALL
                    source: access_token
                    values:
                    - files.read
                    - files.write
{{< /text >}}

[阅读更多如何保护后端应用程序](https://github.com/ibm-cloud-security/app-identity-and-access-adapter)。

## 已知的局限性 {#known-limitations}

在写这篇博客的时候，有 2 个关于 APP 身份和访问适配器的已知局限性问题：

- 如果在 Web 应用程序上启用 APP 身份和访问适配器，只能创建 1 个适配器的副本。由于 Envoy 代理处理 HTTP 头的方式，Mixer 有可能给 Envoy 返回多个 `Set-Cookie` 头。因此，不能设置 Web 应用程序想要设置的所有 cookie。这个问题最近在 Envoy 和 Mixer 的开发上被讨论，计划在后期适配器的版本中解决。**注意这个问题只影响 Web 应用程序，并不会以任何方式影响后端 APP 和 API**。

- 作为一般最佳实践，集群内通信应该永远考虑使用双向 TLS 通信。现在 Mixer 与 APP 身份和访问适配器之间的通信通道并没有使用双端 TLS 通信。未来计划根据 [Mixer 适配器开发指引](https://github.com/istio/istio/wiki/Mixer-Out-of-Process-Adapter-Walkthrough#step-7-encrypt-connection-between-mixer-and-grpc-adapter)实现解决这个问题。

## 总结 {#summary}

当多云部署实施时，随着环境的发展和多样性，安全也会变得复杂起来。当云提供商提供协议和工具来确保其产品的安全性，开发团队仍然要负责应用程序级别的安全，比如基于 OAuth2 的 API 访问控制，通过流量加密防御中间人攻击以及为服务访问控制提供双向 TLS。但是在多云环境中，这会变得复杂，因为可能要为分别为每个服务定义它的安全策略。有了适当的安全协议，这些外部和内部的威胁就可以减轻了。

开发团队花时间让服务能够移植到不同的云提供商，在同等情况下，安全应该更灵活而不依赖基础设施。

Istio 和 APP 身份和访问适配器可以加固 Kubernetes app 的安全性，并且无关编程语言和框架，不需要修改任何一行代码并重新部署。使用这种方式保证了 app 的最大可移植性，并且可以在多个环境中方便的去执行相同的安全策略。

可以在[发布博客](https://www.ibm.com/cloud/blog/using-istio-to-secure-your-multicloud-kubernetes-applications-with-zero-code-change)上阅读更多关于 APP 身份和访问适配器的信息。

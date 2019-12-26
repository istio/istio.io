---
title: APP 身份和访问适配器
subtitle: 使用 Istio 零代码实现多云 Kubernetes 应用安全
description: 使用 Istio 零代码实现多云 Kubernetes 应用安全。
publishdate: 2019-09-18
attribution: Anton Aleksandrov (IBM)
keywords: [security,oidc,jwt,policies]
target_release: 1.3
---

如果在 Kubernetes 以容器化的方式运行应用，就可以使用 App 身份和访问适配器获得抽象级别的安全性，而无需更改或重新部署代码。

无论您的运行环境是单云提供商，多个云提供商的组合，还是遵循混合云方法，集中式身份管理都可以帮助您维护现有基础设施并避免供被应商绑定。

有了 [App 身份和访问适配器](https://github.com/ibm-cloud-security/app-identity-and-access-adapter)，就可以使用任何 OAuth2/OIDC 提供商：IBM Cloud App ID, Auth0, Okta, Ping Identity, AWS Cognito, Azure AD B2C 和其它更多。身份和授权策略可以以高效的方式应用在所有环境（包括前端和后端应用程序），而无需修改代码或重新部署。

## 了解 Istio 和其适配器 {#understanding-istio-and-the-adapter}

[Istio](/zh/docs/concepts/what-is-istio/) 是一个开源的服务网格，它对分布应用来说说一个透明层，它可以和 Kubernetes 无缝集成。为了降低布署复杂性 Istio 提供了对整个服务网格的行为洞察和操作控制。详见 [Istio 架构](/zh/docs/ops/deployment/architecture/)。

在服务网格中 Istio 使用 [Envoy 代理边车](/zh/blog/2019/data-plane-setup/)为所有的 pod 协调进出流量。Istio 从 Envoy 边车中抽取检测信息并发送给 [Mixer](/zh/docs/ops/deployment/architecture/#mixer)，Istio 的组件负责收集检测数据并执行策略。

APP 身份和访问适配器通过分析针对服务网格上各种访问控制策略的检测信息（属性），以便扩展 Mixer 的功能。访问控制策略可以关联到具体的 Kubernetes 服务，并且可以微调指定的服务 endpoint。关于策略和检测信息的详情请看 Istio 的文档。

当 [App 身份和访问适配器](https://github.com/ibm-cloud-security/app-identity-and-access-adapter) 结合到 Istio 中后，为多云架构提供可扩展的、集成身份和访问解决方案，而且不需要修改任何应用程序代码。

## 安装 {#installation}

可以直接使用 `github.com` 仓库中的 Helm 来安装 APP 身份和访问适配器。

{{< text bash >}}
$ helm repo add appidentityandaccessadapter https://raw.githubusercontent.com/ibm-cloud-security/app-identity-and-access-adapter/master/helm/appidentityandaccessadapter
$ helm install --name appidentityandaccessadapter appidentityandaccessadapter/appidentityandaccessadapter
{{< /text >}}

另外，可以从 `github.com` 仓库 clone 下来，用 Helm chart 进行本地安装。

{{< text bash >}}
$ git clone git@github.com:ibm-cloud-security/app-identity-and-access-adapter.git
$ helm install ./helm/appidentityandaccessadapter --name appidentityandaccessadapter.
{{< /text >}}

## 保护 web 应用程序 {#protecting-web-applications}

Web 应用程序通常是由 OpenID Connect (OIDC) 工作流保护，也被叫做 `authorization_code`。当检测到未经认证/未经授权的用户时，会自动重定向到所选择的身份服务并展示认证页面。当认证完成，浏览器会重定向回到被适配器截获的隐含 `/oidc/callback` endpoint。在这一服务点上，适配器从身份服务获取访问和身份令牌，并且将用户重定向回到 web 应用最初请求的 URL。

身份状态和令牌是由适配器维护管理的。适配器处理的每个请求会包含访问和身份令牌的认证头，其格式是：`Authorization: Bearer <access_token> <id_token>`。

开发者可以根据读取token信息调整应用程序的用户体验，比如显示用户名，根绝用户角色适配 UI 等。

为了终止授权回话和清除令牌，亦或者用户登出，只要在服务保护之下简单重定向浏览器到 `/oidc/logout` endpoint 即可，比如如果 app 是在 `https://example.com/myapp` 这里服务的，重定向用户到 `https://example.com/myapp/oidc/logout` 即可。


无论何时访问令牌过期了，刷新令牌是无需用户重新认证的，系统会自动获取一个新的访问和身份令牌。如果配置的身份认真提供商返回一个刷新的令牌，适配器将会持久保存起来，直到老令牌过期，用户又重新获取新的访问和身份令牌。

### 应用 web 应用程序保护 {#applying-web-application-protection}

保护 web 应用程序需要创建 2 种类型的资源 - `OidcConfig` 资源用于定义各种 OIDC 服务提供者，`Policy` 资源用于定义 web 应用保护策略。

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

后端应用程序和 API的保护是使用 Bearer Token 工作流，对特定的策略验证传入的令牌。Bearer Token 授权流程需要在请求中包含 `Authorization` 头，这个头以 JWT 格式包含了玉箫的访问令牌。需要的头结构是：`Authorization: Bearer {access_token}`。如果令牌验证成功请求会被发往被请求的服务。如果令牌验证失败会给客户端返回 HTTP 401 信息，并且返回访问这个API所需要的能力列表。

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

在写这篇博客的时候，有 2 个关于 APP 身份和反问适配的已知局限性问题：

- 如果在 Web 应用程序上启用 APP 身份和访问适配器，只能创建 1 个适配器的副本。由于 Envoy 代理处理 HTTP 头的方式，Mixer 有可能给 Envoy 返回多个 `Set-Cookie` 头。因此，不能设置 Web 应用程序想要设置的所有 cookie。这个问题最近在 Envoy 和 Mixer 的开发上被讨论，计划在后期适配器的版本中解决。**注意这个问题只影响 Web 应用程序，并不会以任何方式影响后端 APP 和 API**。

- 作为一般最佳实践，应该在集群内通信是永远考虑使用双端 TLS 通信。现在 Mixer 与 APP 身份和访问适配器之间的通信通道并没有使用双端 TLS 通信。未来计划根据 [Mixer 适配器开发指引](https://github.com/istio/istio/wiki/Mixer-Out-of-Process-Adapter-Walkthrough#step-7-encrypt-connection-between-mixer-and-grpc-adapter)实现解决这个问题。

## 总结 {#summary}

当多云部署实施时，随着环境的发展和多样性，安全也会变得复杂起来。当云提供商提供协议和工具来确保其产品的安全性，开发团队仍然要负责应用程序级别的安全，比如用 OAuth2 的 API 访问控制，使用流量加密的中间人攻击，为服务访问控制提供双端 TLS 通信。但是在多云环境中，这会变得复杂，因为可能要为分别为每个服务定义它的安全策略。有了适当的安全协议，这些外部和内部的威胁就可以减轻了。

开发团队花时间让服务能够移植到不同的云提供商，在同等情况下，安全应该更灵活而不依赖基础设施。


Istio 和 APP 身份和访问适配器允许加固 Kubernetes app 的安全，而且绝对零代码变动或者重新部署而不用关心编程语言和编程框架。使用这种方式保证了 app 的最大可移植性，并且可以在多个环境中方便的去执行相同的安全策略。

可以在[发布博客](https://www.ibm.com/cloud/blog/using-istio-to-secure-your-multicloud-kubernetes-applications-with-zero-code-change)上阅读更多关于 APP 身份和访问适配器的信息。

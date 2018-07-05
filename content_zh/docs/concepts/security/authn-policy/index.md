---
title: 认证策略
description: 介绍 Istio 的认证策略
weight: 10
keywords: [security,authentication]
---

Istio 的认证策略让运维人员有机会为一或多个服务指定认证策略。Istio 的认证策略由两部分组成：

* 点对点认证：验证直接连接客户端的身份。通常使用的认证机制就是 [双向 TLS](/docs/concepts/security/mutual-tls/)。
* 来源认证：验证发起请求的原始客户端（例如最终用户、设备等）。目前源认证仅支持 JWT 方式。

Istio 对服务端进行配置，从而完成认证过程，然而他并不会在客户端做这些工作。对于双向 TLS 认证来说，用户可以使用[目标规则](/docs/concepts/traffic-management/#destination-rules)来配置客户端使用这些协议。其他情况下，应用程序需要自行负责获取用户凭据（也就是 JWT），并将获取到的凭据附加到请求之上。

两种认证方式下的身份，通常都会输出给下一层（也就是 Citadel、Mixer）。为了简化认证规则，可以指定生效的认证规则（点对点认证或者来源认证），缺省情况下使用的是点对点认证。

## 架构

认证策略保存在 Istio 的配置存储中（0.7 中使用的是 Kubernetes CRD 来实现的），控制平面来负责认证策略的分发。传播速度跟集群规模有关，从几秒钟到几分钟都有可能。在这一过程中，通信可能会有中断，也可能出现非预期的认证结果。

{{< image width="80%" ratio="75%"
    link="/docs/concepts/security/authn-policy/authn.svg"
    caption="认证策略架构"
    >}}

策略的的生效范围是在命名空间一级的，还可以在这一命名空间内，用目标选择器来进一步选择服务来确定策略的应用范围。这一行为是和 Kubernetes RBAC 的访问控制模型相一致的。特别需要提出的是，只有命名空间的管理员才能在为该命名空间内的服务设置策略。

认证功能是使用 Istio sidecar 实现的。例如在使用 Envoy sidecar 的情况下，就会落地为一组 SSL 设置和 HTTP filter。如果验证失败，请求就会被拒绝（可能是 SSL 握手失败的错误码、或者 http 401，依赖具体实现机制）。如果验证成功，会生成下列的认证相关属性：

* **source.principal**: 认证方式。如果使用的不是点对点认证，这一属性为空。
* **request.auth.principal**: 绑定的认证方式，可选的取值范围包括 USE_PEER 以及 USE_ORIGIN。
* **request.auth.audiences**: JWT 中的受众（`aud`）声明 (使用 JWT 进行源认证)。
* **request.auth.presenter**: 和上一则类似，指的是 JWT 中的授权者（`azp`）。
* **request.auth.claims**: 原 JWT 中的所有原始报文。

来自认证源的 Principle 不会显式的输出。通常可以通过把 `iss` 和 `sub` 使用 `/` 进行拼接而来（例如 `iss` 和 `sub` 分别是 "*googleapis.com*" 和 "*123456*"，那么源 Principal 就是 "*googleapis.com/123456*"）。另外如果 Principal 设置为 USE_ORIGIN，**request.auth.principal** 的值是和源 Principal 一致的。

## 策略剖析

### 目标筛选器

策略生效服务范围的定义。如果没有提供选择规则，那么对应策略所在的命名空间中的所有服务都会应用该策略，因此称之为命名空间级别的策略（与此相对应的还有一个服务级别的策略，这种策略的选择规则不允许为空）。Istio 会优先选择服务级的策略，否则会回退到命名空间的策略。如果两个都没有指定，就会使用服务网格中配置的缺省策略或者/以及服务注解中的配置，这些配置只能设置双向 TLS（这是 Istio 0.7 版本之前用于配置双向 TLS 的办法）。参考阅读 [测试 Istio 双向 TLS](/docs/tasks/security/mutual-tls/)

> 0.8 开始，推荐使用认证策略来启用或者禁用各个服务的双向 TLS。未来版本中会移除对服务注解方式的支持。

可能存在多个服务级策略匹配到同一个服务的情况，还可能出现同一个命名空间中创建了多个命名空间级的服务策略的情况，运维人员应负责防止出现这种冲突。

示例：选择 `product-page` 服务（的任何端口），以及 `reviews` 服务的 9000 端口。

{{< text yaml >}}
targets:
- name: product-page
- name: reviews
  ports:
  - number: 9000
{{< /text >}}

### 点对点认证

定义了点对点认证采用的方式以及对应的参数。可以列出一个或多个方法，选择其中一个即可满足认证要求。然而从 0.7 开始，只支持双向 TLS，如果不需要点对点认证，可以完全省略。

{{< text yaml >}}
peers:
- mtls:
{{< /text >}}

> 从 Istio 0.7 开始，`mtls` 设置不需要任何参数（因此 `-mtls: {}`、`- mtls:` 或者 `- mtls: null` 就足够了）。未来会加入参数，用以提供不同的双向 TLS 实现。

### 来源认证

定义了来源认证方法以及对应的参数。目前只支持 JWT 认证，然而这个策略可以包含多个不同提供者的不同实现。跟点对点认证类似，只需一个就可以满足认证需求。

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
{{< /text >}}

### Principal 的绑定

从认证过程中提取数据生成 Principal 的方法定义。缺省情况下会沿用点的 Principal（如果没有使用点对点认证，就会留空）。策略的编写者可以选择使用 `USE_ORIGIN` 进行替换。将来我们还会支持 *conditional-binding* （例如优先选择 `USE_PEER`，如果不可用，则采用 `USE_PRIGIN` ）。
---
title: 使用 Istio 增强端到端安全
description: Istio Auth 0.1 公告。
publishdate: 2017-05-25
subtitle: 默认保护服务间通信
attribution: The Istio Team
aliases:
    - /zh/blog/0.1-auth.html
    - /zh/blog/istio-auth-for-microservices.html
target_release: 0.1
---

传统的网络安全方式无法解决部署在动态变化环境下分布式应用的安全威胁。这里，我们将描述 Istio Auth 如何帮助企业将其安全从边界保护转变为内部所有服务间通信保护。使用 Istio Auth 开发人员和运维人员可以在不改动程序代码的情况下，对于敏感数据进行保护，防止未经授权的内部人员访问。

Istio Auth 是更广泛的 [Istio 平台](/zh)的安全组件。它结合了 Google 生产环境中保护数百万微服务安全的经验。

## 背景知识{#background}

现代应用程序体系结构越来越多地基于共享服务，共享服务部署在云平台上，可被方便地进行动态部署和扩容。传统的网络边界安全性（例如防火墙）控制力度太粗，会导致部分非预期的客户端访问。使用盗取合法客户端的认证令牌进行重放攻击，就是一种常见的安全风险。对于持有敏感数据公司而言，内部威胁是一个需要关注的主要风险。其他网络安全方法（如 IP 白名单）通过静态方式定义，难以大规模管理，不适合动态变化的生产环境。

因此，安全管理员需要一种工具，其可以能够默认开启并且始终保护生产环境中服务间的所有通信。

## 解决方案：增强的服务身份和验证{#solution-strong-service-identity-and-authentication}

多年来，Google 通过研发架构和技术，帮助其生产环境中数百万个微服务抵御了外部攻击和内部威胁。关键安全原则包括信任端而不是网络，基于服务身份和级别授权的双向强身份验证。Istio Auth 基于相同的原则。

Istio Auth 服务 0.1 版本在 Kubernetes 上运行，并提供以下功能：

* 服务间强身份认证

* 访问控制以限制可以访问服务（及其数据）的身份

* 传输中的数据自动加密

* 密钥和证书的大规模管理

Istio Auth 基于双向 TLS 和 X.509 等行业标准。此外，Google 还积极参与一个开放的，社区驱动的 [SPIFFE](https://spiffe.io/) 服务安全框架。随着 [SPIFFE](https://spiffe.io/) 规范的成熟，我们打算让 Istio 安全验证参考并实现。

下图描述了 Kubernetes 上 Istio Auth 服务的体系结构。

{{< image link="istio_auth_overview.svg" caption="Istio Auth 概览" >}}

上图说明了三个关键的安全功能：

### 强身份认证{#strong-identity}

Istio Auth 使用了 [Kubernetes 服务帐户](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-service-account/) 来识别服务运行的身份。
身份用于建立信任和定义服务级别访问策略。身份在服务部署时分配，并在 X.509 证书的 SAN（主题备用名称）字段中进行编码。使用服务帐户作为身份具有以下优点：

* 管理员可以使用 Kubernetes 1.6 中引入的 [RBAC](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/rbac/) 功能配置谁有权访问服务帐户

* 灵活地识别人类用户，服务或一组服务

* 稳定地支持服务身份的动态配置和工作负载自动扩展

### 通信安全{#communication-security}

服务间通信基于高性能客户端和服务器端 [Envoy](https://envoyproxy.github.io/envoy/) 代理的传输隧道。代理之间的通信使用双向 TLS 来进行保护。使用双向 TLS 的好处是服务身份不会被替换为从源窃取或重放攻击的令牌。Istio Auth 还引入了安全命名的概念，以防止服务器欺骗攻击 - 客户端代理验证允许验证特定服务的授权的服务帐户。

### 密钥管理和分配{#key-management-and-distribution}

Istio Auth 为每个集群提供 CA（证书颁发机构），并可对密钥和证书自动管理。这种情况下，Istio Auth 具备以下功能 ：

* 为每个服务帐户生成密钥和证书对。

* 使用 [Kubernetes Secrets](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/) 将密钥和证书分发到相应的 pod。

* 定期轮换密钥和证书。

* 必要时（未来）撤销特定密钥和证书对。

下图说明了 Kubernetes 上的端到端 Istio Auth 工作流程：

{{< image link="istio_auth_workflow.svg" caption="Istio Auth 工作流程" >}}

Istio Auth 是更广泛的容器安全中的一部分。Red Hat 是 Kubernetes 开发的合作伙伴，定义了 [10 层](https://www.redhat.com/en/resources/container-security-openshift-cloud-devops-whitepaper)容器安全。Istio 和 Istio Auth 解决了其中两个层：”网络隔离” 和 “API 和服务端点管理”。随着集群联邦在 Kubernetes 和其他平台上的发展，我们的目的是让 Istio 对跨越多个联邦集群的服务间通信提供保护。

## Istio Auth 的优点{#benefits-of-Istio-authentication}

**深度防御**：当与 Kubernetes（或基础架构）网络策略结合使用时，用户可以获得更多的安全信心，因为他们知道 Pod 或服务间的通信在网络层和应用层上都得到保护。

**默认安全**：当与 Istio 的代理和集中策略引擎一起使用时，可在极少或不更改应用的情况下部署并配置 Istio Auth 。因此，管理员和操作员可以确保默认开启服务通信保护，并且可以跨协议和运行时一致地实施这些策略。

**强大的服务认证**：Istio Auth 使用双向 TLS 保护服务通信，以确保服务身份不会是其他来源窃取或重放攻击的令牌。这可确保只能从经过严格身份验证和授权的客户端才能够访问具有敏感数据的服务。

## 加入我们{#join-us-in-this-journey}

Istio Auth 是提供完整安全功能的第一步，安全功能可以用于抵御外部攻击和内部威胁，保护服务的敏感数据。虽然初始版本仅在 Kubernetes 上运行，但我们的目标是使其能够在不同的生产环境中保护服务通信。我们鼓励更多的社区[加入我们]({{< github_tree >}}/security)，为不同的应用技术栈和运行平台上轻松地提供强大的服务安全保障。

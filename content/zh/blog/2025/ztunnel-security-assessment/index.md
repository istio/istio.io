---
title: "Istio 发布 ztunnel 安全审计结果"
description: 顺利通过。
publishdate: 2025-04-18
attribution: "Craig Box - Solo.io，代表 Istio 产品安全工作组; Translated by Wilson Wu (DaoCloud)"
keywords: [istio,security,audit,ztunnel,ambient]
---

Istio 的 Ambient 模式将服务网格分为两个不同的层：
七层处理（“[waypoint 代理](/zh/docs/ambient/usage/waypoint/)”），
仍然由传统的 Envoy 代理提供支持；安全覆盖层（“零信任隧道”或“[ztunnel](https://github.com/istio/ztunnel)”），
它是[一个新的代码库](/zh/blog/2023/rust-based-ztunnel/)，
用 Rust 从头开始​​编写。

我们的目的是让 ztunnel 项目在每个 Kubernetes 集群中默认安装，
并且因此，它需要安全且高性能。

我们全面展示了 ztunnel 的性能，
表明它是[在 Kubernetes 中实现安全零信任网络的最高带宽方式](/zh/blog/2025/ambient-performance/) — 提供比
IPsec 和 WireGuard 等内核数据平面更高的 TCP
吞吐量 — 并且其性能在过去 4 个版本中提高了 75%。

今天，我们很高兴验证了 ztunnel 的安全性，
并发布了由 [Trail of Bits](https://www.trailofbits.com/)
执行的[代码库审计结果](https://ostif.org/wp-content/uploads/2025/04/Istio-Ztunnel-Final-Summary-Report-1.pdf)。

我们要感谢[云原生计算基金会](https://cncf.io/)对这项工作的资助，
以及 [OSTIF 对此的协调](https://ostif.org/istio-ztunnel-audit-complete/)。

## 范围和总体发现 {#scope-and-overall-findings}

Istio 已于 [2020](/zh/blog/2021/ncc-security-assessment/)
和 [2023](/zh/blog/2023/ada-logics-security-assessment/)
接受过评估，其中 Envoy 代理[正在接受独立评估](https://github.com/envoyproxy/envoy#security-audit)。
本次评估范围涵盖 Istio Ambient 模式中的新代码，即 ztunnel 组件：
具体而言，涉及 L4 授权、入站请求代理、传输层安全性 (TLS) 和证书管理的代码。

审计人员表示，“ztunnel 代码库编写良好，结构合理”，
未发现任何与代码漏洞相关的问题。他们的三项发现（其中一项为中等严重程度，两项为信息性发现）
涉及针对外部因素（包括软件供应链和测试）的建议。

## 解决方案和建议的改进 {#resolution-and-suggested-improvements}

### 改进依赖管理 {#improving-dependency-management}

审计期间，ztunnel 依赖项的
[cargo audit](https://crates.io/crates/cargo-audit) 报告显示，
三个版本均已发布最新安全公告。没有迹象表明 ztunnel
依赖项中存在任何易受攻击的代码路径，并且维护人员会定期将依赖项更新到最新的相应版本。
为了简化此流程，我们采用了 [GitHub 的 Dependabot](https://github.com/istio/ztunnel/pull/1400) 进行自动更新。

审计员指出，ztunnel 依赖链中存在 Rust 包的风险，这些包要么无人维护，要么由单一所有者维护。
这种情况在 Rust 生态系统（乃至所有开源生态系统）中很常见。我们替换了明确标识的两个包。

### 增强测试覆盖率 {#enhancing-test-coverage}

Trail of Bits 团队发现大多数 ztunnel 功能都经过了充分测试，
但发现了一些未被[突变测试](https://mutants.rs/)覆盖的错误处理代码路径。

我们评估了这些建议，发现这些结果突出显示的覆盖范围差距适用于测试代码以及​​不影响正确性的代码。

虽然突变测试有助于识别潜在的改进领域，但其目标并非达到报告不返回任何结果的程度。
突变可能会在许多预期情况下触发无测试失败，例如没有“正确”结果的行为（例如日志消息）、
仅影响性能而不影响正确性的行为（在工具可感知的范围之外进行测量）、
有多种方法可以实现相同结果的代码路径，或者仅用于测试的代码。
测试和安全是 Istio 团队的核心优先事项，
我们正在不断提高测试覆盖率——使用突变测试等工具并[开发新颖的解决方案](https://blog.howardjohn.info/posts/ztunnel-testing/)来测试代理。

### 强化 HTTP 标头解析 {#hardening-http-header-parsing}

我们使用了第三方库来解析 HTTP
[Forwarded](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Forwarded) 标头的值，
该标头可能存在于与 ztunnel 的连接中。审计人员指出，
标头解析是一个常见的攻击领域，并对我们使用的库未进行模糊测试表示担忧。
鉴于我们仅使用该库来解析一个标头，
我们[编写了一个针对 Forwarded 标头的自定义解析器](https://github.com/istio/ztunnel/pull/1418)，
并附带一个模糊测试工具来对其进行测试。

## 参与其中 {#get-involved}

环境模式凭借强大的性能和现已验证的安全性，
持续推动服务网格设计领域的发展。我们鼓励您立即尝试。

如果您想参与 Istio 产品安全工作，或成为维护者，
我们非常欢迎！欢迎加入[我们的 Slack 工作区](https://slack.istio.io/)或[我们的公开会议](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，
提出问题或了解我们为维护 Istio 安全所做的工作。

---
title: "Istio 发布版 2022 年安全审计结果"
description: Istio 的安全审查在 Go 标准库中发现了一个 CVE。
publishdate: 2023-01-30
attribution: "Craig Box (ARMO)，Istio 产品安全工作组"
keywords: [istio,security,audit,ada logics,assessment,cncf,ostif]
---

Istio 是一个被平台工程师信任的项目，可以在其 Kubernetes
生产环境中实施安全策略。我们非常注意代码的安全性，
并致力于维护一个健壮的[漏洞程序集](/zh/docs/releases/security-vulnerabilities/)。
为了验证我们的工作，我们定期邀请项目以外的组织开展审查流程，
我们很高兴发布[第二次安全审计的结果（英文）](./Istio%20audit%20report%20-%20ADA%20Logics%20-%202023-01-30%20-%20v1.0.pdf)。

审计员的评估结论是**“Istio 是一个维护良好的项目，
具有强大且可持续的安全应对方法”**。没有发现严重问题；
该报告的亮点是发现了 Go 编程语言中的一个漏洞。

我们要感谢[云原生计算基金会](https://cncf.io/)资助这项工作，
作为我们 [8 月份加入 CNCF](https://www.cncf.io/blog/2022/09/28/istio-sails-into-the-cloud-native-computing-foundation/)
后提供给我们的福利。这项工作[由 OSTIF 安排](https://ostif.org/the-audit-of-istio-is-complete)，
[由 ADA Logics 执行](https://adalogics.com/blog/istio-security-audit)。

## 工作范围和总体调查结果{#scope-and-overall-findings}

[Istio 在 2020 年接受了第一次安全评估](/zh/blog/2021/ncc-security-assessment/)，
其数据平面和 [Envoy 代理](https://envoyproxy.io/)都已经过
[2018 年和 2021 年的独立评估](https://github.com/envoyproxy/envoy#security-audit)。
因此，Istio 产品安全工作组和 ADA Logics 确定了以下工作范围：

* 生成正式的威胁模型，以指导本次和未来的安全审计
* 对安全问题进行手动代码审计
* 审查 2020 年审计中发现的问题修复
* 审查和改进 Istio 的模糊测试套件
* 对 Istio 进行 SLSA 审查

再一次，在审查中没有发现任何严重问题。在评估中总共发现了 11 个安全问题；
其中两个 High，四个 Medium，四个 Low 和一个信息级别的问题。
所有报告的问题都已被修复。

{{< quote >}}
**“Istio 是一个维护良好且安全的项目，具有完善的代码库、
完善的安全实践和响应迅速的产品安全团队。” - ADA Logics**
{{< /quote >}}

除了上述发现之外，审计员还指出 Istio
在处理安全性方面遵循高水平的行业标准。他们还特别强调了：

* Istio 产品安全工作组迅速响应安全披露
* 关于项目安全性的文档是全面的、高质量的且更新及时
* 遵循行业标准进行安全漏洞的披露，安全建议清晰且详细
* 安全修复都包含回归测试

## 决议和经验{#resolution-and-learnings}

### Go 语言中的请求走私漏洞{#request-smuggling-vulnerability-in-go}

审计人员发现 Istio 可以接受使用 HTTP/2 Over Cleartext（h2c）的流量，
这是一种与 HTTP/1.1 建立未加密连接然后升级到 HTTP/2 的方法。
[用于 h2c 连接的 Go 语言库](https://pkg.go.dev/golang.org/x/net/http2/h2c)将整个请求读入内存，
并指出如果您想避免这种情况，请求应该被包裹在 `MaxBytesHandler` 中。

在修复这个错误时，Istio TOC 成员 John Howard
注意到推荐的修复方式引入了一个[请求走私漏洞](https://portswigger.net/web-security/request-smuggling)。
Go 语言团队因此发布了
[CVE-2022-41721](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-41721) — 本次审计发现的唯一漏洞！

Istio 已更改为始终禁用 h2c 升级支持。

### 文件获取的改进{#improvements-to-file-fetching}

发现的最常见问题类别与 Istio 通过网络获取文件有关（例如，
Istio Operator 安装 Helm Chart，或 WebAssembly 模块下载器）：

* 精雕细琢的 Helm Chart 可能会耗尽磁盘空间（#1）或覆盖
  Operator 的 Pod 中的其他文件（#2）
* 文件句柄在发生错误的情况下不会关闭，并且可能会被耗尽（#3）
* 精雕细琢的文件可能会耗尽内存（#4 和 #5）

要执行这些代码路径，攻击者需要足够的权限来为 Helm Chart
或 WebAssembly 模块指定 URL。有了这样的访问权限，
他们就不再需要某些功能：他们已经可以将任意 Chart 安装到集群或将任意
WebAssembly 模块加载到代理服务器的内存中。

审核员和维护者都注意到不建议将 Operator 作为安装方式，
因为这需要高权限控制器才能在集群中运行。

### 其他问题{#other-issues}

发现的其余问题是：

* 在某些测试代码中，或者控制平面组件通过 localhost 连接到另一个组件的情况下，
  未强制执行最低 TLS 设置（#6）
* 失败的操作可能不会返回错误代码（#7）
* 已弃用的库依然在被使用（#8）
* [TOC/TOU](https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use)
  用于复制文件的库中的竞争条件（#9）
* 如果在调试模式下运行，用户可能会耗尽 Security Token Service 的内存（#11）

详情请参考[报告全文（英文）](./Istio%20audit%20report%20-%20ADA%20Logics%20-%202023-01-30%20-%20v1.0.pdf)。

### 对 2020 年报告的回顾{#reviewing-the-2020-report}

Istio 的第一次安全评估中报告的所有 18 个问题都已被发现并得到修复。

### 模糊测试{#fuzzing}

[OSS-Fuzz 项目](https://google.github.io/oss-fuzz/)帮助开源项目执行免费的[模糊测试](https://en.wikipedia.org/wiki/Fuzzing)。
Istio 已被集成到 OSS-Fuzz 中，有 63 个连续运行的模糊测试器：
这种支持是[由 ADA Logics 和 Istio 团队于 2021 年底建立](https://adalogics.com/blog/fuzzing-istio-cve-CVE-2022-23635)。

{{< quote >}}
**“[我们]通过优先考虑 Istio 的安全关键部分来开始模糊测试评估。
我们在其中发现令人印象深刻的测试覆盖率，这几乎已经没有可以改进余地。” - ADA Logics**
{{< /quote >}}

评估指出，“Istio 在很大程度上受益于拥有在 OSS-Fuzz
上持续运行的大量模糊测试套件”，并确定了安全关键代码中的一些 API
将受益于进一步的模糊测试，因此这项工作的结果是贡献了六个新的模糊测试器；
到审计结束时，新测试已经运行了超过 **30 亿** 次。

### SLSA

[软件制品供应链级别](https://slsa.dev/)（SLSA）是用于防止篡改、
提高完整性以及保护软件包和基础设施的一份标准及控制清单。
它被组织成一系列级别，提供越来越多的完整性保证。

Istio 目前不生成制品，因此并不满足任何 SLSA 级别的要求。
[目前正在进行达到 SLSA 1 级的工作](https://github.com/istio/istio/issues/42517)。
如果您想参与，请加入 [Istio Slack](https://slack.istio.io/)
并联系我们的[测试和发布工作组](https://istio.slack.com/archives/C6FCV6WN4)。

## 参与进来{#get-involved}

如果您想参与 Istio 产品安全，或成为一名维护者，我们很乐意邀请您！
[加入我们的公开会议](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)来提出问题或了解我们为确保 Istio 安全所做的工作。

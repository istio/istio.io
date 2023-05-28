---
title: "Istio 发布版 2022 年安全审计结果"
description: Istio 的安全审查在 Go 标准库中发现了一个 CVE。
publishdate: 2023-01-30
attribution: "Craig Box (ARMO)，Istio 产品安全工作组"
keywords: [istio,security,audit,ada logics,assessment,cncf,ostif]
---

Istio is a project that platform engineers trust to enforce security policy in their production Kubernetes environments. We pay a lot of care to security in our code, and maintain a robust [vulnerability program](/docs/releases/security-vulnerabilities/). To validate our work, we periodically invite external review of the project, and we are pleased to publish [the results of our second security audit](./Istio%20audit%20report%20-%20ADA%20Logics%20-%202023-01-30%20-%20v1.0.pdf).
Istio 是一个平台工程师信任的项目，
可以在其 Kubernetes 生产环境中实施安全策略。
我们非常注意代码的安全性，
并致力于维护一个健壮的[漏洞程序集](/zh/docs/releases/security-vulnerabilities/)。
为了验证我们的工作，我们定期邀请项目以外的审查流程，
我们很高兴发布[第二次安全审计的结果](./Istio%20audit%20report%20-%20ADA%20Logics%20-%202023-01-30%20-%20v1.0.pdf)。

The auditors’ assessment was that **"Istio is a well-maintained project that has a strong and sustainable approach to security"**. No critical issues were found; the highlight of the report was the discovery of a vulnerability in the Go programming language.
审计员的评估结论是
**“Istio 是一个维护良好的项目，具有强大且可持续的安全应对方法”**。
没有发现严重问题；该报告的亮点是发现了 Go 编程语言中的一个漏洞。

We would like to thank the [Cloud Native Computing Foundation](https://cncf.io/) for funding this work, as a benefit offered to us after we [joined the CNCF in August](https://www.cncf.io/blog/2022/09/28/istio-sails-into-the-cloud-native-computing-foundation/). It was [arranged by OSTIF](https://ostif.org/the-audit-of-istio-is-complete), and [performed by ADA Logics](https://adalogics.com/blog/istio-security-audit).
我们要感谢[云原生计算基金会](https://cncf.io/)资助这项工作，
作为我们 [8 月份加入 CNCF](https://www.cncf.io/blog/2022/09/28/istio-sails-into-the-cloud-native-computing-foundation/)
后提供给我们的福利。这项工作[由 OSTIF 安排](https://ostif.org/the-audit-of-istio-is-complete)，
[由 ADA Logics 执行](https://adalogics.com/blog/istio-security-audit)。

## Scope and overall findings
## 工作范围和总体调查结果{#scope-and-overall-findings}

[Istio received its first security assessment in 2020](/blog/2021/ncc-security-assessment/), with its data plane, the [Envoy proxy](https://envoyproxy.io/), having been [independently assessed in 2018 and 2021](https://github.com/envoyproxy/envoy#security-audit). The Istio Product Security Working Group and ADA Logics therefore decided on the following scope:
[Istio 在 2020 年接受了第一次安全评估](/zh/blog/2021/ncc-security-assessment/)，
其数据平面和 [Envoy 代理](https://envoyproxy.io/)都已经过
[2018 年和 2021 年的独立评估](https://github.com/envoyproxy/envoy#security-audit)。因此，Istio 产品安全工作组和
ADA Logics 确定了以下工作范围：

* Produce a formal threat model, to guide this and future security audits
* 生成正式的威胁模型，以指导本次和未来的安全审计
* Carry out a manual code audit for security issues
* 对安全问题进行手动代码审计
* Review the fixes for the issues found in the 2020 audit
* 审查 2020 年审计中发现的问题的修复
* Review and improve Istio's fuzzing suite
* 审查和改进 Istio 的模糊测试套件
* Perform a SLSA review of Istio
* 对 Istio 进行 SLSA 审查

Once again, no Critical issues were found in the review. The assessment found 11 security issues; two High, four Medium, four Low and one informational. All the reported issues have been fixed.

{{< quote >}}
**"Istio is a very well-maintained and secure project with a sound code base, well-established security practices and a responsive product security team." - ADA Logics**
{{< /quote >}}

Aside from their observations above, the auditors note that Istio follows a high level of industry standards in dealing with security. In particular, they highlight that:

* The Istio Product Security Working Group responds swiftly to security disclosures
* The documentation on the project’s security is comprehensive, well-written and up to date
* Security vulnerability disclosures follow industry standards and security advisories are clear and detailed
* Security fixes include regression tests

## Resolution and learnings

### Request smuggling vulnerability in Go

The auditors uncovered a situation where Istio could accept traffic using HTTP/2 Over Cleartext (h2c), a method of making an unencrypted connection with HTTP/1.1 and then upgrading to HTTP/2. The [Go library for h2c connections](https://pkg.go.dev/golang.org/x/net/http2/h2c) reads the entire request into memory, and notes that if you wish to avoid this, the request should be wrapped in a `MaxBytesHandler`.

In fixing this bug, Istio TOC member John Howard noticed that the recommended fix introduces a [request smuggling vulnerability](https://portswigger.net/web-security/request-smuggling). The Go team thus published [CVE-2022-41721](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-41721) — the only vulnerability discovered by this audit!

Istio has since been changed to disable h2c upgrade support throughout.

### Improvements to file fetching

The most common class of issue found were related to Istio fetching files over a network (for example, the Istio Operator installing Helm charts, or the WebAssembly module downloader):

* A crafted Helm chart could exhaust disk space (#1) or overwrite other files in the Operator’s pod (#2)
* File handles were not closed in the case of an error, and could be exhausted (#3)
* Crafted files could exhaust memory  (#4 and #5)

To execute these code paths, an attacker would need enough privilege to either specify a URL for a Helm chart or a WebAssembly module.  With such access, they would not need an exploit: they could already cause an arbitrary chart to be installed to the cluster or an arbitrary WebAssembly module to be loaded into memory on the proxy servers.

The auditors and maintainers both note that the Operator is not recommended as a method of installation, as this requires a high-privilege controller to run in the cluster.

### Other issues

The remaining issues found were:

* In some testing code, or where a control plane component connects to another component over localhost, minimum TLS settings were not enforced (#6)
* Operations that failed may not return error codes (#7)
* A deprecated library was being used (#8)
* [TOC/TOU](https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use) race conditions in a library used for copying files (#9)
* A user could exhaust the memory of the Security Token Service if running in Debug mode (#11)

Please refer to [the full report](./Istio%20audit%20report%20-%20ADA%20Logics%20-%202023-01-30%20-%20v1.0.pdf) for details.

### Reviewing the 2020 report

All 18 issues reported in Istio’s first security assessment were found to have been fixed.

### Fuzzing

The [OSS-Fuzz project](https://google.github.io/oss-fuzz/) helps open source projects perform free [fuzz testing](https://en.wikipedia.org/wiki/Fuzzing). Istio is integrated into OSS-Fuzz with 63 fuzzers running continuously: this support was [built by ADA Logics and the Istio team in late 2021](https://adalogics.com/blog/fuzzing-istio-cve-CVE-2022-23635).

{{< quote >}}
**"[We] started the fuzzing assessment by prioritizing security-critical parts of Istio. We found that many of these had impressive test coverage with little to no room for improvement." - ADA Logics**
{{< /quote >}}

The assessment notes that "Istio benefits largely from having a substantial fuzz test suite that runs continuously on OSS-Fuzz", and identified a few APIs in security-critical code that would benefit from further fuzzing, Six new fuzzers were contributed as a result of this work; by the end of the audit, the new tests had run over **3 billion** times.

### SLSA

[Supply chain Levels for Software Artifacts](https://slsa.dev/) (SLSA) is a check-list of standards and controls to prevent tampering, improve integrity, and secure software packages and infrastructure. It is organized into a series of levels that provide increasing integrity guarantees.

Istio does not currently generate provenance artifacts, so it does not meet the requirements for any SLSA levels.  [Work on reaching SLSA Level 1 is currently underway](https://github.com/istio/istio/issues/42517). If you would like to get involved, please join the [Istio Slack](https://slack.istio.io/) and reach out to our [Test and Release working group](https://istio.slack.com/archives/C6FCV6WN4).

## Get involved

If you want to get involved with Istio product security, or become a maintainer, we’d love to have you! [Join our public meetings](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) to raise issues or learn about what we are doing to keep Istio secure.

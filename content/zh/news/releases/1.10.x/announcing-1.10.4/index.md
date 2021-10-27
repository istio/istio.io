---
title: 发布 Istio 1.10.4 版本
linktitle: 1.10.4
subtitle: 补丁发布
description: Istio 1.10.4 补丁发布。
publishdate: 2021-08-24
release: 1.10.4
aliases:
    - /zh/news/announcing-1.10.4
---

此版本修复了在 8 月 24 日发布的帖子 [ISTIO-SECURITY-2021-008](/zh/news/security/istio-security-2021-008) 中描述的安全问题以及一些小漏洞，提高了稳健性。本次发布说明主要描述 Istio 1.10.3 和 1.10.4 版本之间的不同之处。

{{< relnote >}}

## 安全更新{#security-updates}

- __[CVE-2021-39155](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2CVE-2021-39155])__ __([CVE-2021-32779](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32779))__：
  Istio 授权策略错误地以区分大小写的方式来比较主机头，而 RFC 4343 规定它应该是不区分大小写。Envoy 以不区分大小写的方式路由请求主机名，这意味着授权策略可以被绕过。
    - __CVSS Score__：8.3 [CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:L](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:L)

- __[CVE-2021-39156](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2CVE-2021-39156])__：
  Istio 存在一个可远程利用的漏洞，路径中带有片段（例如#Section）的 HTTP 请求可能会绕过 Istio 基于 URI 路径的授权策略。
    - __CVSS Score__：8.1 [CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N)

### Envoy 安全更新{#envoy-security-updates}

- [CVE-2021-32777](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32777) (CVSS score 8.6，High)：Envoy 存在一个可远程利用的漏洞，当使用 `ext_authz` 扩展时，带有多个值标头的 HTTP 请求可能会绕过授权策略。

- [CVE-2021-32778](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32778) (CVSS score 8.6，High)：Envoy 存在一个可远程利用的漏洞，其中 Envoy 客户端打开并重置大量 HTTP/2 请求可能会导致 CPU 消耗过多。

- [CVE-2021-32780](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32780) (CVSS score 8.6，High)：Envoy 存在一个可远程利用的漏洞，不受信任的上游服务可以通过发送 GOAWAY 帧和 SETTINGS 帧，并将 `SETTINGS_MAX_CONCURRENT_STREAMS` 参数设置为 0，导致 Envoy 异常终止。
  注意：该漏洞不影响下游客户的连接。

- [CVE-2021-32781](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32781) (CVSS score 8.6，High)：Envoy 存在一个可远程利用的漏洞，该漏洞影响 Envoy 的解压器、json-transcoder 或 grpc-web 扩展，或修改和增加请求或响应体的大小的专有扩展。在 Envoy 扩展中修改和增加体的大小超过内部缓冲区的大小，可能会导致 Envoy 访问已分配的内存并异常终止。

## 变化{#changes}

- **新增** 新增防止空的正则表达式匹配的验证器。([Issue #34065](https://github.com/istio/istio/issues/34065))

- **新增** 新增新的分析器，用于检查不会被注入的 Pod 和部署中的 `image: auto`。

- **修复** 修复了在同一端口使用 `SIMPLE` 和 `PASSTHROUGH` 模式的多个网关无法正常工作的问题。([Issue #33405](https://github.com/istio/istio/issues/33405))

- **修复** 修复了 Kubernetes Ingress 中导致前缀为 `/foo` 的路径与路由 `/foo/` 相匹配，而不是路由 `/foo` 的问题。

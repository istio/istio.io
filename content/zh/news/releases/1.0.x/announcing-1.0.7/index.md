---
title: 含有重要安全更新的 Istio 1.0.7 发布公告
linktitle: 1.0.7
subtitle: 补丁发布
description: Istio 1.0.7 补丁发布。
publishdate: 2019-04-05
release: 1.0.7
aliases:
    - /zh/about/notes/1.0.7
    - /zh/blog/2019/announcing-1.0.7
    - /zh/news/2019/announcing-1.0.7
    - /zh/news/announcing-1.0.7
---

我们很高兴的宣布 Istio 1.0.7 现已正式发布。下面是更新详情。

{{< relnote >}}

## 安全更新{#security-update}

最近在 Envoy 代理中发现了两个安全漏洞 ([CVE 2019-9900](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9900) 和 [CVE 2019-9901](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9901))。
此漏洞已在 Envoy 1.9.1 版中被修复，相应地，也对 Istio 1.1.2 和 Istio 1.0.7 内置的 Envoy 进行了修复。
由于 Envoy 是 Istio 不可或缺的一部分，因此建议用户立即更新 Istio，以防范由这些漏洞引起的安全风险。

漏洞实际上是这样导致的：Envoy 没有规范化 HTTP URI 路径，也没有完全验证 HTTP/1.1 header 值。这些漏洞影响了依赖于 Envoy 强制执行授权、路由和速率限制的 Istio 特性。

## 受影响的 Istio 版本{#affected-Istio-releases}

以下 Istio 版本容易受到攻击：

- 1.1, 1.1.1
    - 这些版本可以升级至 Istio 1.1.2。
    - 1.1.2 与 1.1.1 是基于相同源码构建的，仅添加了解决 CVE 的 Envoy 补丁。

- 1.0, 1.0.1, 1.0.2, 1.0.3, 1.0.4, 1.0.5, 1.0.6
    - 这些版本可以升级至 Istio 1.0.7。
    - 1.0.6 与 1.0.7 是基于相同源码构建的，仅添加了解决 CVE 的 Envoy 补丁。

- 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8
    - 这些发行版不再受支持，也不会进行修补。 请升级到受支持的版本，以获取必要的修复程序。

## 漏洞影响{#vulnerability-impact}

[CVE 2019-9900](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9900) 和 [CVE 2019-9901](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9901)
允许远程攻击者使用特制的请求 URI 路径（9901）和 HTTP/1.1 header 中的 NUL 字节（9900）来访问未经授权的资源，并可能绕过速率限制等 DoS 防御系统，或路由至未暴露的上游系统。
参阅 [issue 6434](https://github.com/envoyproxy/envoy/issues/6434) 和 [issue 6435](https://github.com/envoyproxy/envoy/issues/6435) 获取更多信息。

由于 Istio 基于 Envoy，因此 Istio 客户可能会受到这些漏洞的影响，具体取决于 Istio 策略和路由规则中是否使用了路径和请求 header 以及后端 HTTP 实现是如何解析它们的。

如果 Mixer 或 Istio 的授权策略或路由规则使用前缀路径匹配规则，则攻击者可能利用这些漏洞来访问某些 HTTP 后端上的未授权路径。

## 防范{#mitigation}

消除漏洞需要更新到正确的 Envoy 版本。我们已经在最新的 Istio 修补程序版本中合并了必要的更新。

对于 Istio 1.1.x deployment：至少升级至 [Istio 1.1.2](/zh/news/releases/1.1.x/announcing-1.1.2)

对于 Istio 1.0.x deployment：至少升级至 [Istio 1.0.7](/zh/news/releases/1.0.x/announcing-1.0.7)

尽管 Envoy 1.9.1 需要选择路径规范化以解决 CVE 2019-9901，但默认情况下，Istio 1.1.2 和 1.0.7 中内置的 Envoy 版本已经启用了路径规范化。

## 检测 NUL header 漏洞{#detection-of-NUL-header-exploit}

根据目前的信息，这只会影响 HTTP/1.1 的流量。如果您的网络或配置不是这种结构，那么此漏洞不太可能影响到您。

基于文件的访问日志记录与 gRPC 访问日志记录一样，使用 `c_str()` 表示 header 值，因此扫描 NUL，不会发现通过 Envoy 的访问日志的任何异常。

相反，运维人员可能会在 Envoy 执行的路由和 `RouteConfiguration` 预期的逻辑之间的日志中寻找不一致之处。

外部授权和速率限制服务可以检查 header 中的 NUL。后端服务器可能具有足够的日志记录来检测 NUL 或意外访问；根据 RFC 7230，在这种情况下，很可能会通过 400 bad request 简单地拒绝 NUL。

## 检测路径遍历漏洞{#detection-of-path-traversal-exploit}

Envoy 的访问日志（基于文件或 gRPC ）将包含非规范化路径，因此可以检查这些日志以检测可疑的模式和与预期的运维人员配置意图不一致的请求。此外，在 `ext_authz`、速率限制和后端服务器上可以使用非规范化路径进行日志检查。

---
title: ISTIO-SECURITY-2020-003
subtitle: 安全公告
description: Envoy 中存在两个未受控的资源消耗问题和两个错误的访问控制漏洞。
cves: [CVE-2020-8659, CVE-2020-8660, CVE-2020-8661, CVE-2020-8664]
cvss: "7.5"
releases: ["1.4 to 1.4.5"]
publishdate: 2020-03-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy 和随后的 Istio 发现了四个新的漏洞：

* __[CVE-2020-8659](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8659)__：当代理 HTTP/1.1 请求或响应时，Envoy 代理可能会消耗过多的内存，特别是对于许多小的（即 1 字节）块。Envoy 为每个传入或传出的块分配一个单独的缓冲区片段，大小取最接近的 4Kb，并且在提交数据后不会释放空块。如果对具有许多小块的请求或响应进行处理，而对等方的读取速度较慢或无法读取代理数据，则可能会导致极高的内存开销。内存开销可能比配置的缓冲区限制高两到三个数量级。
    * CVSS Score: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F/RL:X/RC:X)

* __[CVE-2020-8660](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8660)__：Envoy 代理包含一个 TLS 检查器，可以被仅使用 TLS 1.3 的客户端绕过（不被识别为 TLS 客户端）。因为 TLS 扩展（SNI、ALPN）未被检查，这些连接可能会匹配到错误的过滤器链，可能绕过一些安全限制。
    * CVSS Score: 5.3 [AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N)

* __[CVE-2020-8661](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8661)__：当响应管线化的HTTP/1.1请求时，Envoy 代理可能会消耗过多的内存。在非法形式请求的情况下，Envoy 会发送一个内部生成的 400 错误，该错误会发送到 `Network::Connection` 缓冲区。如果客户端缓慢读取这些响应，就有可能积累大量响应，从而消耗功能上无限的内存。这将绕过 Envoy 的过载管理器，当 Envoy 接近配置的内存阈值时，过载管理器本身也会发送一个内部生成的响应，进一步加剧了这个问题。
    * CVSS Score: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F/RL:X/RC:X)

* __[CVE-2020-8664](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8664)__：在 Envoy 代理中，对于 SDS TLS 验证上下文，只有在首次接收到密钥或其值发生变化时才会调用更新回调函数。这导致了一个竞态条件，即其他引用相同密钥的资源（例如，可信 CA）在密钥的值发生变化之前无法配置，从而创建了一个可能较大的窗口，可以完全绕过来自静态（"default"）部分的安全检查。
    * CVSS Score: 5.3 [AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N)

    此漏洞仅影响 Istio 1.4.5 及更早版本的 SDS 实现的证书轮换机制，仅在启用 SDS 和相互 TLS 时才会受到影响。在先于 Istio 1.5 版本的所有版本中，SDS 默认关闭，操作员必须显式启用。Istio 基于 Kubernetes 密钥挂载的默认密钥分发实现不受此漏洞影响。

    **检测**

    要确定您的系统是否启用了 SDS，请运行以下命令：

    {{< text bash >}}
    $ kubectl get pod -l app=pilot -o yaml | grep SDS_ENABLED -A 1
    {{< /text >}}

    如果输出包含：

    {{< text plain>}}
    -  name: SDS_ENABLED
    value: "true"
    {{< /text >}}

    您的系统已启用SDS。

    要确定您的系统是否启用了双向传输层安全（Mutual TLS），请运行以下命令：

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces -o yaml | grep trafficPolicy -A 2
    {{< /text >}}

    如果输出包含：

    {{< text plain>}}
    --
    trafficPolicy:
    tls:
    mode: ISTIO_MUTUAL
    {{< /text >}}

    您的系统已启用了双向 TLS。

## 防范

* For Istio 1.4.x deployments: update to [Istio 1.4.6](/news/releases/1.4.x/announcing-1.4.6) or later.
* For Istio 1.5.x deployments: Istio 1.5.0 will contain the equivalent security fixes.
* 对于 Istio 1.4.x 的部署：请升级至 Istio 1.4.6 或更高版本。
* 对于 Istio 1.5.x 的部署：Istio 1.5.0 将包含相应的安全修复。
{{< boilerplate "security-vulnerability" >}}

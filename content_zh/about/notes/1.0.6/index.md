---
title: Istio 1.0.6
publishdate: 2019-02-12
icon: notes
---

本次发布中包含了安全缺陷的修复，并增强了系统的健壮性。发行声明中包含了 Istio 1.0.5 和 1.0.6 之间的差别。

{{< relnote_links >}}

## 修复安全缺陷

- 针对 [`CVE-2018-18074`](https://nvd.nist.gov/vuln/detail/CVE-2018-18074) 和 [`CVE-2018-20060`](https://nvd.nist.gov/vuln/detail/CVE-2018-20060)，修正了 Bookinfo 示例中 Go 语言的 `requests` 和 `urllib3` 库。
- 修正了 `Grafana` 和 `Kiali` 中的密码泄露问题（[Issue 7446](https://github.com/istio/istio/issues/7476) 和 [Issue 7447](https://github.com/istio/istio/issues/7447)）。
- 可以利用 Pilot 内存中的服务注册表，通过 Pilot 调试 API 向代理中写入端点信息。这一功能现已移除。

## 增强健壮性

- 在高负载情况下，Pilot 无法进行配置推送（[Issue 10360](https://github.com/istio/istio/issues/10360)）的问题已经修复。
- 修正了一处会导致 Pilot 崩溃重启的竞争场景（[Issue 10868](https://github.com/istio/istio/issues/10868)）。
- 修复了 Pilot 中的一处内存泄漏（[Issue 10822](https://github.com/istio/istio/issues/10822)）。
- 修复了 Mixer 中的一处内存泄漏（[Issue 10393](https://github.com/istio/istio/issues/10393)）。

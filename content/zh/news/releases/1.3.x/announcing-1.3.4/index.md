---
title: Istio 1.3.4 发布公告
linktitle: 1.3.4
subtitle: 补丁发布
description: Istio 1.3.4 补丁发布。
publishdate: 2019-11-01
release: 1.3.4
aliases:
    - /zh/news/2019/announcing-1.3.4
    - /zh/news/announcing-1.3.4
---

此版本发布了包含提高系统稳定性的错误修复程序，下面是 Istio 1.3.3 和 Istio 1.3.4 之间的区别。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- **修复** Google 节点代理提供程序中的崩溃错误。（[Pull Request #18296](https://github.com/istio/istio/pull/18260)）
- **修复** Prometheus 注释，并将 Jaeger 更新为 1.14。（[Pull Request #18274](https://github.com/istio/istio/pull/18274)）
- **修复** 入站侦听器重载间隔为 5 分钟。([Issue #18138](https://github.com/istio/istio/issues/18088)）
- **修复** 密钥和证书轮换的验证问题。（[Issue #17718](https://github.com/istio/istio/issues/17718)）
- **修复** 无效的内部资源垃圾回收问题。（[Issue #16818](https://github.com/istio/istio/issues/16818)）
- **修复** 在失败时不更新 webhook 的问题。（[Pull Request #17820](https://github.com/istio/istio/pull/17820)）
- **Improved** OpenCensus 跟踪适配器的性能问题。([Issue #18042](https://github.com/istio/istio/issues/18042)）

## 小的增强{#minor-enhancements}

- **增强** SDS 服务的可靠性。（[Issue #17409](https://github.com/istio/istio/issues/17409), [Issue #17905](https://github.com/istio/istio/issues/17905)）
- **添加** 稳定版本的故障域标签。（[Pull Request #17755](https://github.com/istio/istio/pull/17755)）
- **添加** 更新与升级相关的全局网格策略。（[Pull Request #17033](https://github.com/istio/istio/pull/17033)）

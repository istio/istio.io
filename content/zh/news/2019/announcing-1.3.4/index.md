---
title: 宣布 Istio 1.3.4 发布
description: Istio 1.3.4 发布声明。
publishdate: 2019-11-01
attribution: The Istio Team
subtitle: 次要更新
release: 1.3.4
---

此版本包含 bug 修复以提高健壮性。此 release 说明包含 Istio 1.3.3 版本与 1.3.4 版本的区别。

{{< relnote >}}

## Bug 修复

- **修复** Google 节点 agent 导致崩溃的错误。([Pull Request #18296](https://github.com/istio/istio/pull/18260))
- **修复** Prometheus 注解和更新 Jaeger 到 1.14 版本。([Pull Request #18274](https://github.com/istio/istio/pull/18274))
- **修复** 入站侦听器重载间隔调整为 5 分钟。([Issue #18138](https://github.com/istio/istio/issues/18088))
- **修复** 密钥验证和证书轮换。([Issue #17718](https://github.com/istio/istio/issues/17718))
- **修复** 内部资源垃圾回收无效问题。([Issue #16818](https://github.com/istio/istio/issues/16818))
- **修复** 了当故障时 webhook 更新失败的问题。([Pull Request #17820](https://github.com/istio/istio/pull/17820)
- **改进** OpenCensus 跟踪适配器的性能。([Issue #18042](https://github.com/istio/istio/issues/18042))

## 小幅改善

- **改进** SDS 服务的可靠性。([Issue #17409](https://github.com/istio/istio/issues/17409), [Issue #17905](https://github.com/istio/istio/issues/17905])
- **新增** 故障域标签的稳定版本。([Pull Request #17755](https://github.com/istio/istio/pull/17755))
- **新增** 全局网格更新策略的升级。([Pull Request #17033](https://github.com/istio/istio/pull/17033))

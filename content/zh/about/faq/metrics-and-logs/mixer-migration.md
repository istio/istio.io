---
title: 如何迁移现有的 Mixer 功能？
weight: 30
---

Mixer在 [Istio 1.8 版本中被移除](/zh/news/releases/1.8.x/announcing-1.8/#deprecations)。
如果您仍然依赖于 Mixer 的内置适配器或任何进程外的适配器进行网格扩展，则需要迁移。

对于内置适配器，提供了几种替代方案：

* `Prometheus` 和 `Stackdriver` 集成是作为[代理扩展](/zh/docs/reference/config/proxy_extensions/)实现的。
    这两个扩展生成的 Telemetry 的定制可以通过[请求分类](/zh/docs/tasks/observability/metrics/classify-metrics/)和 [Prometheus 指标定制](/zh/docs/tasks/observability/metrics/customize-metrics/)来实现。
* Global 和 Local Rate-Limiting (`memquota` 和 `redisquota` 适配器)功能是通过[基于 Envoy 的速率限制解决方案提供的](/zh/docs/tasks/policy-enforcement/rate-limit/)。
* `OPA` 适配器被[基于 Envoy ext-authz 的解决方案](/zh/docs/tasks/security/authorization/authz-custom/)所取代，该解决方案支持与 [OPA 策略代理的集成](https://www.openpolicyagent.org/docs/latest/envoy-introduction/)。

对于自定义进程外适配器，强烈建议迁移到基于 Wasm 的扩展。请参阅有关 [Wasm 模块开发](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)和[扩展分发](/zh/docs/tasks/extensibility/wasm-module-distribution/)的指南。作为临时解决方案，您可以在 [Mixer 中启用 Envoy ext-authz 和 gRPC 访问日志 API 支持](https://github.com/istio/istio/wiki/Enabling-Envoy-Authorization-Service-and-gRPC-Access-Log-Service-With-Mixer)，这允许您将 Istio 升级到发布 1.7 版本，同时仍然使用 1.7 Mixer 的进程外适配器。这将使您有更多时间迁移到基于 Wasm 的扩展。请注意，此临时解决方案未经实战测试，不太可能得到补丁修复，因为它只在 Istio 1.7 分支上可用，这是在 2021 年 2月 之后的支持窗口之外的。

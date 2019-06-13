---
title: 适配器
---

适配器（adapter）是 Istio 的[策略与遥测](/zh/docs/concepts/policies-and-telemetry/)组件： Mixer 里的插件。适配器使 Mixer 可以通过接口使用开放式基础设施后端服务，去为 Istio 提供核心功能，比如日志、监控、配额、ACL 检查等等。

运行时确切生效的适配器是通过配置指定的，而且适配器很容易进行扩展来适配一个新的或者自定义的基础设施后端服务。

[了解更多关于适配器](/zh/docs/concepts/policies-and-telemetry/#适配器)

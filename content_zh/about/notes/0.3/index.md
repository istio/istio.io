---
title: Istio 0.3
weight: 98
icon: notes
---

## 通用

0.3 开始，Istio 进入以月为单位的发布节奏。希望这一举措能够增强团队按时交付的能力。[Feature stages](/zh/about/feature-stages/) 中会提供关于各个功能实现情况的相关信息。

这一阶段里，团队致力于内部的基础设施建设以及工作效率的提高，因此这一版本在功能上面乏善可陈。解决了为数众多的 Bug 和问题，改善了总体性能表现。

## 安全

- **控制平面通信加密**：Mixer 和 Pilot 之间的通信和其他网格内的服务一样，开始使用双向 TLS 加密。

- **可选的认证方式**：可以用服务注解的方式，控制单个服务的认证方式，这对向 Istio 逐步迁移的过程是大有帮助的。

## 网络

- **TCP 的 Egress 规则支持**：现在 Egress 规则可以用于控制 TCP 级别的流量了。

## 策略实施和遥测

- **增强缓存**：Envoy 和 Mixer 之间的缓存大幅改善，鉴权检查过程造成的延迟显著降低。

- **List 适配器改良**：Mixer 的 `list` 适配器提供了正则表达式的匹配支持。参考 [List 配置选项](/docs/reference/config/policy-and-telemetry/adapters/list/)可以获得更多信息。

- **配置校验**：Mixer 会对配置状态进行更多检查，以期尽早发现问题。我们希望未来版本中会进行更多这方面的改善。

如果希望了解更多低级细节，可以进一步阅读[发行说明](https://github.com/istio/istio/wiki/v0.3.0)。

{{< relnote_links >}}

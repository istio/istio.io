---
title: Istio 0.3 发布公告
linktitle: 0.3
subtitle: 重大更新
description: Istio 0.3 发布公告。
publishdate: 2017-11-29
release: 0.3.0
aliases:
    - /zh/about/notes/older/0.3
    - /zh/docs/welcome/notes/0.3.html
    - /zh/about/notes/0.3/index.html
    - /zh/news/2017/announcing-0.3
    - /zh/news/announcing-0.3
---

我们很高兴的宣布 Istio 0.3 现已正式发布。下面是更新详情。

{{< relnote >}}

## 概况{#general}

从 0.3 开始，Istio 的发布节奏切换为月度更新。我们希望这将有助于提高我们及时提供改进的能力。有关此版本的各个功能的状态，请参见 [here](/zh/about/feature-stages/)。

团队将重点放在内部基础设施工作上，以提高我们的速度，所以在新功能方面，这是一个相当适中的发布。解决了许多错误和较小的问题，并在许多方面提高了整体性能。

## 安全{#security}

- **安全的控制平面通信**。Mixer 和 Pilot 现在由双向 TLS 保障安全，就像网格中的所有服务一样。

- **选择性认证**。现在，您可以通过服务注释在每个服务的基础上控制身份验证，这有助于逐步迁移到 Istio。

## 网络{#networking}

- **TCP Egress 规则**。现在，您可以指定影响 TCP 级别流量的 Egress 规则。

## 策略执行和遥测{#policy-enforcement-and-telemetry}

- **改善缓存**。Envoy 和 Mixer 之间的缓存得到了很大改善，大大降低了授权检查的平均延迟。

- **改进的列表适配器**。Mixer “列表” 适配器现在支持正则表达式匹配。有关详细信息，请参见适配器的[配置选项](/zh/docs/reference/config/policy-and-telemetry/adapters/list/)。

- **配置校验**。Mixer 对配置状态进行更广泛的验证，以便更早发现问题。我们希望在即将发布的版本中，投入更多的精力在此功能上。

如果您想了解细节，可以在[这里](https://github.com/istio/istio/wiki/v0.3.0)查看我们更详细的低级发行说明。

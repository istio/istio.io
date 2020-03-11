---
title: 发布 Istio 1.4 版本
linktitle: 1.4
subtitle: 重大更新
description: Istio 1.4 版本发布公告。
publishdate: 2019-11-14
release: 1.4.0
skip_list: true
aliases:
    - /zh/news/2019/announcing-1.4
    - /zh/news/announcing-1.4.0
    - /zh/news/announcing-1.4
---

我们很高兴地宣布 Istio 1.4 版本发布啦！

{{<relnote>}}

`Istio 1.4` 继续致力于改善 `Istio` 用户的体验，并着重于简化使用方式。我们还在继续添加新功能，以提高 `Istio` 的运行性能和使用体验。

## Mixer-less 遥测技术{#mixer-less-telemetry}

我们在不使用 `Mixer` 的情况下实施遥测技术以简化网格的安装和操作，同时极大地提高性能。HTTP 指标代理已从实验性过渡到了 `alpha`。这一功能的改进深受用户喜爱，当然，我们还在继续努力完善此项功能。我们还添加了不需要 `Mixer` 的新实验功能：`TCP` 指标和 `Stackdriver` 指标。

## 处在 `beta` 中的授权模型{#authorization-policy-model-in-beta}

授权策略模型现在处于 `Beta` 中，其中引入了以简化和灵活性为重点的 [`v1beta1` authorization policy](/zh/blog/2019/v1beta1-authorization-policy/) 策略。这也将取代旧的 [`v1alpha1` RBAC policy](/zh/docs/reference/config/security/istio.rbac.v1alpha1/) 策略。

## Automatic mutual TLS

我们添加了 [automatic mutual TLS support](/zh/docs/tasks/security/authentication/auto-mtls/)。它允许您采用双向 `TLS`，而无需配置目标规则。`Istio` 自动对客户端 `Sidecar` 代理进行编程，以双向 `TLS` 发送到能够接受双向 `TLS` 的服务器端点。

如果想在目前的版本中使用，必须手动配置启用，但是我们计划在以后的版本中默认启用它。

## 改善故障排除方法{#improved-troubleshooting}

我们正在引入 [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 命令来改善排除网格故障的困难。检查网格中的配置，以及在将新配置提交到网格之前要对其进行验证。

## 更好的 sidecar{#better-sidecar}

我们一直在做大量工作来改善 `Envoy` 的功能和用户使用体验，`Envoy` 在崩溃时可以更正常地退出，它支持更多指标，并且可以将流量映射到一定的比例。它会报告流量的来源，并且可以更好地配置 `stat patterns`。最后，有一个新的[实验命令](/zh/docs/reference/commands/istioctl/#istioctl-experimental-wait)  ，可以告诉您将所有代理推送到网格中的时间。

## 其他增强功能{#other-enhancements}

- Citadel 将定期检查和更换过期的根证书
- 我们增加了对 OpenAPI v3 模式验证的支持
- 实验性的多群集设置已添加到 `istioctl` 命令中
- 我们通过删除 Docker 镜像中的 `proxy_init` 从而简化安装

与往常一样，[社区会议](https://github.com/istio/community#community-meeting)上会发生很多相关事宜；所以请在太平洋时间的每个星期四上午的 11 点钟请加入我们。

我们很荣幸被评选为在 GitHub 上[增长最快](https://octoverse.github.com/#top-and-trending-projects)的五个开源项目之一。你想参与其中吗？加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一 ，让我们一起把 Istio 变得更好。

要加入我们，请访问 [discuss.istio.io](https://discuss.istio.io)，并使用您的 GitHub 账号登录！

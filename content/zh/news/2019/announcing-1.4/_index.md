---
title: Istio 1.4 发布
subtitle: 重要更新
description: Istio 1.4 发布声明。
publishdate: 2019-11-14
release: 1.4.0
skip_list: true
aliases:
    - /zh/news/announcing-1.4
---

我们很高兴地宣布，Istio 1.4 发布！

{{< relnote >}}

Istio 1.4 着重于简化，以继续努力改善 Istio 的用户体验。
同时我们也持续添加功能，以改善运行 Istio 的性能和体验。

## 无 Mixer 遥测{#mixer-less-telemetry}

我们在没有 Mixer 的情况下实施遥测将简化网格的安装和操作，同时大大提高性能。
HTTP指标的代理内生成已从实验性过渡到 Alpha。
用户对此改进感到非常兴奋，我们正在努力将其就绪。
我们还添加了不需要 Mixer 的新实验功能：TCP 指标和 Stackdriver 指标。

## 授权策略模型已 `beta` {#authorization-policy-model-in-beta}

授权策略模型现在已经 Beta（[`v1beta1` 授权策略介绍](/zh/blog/2019/v1beta1-authorization-policy/)），该策略着重于简化和灵活性。
这也将取代旧的 [v1alpha1 RBAC 策略](/zh/docs/reference/config/security/istio.rbac.v1alpha1/)。

## 改进的故障排除{#improved-troubleshooting}

我们引入了 [`istioctl analysis`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 命令，以改进对网格的故障排除。
它可以帮您检查网格中的配置问题，甚至在将新配置提交到网格之前对其进行验证。

## 更好的 sidecar{#better-sidecar}

我们一直在做大量工作来改进 Envoy，包括其功能集和使用体验。
现在，Envoy 在崩溃时可以更优雅地退出，支持更多指标，并且可以镜像一定比例的流量。
它报告流量的方向，并具有更好的 `stat patterns` 配置。
最后，有一个新的[实验命令](/zh/docs/reference/commands/istioctl/#istioctl-experimental-wait)可以告诉您配置是何时被推送到网格中的所有代理的。

## 其它改进{#other-enhancements}

- Citadel 现在将定期检查并轮换过期的根证书
- 我们增加了对 OpenAPI v3 模式验证的支持
- 实验性多群集设置已添加到 `istioctl`
- 我们通过删除 `proxy_init` Docker 镜像简化了安装

与往常一样，[社区会议](https://github.com/istio/community#community-meeting)上发生了很多事情；您可以在每隔一周的周四上午 11 点（[太平洋时间](https://zh.wikipedia.org/zh-hans/%E5%A4%AA%E5%B9%B3%E6%B4%8B%E6%97%B6%E5%8C%BA)）加入我们。

我们很荣幸被评选为 GitHub 上[发展最快](https://octoverse.github.com/#top-and-trending-projects)的五个开源项目之一。
想参与其中吗？
加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一，帮助我们使 Istio 变得更好。

要加入对话，请转到 [discuss.istio.io](https://discuss.istio.io)，使用您的 GitHub 账号登录并加入我们！

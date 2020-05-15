---
title: Istio 1.2.4 sidecar 镜像漏洞
description: 由于错误的发布操作，出现了错误的 1.2.4 sidecar 镜像。
releases: ["1.2 to 1.2.4"]
publishdate: 2019-09-10
keywords: [community,blog,security]
aliases:
    - /zh/blog/2019/incorrect-sidecar-image-1.2.4
    - /zh/news/2019/incorrect-sidecar-image-1.2.4
---
致 Istio 用户社区，

在太平洋标准时间 2019 年 8 月 23 日下午 9:16 至太平洋标准时间 2019 年 9 月 6 日上午 09:26 之间，Istio `proxyv2` 1.2.4（参见 [https://hub.docker.com/r/istio/proxyv2](https://hub.docker.com/r/istio/proxyv2)）的 Docker 映像包含了错误的针对 [ISTIO-SECURITY-2019-003](/zh/news/security/istio-security-2019-003/) 和 [ISTIO-SECURITY-2019-004](/zh/news/security/istio-security-2019-004/) 漏洞的代理版本。

如果在此期间安装了 Istio 1.2.4，请考虑升级到还包含其他安全修复程序的 Istio 1.2.5。

## 详细说明{#detailed-explanation}

由于在修复最近的 HTTP2 DoS 漏洞时我们已经执行了通信禁令，因此对于这种类型的发布来说很常见：我们预先私下构建了 Sidecar 的映像，在公开披露的同时，我们在 Docker Hub 上手动推送了该映像。

对于无法修复安全漏洞的秘密披露版本，该 Docker 映像通常会通过我们的发行渠道作业完全自动的完成 push。

我们的自动发布流程无法与漏洞披露禁令所要求的手动交互一起正常工作：发布管道保留了对 Istio 仓库旧版本代码的引用。

出现的问题，自动构建需要基于旧版本构建，这是在 Istio 1.2.5 发行期间的事情：我们遇到了一个需要 [revert commit](https://github.com/istio-releases/pipeline/commit/635d276ad7eac01bef9c3f195520a0f722626c0f) 的问题，该问题触发了基于旧版本 Istio 1.2.4 代码的重建。

此 revert commit 发生在太平洋标准时间 2019 年 8 月 23 日下午 09:16。我们已经注意到该问题，并于太平洋标准时间 2019 年 9 月 6 日上午 09:26 回推了该镜像。

对于由于此事件给您带来的不便，我们感到抱歉，并且我们[正在努力建立更好的发布系统](https://github.com/istio/istio/issues/16887)，以及一种更有效的方式来处理漏洞报告。

- 1.2 的发布管理器

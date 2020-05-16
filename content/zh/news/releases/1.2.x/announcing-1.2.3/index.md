---
title: Istio 1.2.3 发布公告
linktitle: 1.2.3
subtitle: 补丁发布
description: Istio 1.2.3 补丁发布。
publishdate: 2019-08-02
release: 1.2.3
aliases:
    - /zh/about/notes/1.2.3
    - /zh/blog/2019/announcing-1.2.3
    - /zh/news/2019/announcing-1.2.3
    - /zh/news/announcing-1.2.3
---

我们很高兴的宣布 Istio 1.2.3 现在是可用的，具体更新内容如下。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复了一个错误，当 pod 定义了一个端口，而服务未定义该端口时，sidecar 会将请求无限转发给自身（[Issue 14443](https://github.com/istio/istio/issues/14443)）和（[Issue 14242](https://github.com/istio/istio/issues/14242)）
- 修复了启动遥测后 Stackdriver 适配器会关闭的 bug。
- 修复 Redis 连接问题。
- 修复虚拟服务基于正则表达式匹配 HTTP URI 区分大小写的问题（[Issue 14983](https://github.com/istio/istio/issues/14983)）
- 修复 demo 配置文件的 HPA 和 CPU 设置（[Issue 15338](https://github.com/istio/istio/issues/15338)）
- 放宽 Keep-Alive 实施策略，避免在轻负载下断开连接（[Issue 15088](https://github.com/istio/istio/issues/15088)）
- 当未使用 SDS 时，跳过 Kubernetes JWT 身份验证，以降低使用受损（不可信）JWT 的风险。

## 测试升级{#tests-upgrade}

- 更新 Bookinfo 评论示例应用程序的基础镜像版本（[Issue 15477](https://github.com/istio/istio/issues/15477)）
- Bookinfo 示例镜像鉴定（[Issue 14237](https://github.com/istio/istio/issues/14237)）

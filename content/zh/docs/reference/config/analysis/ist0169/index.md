---
title: UpdateIncompatibility
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 [`istioctl x precheck`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
发现某些配置在升级 Istio 后可能会有不同的行为时，会出现此消息。某项设置的默认行为在新版本中发生了变化。

## 如何修复 {#how-to-resolve}

阅读消息文本，它会告诉您哪项设置发生了变化，以及在哪个版本中发生了变化。然后执行以下操作之一：

- 修改您的配置，使其适用于新行为。
- 使用 `--set compatibilityVersion=<version>` 进行安装，以保留旧的默认行为。
  更多信息请参阅[兼容性版本](/zh/docs/setup/additional-setup/compatibility-versions/)。

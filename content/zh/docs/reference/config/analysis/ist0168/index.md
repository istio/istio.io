---
title: UnknownUpgradeCompatibility
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当您使用的某项配置设置在 Istio 新版本中更改了默认行为，
而 Istio 无法自动判断该变更是否会影响您的网格时，会出现此消息。

## 如何修复 {#how-to-resolve}

阅读消息文本以及该版本的升级说明，然后执行以下操作之一：

- 确保新行为适用于您的网格。
- 使用 `--set compatibilityVersion=<version>` 进行安装，以保留旧的默认行为。
  更多信息请参阅[兼容性版本](/zh/docs/setup/additional-setup/compatibility-versions/)。

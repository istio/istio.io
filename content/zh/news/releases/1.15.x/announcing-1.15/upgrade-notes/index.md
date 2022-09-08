---
title: Istio 1.15 升级说明
description: 升级到 Istio 1.15.0 时需要考虑的重要更改。
publishdate: 2022-08-31
weight: 20
---

当您从 Istio 1.14.x 升级到 Istio 1.15.0 时，您需要考虑此页面上所描述的变化。
这些说明详细介绍了有意地破坏与 Istio 1.14.0 的向后兼容性所带来的变化。
说明中还提到了在引入新行为的同时保留向后兼容性的变化。
只有当新的行为对 Istio `1.14.x` 的用户来说是意想不到的时候，才会包括这些变化。
从 1.13.x 升级到 Istio 1.15.0 的用户还应该参考 [1.15.0 变更日志](/zh/news/releases/1.15.x/announcing-1.15/change-notes/)。

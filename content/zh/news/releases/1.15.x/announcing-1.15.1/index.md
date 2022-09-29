---
title: 发布 Istio 1.15.1
linktitle: 1.15.1
subtitle: Patch Release
description: Istio 1.15.1 补丁发布。
publishdate: 2022-09-23
release: 1.15.1
---

此版本包含了一些改进稳健性的漏洞修复。

此发布说明描述了 Istio 1.15.0 和 Istio 1.15.1 之间的不同之处。

{{< relnote >}}

## 变更{#changes}

- **修复** 修复了 `AddRunningKubeSourceWithRevision` 返回一个错误会造成 Istio Operator 进入错误循环的问题。([Issue #39599](https://github.com/istio/istio/issues/39599))

- **修复** 修复了添加 `ServiceEntry` 可能会影响主机名相同的现有 `ServiceEntry` 的问题。([Issue #40166](https://github.com/istio/istio/issues/40166))

- **修复** 修复了 istiod 未运行时用户无法删除 Istio Operator 资源的问题。([Issue #40796](https://github.com/istio/istio/issues/40796))

- **修复** 修复了遥测访问日志为 nil 时不会回退为使用 MeshConfig 的问题。

- **修复** 修复了内置提供程序应在格式未设置时回退为 MeshConfig 的问题。

- **修复** 修复了 `DestinationRule` 应用到多个服务时可能不正确地应用一个非预期 `subjectAltNames` 字段的问题。([Issue #40801](https://github.com/istio/istio/issues/40801))

- **修复** 修复了 1.15.0 中的某个行为变化造成 `ServiceEntry` `SubjectAltName` 字段被忽略的问题。([Issue #40801](https://github.com/istio/istio/issues/40801))

- **改进** 当工作负载缩容为零个实例且进行备份时 xDS 推送会触发部分推送。([Issue #39652](https://github.com/istio/istio/issues/39652))

- **新增** 增加了 Istio 1.14 中移除的 `PILOT_ENABLE_K8S_SELECT_WORKLOAD_ENTRIES` 特性。此特性将持续到用例被明确且添加了更持久的 API 为止。([Pull Request #40716](https://github.com/istio/istio/pull/40716))

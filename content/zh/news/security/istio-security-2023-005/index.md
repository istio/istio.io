---
title: ISTIO-SECURITY-2023-005
subtitle: 安全公告
description: Istio CNI RBAC 权限的变更。
cves: []
cvss: N/A
vector: N/A
releases: [1.18.0 以及之前的所有版本", "1.18.0 到 1.18.5", "1.19.0 到 1.19.4", "1.20.0"]
publishdate: 2023-12-12
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 安全委员会最近意识到一种潜在情况，即 Istio CNI
由于其高级别权限而可能被用作已受感染节点的攻击载体。该载体涉及在受感染的节点上滥用
`istio-cni-repair-role` `ClusterRole`，将危害范围从本地节点扩大到集群范围。

因此，Istio 维护者正在逐步推出对上述 `ClusterRole` 的变更，
以减少权限，关闭此潜在的攻击载体。在补丁版本中，
角色的权限被限制在基于[所选修复模式](/zh/docs/setup/additional-setup/cni/#race-condition--mitigation)的最低必要要求。
在此之前，无论配置如何，都会授权予所有角色，而且被授权的角色过多。

另一个选项可以通过完全消除 Istio CNI 需要自定义 RBAC 权限的需求，来进一步减轻任何潜在的攻击风险；
由于这种新方法可能存在风险，因此仅在 Istio 1.21+ 上默认启用。 请参阅下文了解可用的配置选项以及所需的角色：

| 配置                             | 角色         | 错误时的行为                                      | 备注              |
|--------------------------------|------------|---------------------------------------------|-----------------|
| `values.cni.repair.deletePods` | DELETE Pod | Pod 将被删除，重新调度后它们将具有正确的配置。                   | 1.20 及更早版本中的默认值 |
| `values.cni.repair.labelPods`  | UPDATE Pod | 只对 Pod 打标签。用户需要采取手动操作来解决问题。                    |                 |
| `values.cni.repair.repairPods` | 无          | Pod 会动态的被重新配置以具有适当的配置。当容器重新启动时，Pod 将继续正常执行。 | 1.21 及更高版本中的默认值 |

Istio 安全委员会感谢 `Yuval Avrahami` 披露此问题并与我们合作制定解决方案。

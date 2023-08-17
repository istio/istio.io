---
---
现在，修订版、标记和命名空间之间更新后的映射关系如下所示：

{{< image width="90%"
link="/zh/docs/setup/upgrade/canary/revision-tags-after.svg"
caption="命名空间标签没有变化，但现在所有命名空间都指向 {{< istio_full_version_revision >}}"
>}}

当在带有 `prod-stable` 标签的命名空间中重新启动注入工作负载，将导致这些工作负载使用 `{{< istio_full_version_revision >}}` 控制平面。
请注意，将工作负载迁移到新版本时不需要重新标记命名空间。

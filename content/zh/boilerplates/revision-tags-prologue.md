---
---
现在，情况如下：

{{< image width="70%"
link="/zh/docs/setup/upgrade/canary/tags-updated.png"
caption="Namespace labels unchanged but now all namespaces pointed to 1-10-0"
>}}

当在带有 `prod-stable` 标签的命名空间中重新启动注入工作负载，将导致这些工作负载使用 `1-10-0` 控制平面。
请注意，将工作负载迁移到新版本时不需要重新标记名称空间。
---
---
修订、标签和命名空间之间的结果映射如下所示：

{{< image width="90%"
link="/zh/docs/setup/upgrade/canary/revision-tags-before.svg"
caption="Two namespaces pointed to prod-stable and one pointed to prod-canary"
>}}

除了标记的命名空间之外，集群管理员还可以通过以下 `istioctl tag list` 命令查看此映射：

{{< text bash >}}
$ istioctl tag list
TAG         REVISION NAMESPACES
default     {{< istio_previous_version_revision >}}-1   ...
prod-canary {{< istio_full_version_revision >}}   ...
prod-stable {{< istio_previous_version_revision >}}-1   ...
{{< /text >}}

当集群管理员对标记为 `prod-canary` 的控制面、命名空间的稳定性感到满意后，
`istio.io/rev=prod-stable` 可以通过修改 `prod-stable` 修订标记来更新，
以指向更新的 `{{< istio_full_version_revision >}}` 修订版本。

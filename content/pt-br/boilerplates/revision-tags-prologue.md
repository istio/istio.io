---
---
Now, the updated mapping between revisions, tags, and namespaces is as shown below:

{{< image width="90%"
link="/docs/setup/upgrade/canary/revision-tags-after.svg"
caption="Namespace labels unchanged but now all namespaces pointed to {{< istio_full_version_revision >}}"
>}}

Restarting injected workloads in the namespaces marked `prod-stable` will now result in those workloads using the `{{< istio_full_version_revision >}}`
control plane. Notice that no namespace relabeling was required to migrate workloads to the new revision.

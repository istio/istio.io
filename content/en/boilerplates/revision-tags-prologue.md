---
---
Now, the updated mapping between revisions, tags, and namespaces is as shown below:

{{< image width="70%"
link="/docs/setup/upgrade/canary/tags-updated.png"
caption="Namespace labels unchanged but now all namespaces pointed to 1-10-0"
>}}

Restarting injected workloads in the namespaces marked `prod-stable` will now result in those workloads using the `1-10-0`
control plane. Notice that no namespace relabeling was required to migrate workloads to the new revision.
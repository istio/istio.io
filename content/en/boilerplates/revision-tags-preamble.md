---
---
Manually relabeling namespaces when moving them to a new revision can be tedious and error-prone.
[Revision tags](/docs/reference/commands/istioctl/#istioctl-tag) solve this problem.
[Revision tags](/docs/reference/commands/istioctl/#istioctl-tag) are stable identifiers that point to revisions and can be used to avoid relabeling namespaces. Rather than relabeling the namespace, a mesh operator can simply change the tag to point to a new revision. All namespaces labeled with that tag will be updated at the same time.

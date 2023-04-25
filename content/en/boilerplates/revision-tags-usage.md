---
---
Consider a cluster with two revisions installed, `{{< istio_previous_version_revision >}}-1` and `{{< istio_full_version_revision >}}`. The cluster operator creates a revision tag `prod-stable`,
pointed at the older, stable `{{< istio_previous_version_revision >}}-1` version, and a revision tag `prod-canary` pointed at the newer `{{< istio_full_version_revision >}}` revision. That
state could be reached via the following commands:

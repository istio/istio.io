---
---
Consider a cluster with two revisions installed, `1-9-5` and `1-10-0`. The cluster operator creates a revision tag `prod-stable`,
pointed at the older, stable `1-9-5` version, and a revision tag `prod-canary` pointed at the newer `1-10-0` revision. That
state could be reached via the following commands:

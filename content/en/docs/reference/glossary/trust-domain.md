---
title: Trust Domain
test: n/a
---

[Trust domain](https://spiffe.io/spiffe/concepts/#trust-domain) corresponds to the trust root of a system and is part of a workload identity.

Istio uses a trust domain to create all [identities](/docs/reference/glossary/#identity) within a mesh.
For example in `spiffe://mytrustdomain.com/ns/default/sa/myname` the substring `mytrustdomain.com` specifies that the workload is from a trust domain called `mytrustdomain.com`.

Depending upon your configuration, you can choose to have a single trust domain for the entire mesh across clusters or a trust domain for each cluster, as long as the clusters share the same root of trust.

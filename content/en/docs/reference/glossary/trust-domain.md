---
title: Trust Domain
test: n/a
---

[Trust domain](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/#trust-domain) corresponds to the trust root of a system and is part of a workload identity.

Istio uses a trust domain to create all [identities](/docs/reference/glossary/#identity) within a mesh.
For example in `spiffe://mytrustdomain.com/ns/default/sa/myname` the substring `mytrustdomain.com` specifies that the workload is from a trust domain called `mytrustdomain.com`.

You can have one or more trust domains in a multicluster mesh, as long as the clusters share the same root of trust.

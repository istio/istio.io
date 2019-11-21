---
title: Trust Domain
---

[Trust domain](https://spiffe.io/spiffe/concepts/#trust-domain) corresponds to the trust root of a system and is part of a workload identity

Istio uses a trust domain to create all
[identities](/docs/reference/glossary/#identity) within a mesh. Every mesh has
an exclusive trust domain.

For example in `spiffe://mytrustdomain.com/ns/default/sa/myname` the substring
identifying the mesh is: `mytrustdomain.com`. This substring is the trust
domain of the mesh.

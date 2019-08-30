---
title: Trust Domain
---

A trust domain is a unique name that Istio uses to create all
[identities](/docs/reference/glossary/#identity) within a mesh. Every mesh has
an exclusive trust domain.

For example in `spiffe://mytrustdomain.com/ns/default/sa/myname` the substring
identifying the mesh is: `mytrustdomain.com`. This substring is the trust
domain of the mesh.

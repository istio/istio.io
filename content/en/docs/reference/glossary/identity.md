---
title: Identity
---

An identity is a unique name backed by a key material, for
example:

- [X.509 certificate](https://en.wikipedia.org/wiki/X.509)
- [JWT](https://en.wikipedia.org/wiki/JSON_Web_Token)

Each identity Istio assigns is understood throughout the mesh and you can use it
to enable mutual authentication and enforce policies.

An identity contains a substring identifying the mesh that created it. For
example in `spiffe://mytrustdomain.com/ns/default/sa/myname` the substring
identifying the mesh is: `mytrustdomain.com`. We call this substring the trust
domain of the mesh. Every Istio mesh has a globally unique trust domain used to
create identity names.

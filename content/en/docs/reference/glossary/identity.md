---
title: Identity
---

An identity is a unique name backed by key material, for
example:

- [X.509 certificate](https://en.wikipedia.org/wiki/X.509)
- [JWT](https://en.wikipedia.org/wiki/JSON_Web_Token)

Each identity Istio assigns is understood throughout the mesh and you can use it
to enable mutual authentication and enforce policies.

An identity contains a [trust domain](/docs/reference/glossary/#trust-domain)
identifying the mesh that created it.

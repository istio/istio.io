---
title: Trust Domain
---

An [identity](/docs/reference/glossary/#identity) contains a substring
identifying the mesh that created it. For example in
`spiffe://mytrustdomain.com/ns/default/sa/myname` the substring identifying the
mesh is: `mytrustdomain.com`. We call this substring the trust domain of the
mesh. Every Istio mesh has a globally unique trust domain used to create
identity names.

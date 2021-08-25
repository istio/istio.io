---
---
The revision pointed to by the tag `default` is considered the ***default revision*** and has additional semantic meaning.

The `default` revision will inject sidecars for the `istio-injection=enabled` namespace selector and `sidecar.istio.io/inject=true` object
selector in addition to the `istio.io/rev=default` selectors. This makes it possible to migrate from using non-revisioned Istio to using
a revision entirely without relabeling namespaces. To make a revision `1-10-0` the default, run:

---
---
The revision pointed to by the tag `default` is considered the ***default revision*** and has additional semantic meaning. The default
revision performs the following functions:

- Injects sidecars for the `istio-injection=enabled` namespace selector, the `sidecar.istio.io/inject=true` object
  selector, and the `istio.io/rev=default` selectors
- Validates Istio resources
- Steals the leader lock from non-default revisions and performs singleton mesh responsibilities (such as updating resource statuses)

To make a revision `{{< istio_full_version_revision >}}` the default, run:

---
title: NamespaceNotInjected
layout: analysis-message
---

This message occurs when you have a namespace that is missing the
[annotation](/docs/reference/config/annotations/) to indicate whether the
namespace is auto-injected, for example `sidecar.istio.io/inject`.

To resolve this problem, always use an annotation to explicitly declare whether
or not you want the namespace to be auto-injected. We strongly recommend
explicitly defining desired injection behavior. Forgetting to annotate a
namespace is a common cause of errors.

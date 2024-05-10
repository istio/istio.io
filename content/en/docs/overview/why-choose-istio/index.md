---
title: Why choose Istio?
description: Compare Istio to other service mesh solutions.
weight: 20
keywords: [comparison]
owner: istio/wg-docs-maintainers-english
test: n/a
---

## Service mesh or CNI?

Today, some CNI plugins are starting to offer non-CNI service mesh functionality as an add-on that sits on top of their own CNI implementation. For example, they may implement their own encryption schemes for traffic between nodes and/or pods, workload identity, or support some amount of transport-level policy by redirecting traffic to a L7 proxy. These service mesh addons are non-standard, and as such can only work on top of the CNI that ships them.  They also offer varying feature sets.

Istio is designed to be a service mesh that provides a consistent, highly secure, efficient, and standards-compliant service mesh implementation using a powerful set of L7 policies, platform-agnostic workload identity, using industry-proven mTLS protocols - in any environment, with any CNI, or even across clusters with different CNIs.

For this reason, Istio has implemented its zero-trust tunnel (ztunnel) component, which transparently and efficiently provides this functionality using proven, industry-standard encryption protocols. Learn more about ztunnel.

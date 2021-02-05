---
title: DeprecatedAnnotation
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when an Istio or Kubernetes resource has an Istio annotation that
has been deprecated by the Istio team.

## How to resolve

It is likely the annotation will stop taking affect when the Istio control plane is upgraded.
Before upgrading, remove or replace this annotation with a supported replacement.

Consult the [Istio annotation documentation](/docs/reference/config/annotations/) for a list of Istio annotations.

The Istio release announcements may include advice or suggested replacements for deprecated
Istio annotations.

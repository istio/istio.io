---
title: MisplacedAnnotation
layout: analysis-message
---

This message occurs when an Istio {{< gloss >}}annotation{{< /gloss >}} is attached to an invalid resource,
or to a resource in the wrong location.

For example, this could occur if you create a deployment and attach the
annotation to the deployment instead of attaching the annotation to the pods it
creates.

To resolve this problem, verify that your annotations are correctly placed and
try again.

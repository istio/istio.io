---
title: MisplacedAnnotation
layout: analysis-message
---

This message occurs when an Istio annotation is attached to an invalid resource,
or to a resource in the wrong location.

{{< tip >}}
Annotation refers to a Kubernetes annotation attached to a pod. For
a list of valid Istio annotations, see
[Resource Annotations](/docs/reference/config/annotations/).
{{< /tip >}}

For example, this could occur if you create a deployment and attach the
annotation to the deployment instead of attaching the annotation to the pods it
creates.

To resolve this problem, verify that your annotations are correctly placed and
try again.

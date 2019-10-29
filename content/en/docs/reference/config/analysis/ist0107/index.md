---
title: MisplacedAnnotation
layout: analysis-message
---

This message occurs when you create a deployment that contains pods without the required annotation attached to them.

{{< tip >}}
Annotation refers to a Kubernetes annotation attached to a pod. For a list of valid annotations, see
[Resource Annotations](/docs/reference/config/annotations/).
{{< /tip >}}

For example, you create a deployment and attach the annotation to the deployment instead of attaching the annotation to the pods it creates.

To resolve this problem, attach the required annotation to each pod and try again.

---
title: SchemaWarning
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a resource passes schema validation, but the validation returns a warning.
A warning does not block the configuration. It tells you that the configuration uses a deprecated
setting, or that it might not do what you expect.

## An example

Consider a `VirtualService` that uses the deprecated `mirrorPercent` field:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
    mirror:
      host: reviews-mirror
    mirrorPercent: 50
{{< /text >}}

You will receive this message:

{{< text plain >}}
Warning [IST0133] (VirtualService default/reviews) Schema validation warning: using deprecated setting "mirrorPercent", use "mirrorPercentage" instead
{{< /text >}}

## How to resolve

Read the text of the warning and update the resource. In the example above, replace
`mirrorPercent` with `mirrorPercentage`.

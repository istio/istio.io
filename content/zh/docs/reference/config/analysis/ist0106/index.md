---
title: SchemaValidationError
layout: analysis-message
---

This message occurs when your Istio configuration does not successfully pass
schema validation.

For example, you receive this error:

{{< text plain >}}
Error [IST0106] (VirtualService ratings-bogus-weight-default.default) Schema validation error: percentage 888 is not in range 0..100
{{< /text >}}

and your Istio configuration contains these values:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-bogus-weight-default
  namespace: default
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
      weight: 999
    - destination:
        host: ratings
        subset: v2
      weight: 888
{{< /text >}}

In this example, the error message indicates that the `weight` element has an
invalid value when checked against the schema.

To resolve this problem, refer to the
[message details](/zh/docs/reference/config/analysis/message-format/) field to determine
which element or value does not adhere to the schema, correct the error and try
again.

For details about the expected schema for Istio resources, see the
[configuration reference](/zh/docs/reference/config/).

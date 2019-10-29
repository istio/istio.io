---
title: SchemaValidationError
layout: analysis-message
---

This message occurs when your Configuration Resource Definition (CRD) file does
not successfully pass schema validation.

For example, you receieve this error:
`Error [IST0106] (VirtualService ratings-bogus-weight-default.default) Schema validation error: percentage 888 is not in range 0..100`

and your CRD contains these values:

{{< text bash >}}
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

The error message indicates that the `weight` element has an invalid value when
checked against the schema.

To resolve this problem, refer to the detailed error message to determine which
element or value does not adhere to the schema, correct the error and try again.

For more a reference to valid keys and values, see the
[schema for HTTPRouteDestination](/docs/reference/config/networking/v1alpha3/virtual-service/#HTTPRouteDestination).

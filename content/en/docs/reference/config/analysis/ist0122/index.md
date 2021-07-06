---
title: InvalidRegexp
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when an Istio resource contains an invalid regular expression.

Istio regular expressions use the [RE2](https://github.com/google/re2/wiki/Syntax)
regular expression syntax.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0122] (VirtualService bad-match.default) Field "uri" regular expression invalid: "[A-Z" (error parsing regexp: missing closing ]: `[A-Z`)
{{< /text >}}

when your cluster has following virtual service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bad-match
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        regex: "[A-Z"
    route:
    - destination:
        host: productpage
{{< /text >}}

In this example, the regex `[A-Z` does not follow the RE2 syntax.

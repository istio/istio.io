---
title: NoMatchingWorkloadsFound
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when an authorization policy's selector does not match any pods.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0127] (AuthorizationPolicy httpbin-nopods.httpbin) No matching workloads for this resource with the following labels: app=bogus-label,version=v1
{{< /text >}}

when your cluster has the following authorization policy:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-nopods
  namespace: httpbin
spec:
  selector:
    matchLabels:
      app: bogus-label # Bogus label. No matching workloads
      version: v1
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/default/sa/sleep"]
        - source:
            namespaces: ["httpbin"]
      to:
        - operation:
            methods: ["GET"]
            paths: ["/info*"]
        - operation:
            methods: ["POST"]
            paths: ["/data"]
      when:
        - key: request.auth.claims[iss]
          values: ["https://accounts.google.com"]
{{< /text >}}

In this example, the authorization policy `httpbin-nopods` selects
pods with the label `app=bogus-label`, and none exist.

## How to resolve

- Change the selector to match the pods you have
- Label pods to match the selector

---
title: InvalidAnnotation
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when an `annotation` mentions `istio.io` but the annotation

- isn't an annotation known to this version of Istio
- is known, but has a disallowed value, such as a string where a number is needed
- is applied to the wrong kind of resource, such as a pod-specific resource applied to a service

Consult [Istio's list of resource annotations](/docs/reference/config/annotations/).

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0108] (Service httpbin.default) Unknown annotation: networking.istio.io/exportTwo
{{< /text >}}

when your cluster has following namespace:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
  annotations:
    # no such Istio annotation
    networking.istio.io/exportTwo: bar
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
{{< /text >}}

In this example, the service `httpbin` is using `networking.istio.io/exportTwo` instead of `networking.istio.io/exportTo`.

## How to resolve

- Delete or rename unknown annotations
- Change annotations with disallowed values

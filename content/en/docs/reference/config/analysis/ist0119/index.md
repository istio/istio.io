---
title: JwtFailureDueToInvalidServicePortPrefix
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when a authentication Policy specifies the use of JWT authentication, but
the targeted [Kubernetes services](https://kubernetes.io/docs/concepts/services-networking/service/) is not configured
properly. A properly targeted Kubernetes service requires the port to be named with a prefix of http|http2|https
(see [Protocol Selection](/docs/ops/configuration/traffic-management/protocol-selection/)) and also requires the
protocol to be TCP; an empty protocol is acceptable as TCP is the default value.

## Example

You will receive this message:

{{< text plain >}}
Warn [IST0119] (Policy secure-httpbin.default) Authentication policy with JWT targets Service with invalid port specification (port: 8080, name: svc-8080, protocol: TCP, targetPort: 80).
{{< /text >}}

when your cluster has following policy:

{{< text yaml >}}
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: secure-httpbin
  namespace: default
spec:
  targets:
    - name: httpbin
  origins:
    - jwt:
        issuer: "testing@secure.istio.io"
        jwksUri: "https://raw.githubusercontent.com/istio/istio-1.4/security/tools/jwt/samples/jwks.json"
{{< /text >}}

that targets the following service:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: default
  labels:
    app: httpbin
spec:
  ports:
  - name: svc-8080
    port: 8080
    targetPort: 80
    protocol: TCP
  selector:
    app: httpbin
{{< /text >}}

In this example, the port `svc-8080` does follow the syntax: `name: <http|https|http2>[-<suffix>]`.

## How to resolve

- JWT authentication is only supported over http, https or http2. Rename the Service port name to conform with `<http|https|http2>[-<suffix>]`

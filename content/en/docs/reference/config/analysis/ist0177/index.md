---
title: ConflictingServiceEntryProtocol
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when two or more `ServiceEntry` resources that are visible in the same namespace
define the same host and port, but use different protocols.

Istio can use only one protocol for a host and port. Thus, traffic can use a protocol that you do not
expect.

## An example

Consider these two `ServiceEntry` resources:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: api-http
spec:
  hosts:
  - api.example.com
  ports:
  - number: 443
    name: http
    protocol: HTTP
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: api-tls
spec:
  hosts:
  - api.example.com
  ports:
  - number: 443
    name: tls
    protocol: TLS
  resolution: DNS
{{< /text >}}

You will receive this message for each `ServiceEntry`:

{{< text plain >}}
Warning [IST0177] (ServiceEntry default/api-http) Multiple ServiceEntries (default/api-http, default/api-tls) define the same host "api.example.com" and port 443 with conflicting protocols (HTTP, TLS).
{{< /text >}}

## How to resolve

Use the same protocol for the port in all `ServiceEntry` resources, or put the host in one
`ServiceEntry`.

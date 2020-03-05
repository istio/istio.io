---
title: How can I check whether mutual TLS is enabled for a service?
weight: 11
---

The [`istioctl`](/docs/reference/commands/istioctl) command provides an option for this purpose. You can do:

{{< text bash >}}
$ istioctl authn tls-check $CLIENT_POD httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS     SERVER     CLIENT           AUTHN POLICY     DESTINATION RULE
httpbin.default.svc.cluster.local:8000     OK         STRICT     ISTIO_MUTUAL     /default         istio-system/default
{{< /text >}}

Where `$CLIENT_POD` is the ID of one of the client service's pods.

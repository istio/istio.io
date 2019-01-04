---
title: How can I check whether mutual TLS is enabled for a service?
weight: 11
---

The `istioctl` tool provides an option for this purpose. You can do:

{{< text bash >}}
$ istioctl authn tls-check httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS     SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8000     OK         mTLS       mTLS       default/            default/default
{{< /text >}}

Refer to [Verify mutual TLS configuration](/docs/tasks/security/mutual-tls/#verify-mutual-tls-configuration) for more information.

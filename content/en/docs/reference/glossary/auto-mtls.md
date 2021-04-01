---
title: Auto mTLS
test: n/a
---

Auto mTLS is a feature of Istio to automatically configure client side proxies to send
[mutual TLS traffic](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls)
on connections where both the client and server are able to handle Mutual TLS traffic.
Istio downgrades to plaintext when either the client or server is not able to handle such traffic.

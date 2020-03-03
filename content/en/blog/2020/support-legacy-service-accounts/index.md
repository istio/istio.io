---
title: Support Added for Legacy Kubernetes Service Accounts
description: Istio 1.5 adds support for legacy Kubernetes service accounts.
publishdate: 2020-02-29
attribution: Lei Tang (Google)
keywords: [security, Kubernetes, service accounts, JWT]
target_release: 1.5
---

Istio uses Kubernetes service accounts (JSON Web Tokens (JWTs))
for authentication purposes. Istio 1.4 only supports
Kubernetes service accounts with the newer format, for example
those containing the `audience` and the `expiration time` fields.

Istio 1.5 adds support for legacy Kubernetes service accounts to
ensure that platforms without the new Kubernetes service accounts
(e.g., Kubernetes with versions < 1.13) can use Istio.

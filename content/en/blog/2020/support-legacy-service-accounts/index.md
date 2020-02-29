---
title: Support legacy Kubernetes service accounts
description: Support legacy Kubernetes service accounts.
publishdate: 2020-02-29
attribution: Lei Tang (Google)
keywords: [security, Kubernetes, service accounts, JWT]
target_release: 1.5
---

Kubernetes service accounts (JSON Web Tokens (JWTs)) are used in Istio
for authentication purposes.  Istio 1.4 only supports Kubernetes service
accounts with the newer format that contains the fields such as the audience
and the expiration time.

Istio 1.5 adds the support of legacy Kubernetes service accounts so
the platforms not having the newer Kubernetes service accounts
(e.g., Kubernetes with versions < 1.13)) can use Istio with
legacy Kubernetes service accounts.

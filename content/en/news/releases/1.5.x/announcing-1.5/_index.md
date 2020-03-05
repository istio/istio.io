---
title: Announcing Istio 1.5
linktitle: 1.5
subtitle: Major Update
description: Istio 1.5 release announcement.
publishdate: 2020-o2-11
release: 1.5.0
skip_list: true
aliases:
    - /news/announcing-1.5.0
    - /news/announcing-1.5
---

We are pleased to announce the release of Istio 1.5!

{{< relnote >}}

## Support added for legacy Kubernetes service accounts

Istio uses Kubernetes service accounts (JSON Web Tokens (JWTs))
for authentication purposes. Istio 1.4 only supports
Kubernetes service accounts with the newer format, for example
those containing the `audience` and the `expiration time` fields.

Istio 1.5 adds support for legacy Kubernetes service accounts to
ensure that platforms without the new Kubernetes service accounts
(e.g., Kubernetes with versions < 1.13) can use Istio.
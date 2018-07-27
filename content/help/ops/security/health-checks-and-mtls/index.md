---
title: Health Checks and Mutual TLS
description: How to get health checks working when mutual TLS is enabled.
weight: 40
---
As of Istio 1.0, we support a ‘permissive’ mode so that your service can take both mTLS and plaintext traffic.
To configure your service to accept both mTLS and plaintext traffic for health checking, please refer to the
[permissive mode configuration](/docs/tasks/security/mtls-migration/#configure-the-server-to-accept-both-mtls-and-plain-text-traffic).

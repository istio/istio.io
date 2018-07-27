---
title: Health Checks and Mutual TLS
description: How to get health checks working when mutual TLS is enabled.
weight: 40
---
As of Istio 1.0, you can enable a PERMISSIVE mode for your service to take both mutual TLS and plain-text traffic.
To configure your service to accept both mTLS and plain-text traffic for health checking, please refer to the
[PERMISSIVE mode configuration documentation](/docs/tasks/security/mtls-migration/#configure-the-server-to-accept-both-mtls-and-plain-text-traffic).

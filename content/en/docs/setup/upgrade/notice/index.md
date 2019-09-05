---
title: 1.3 Upgrade Notice
description: Important changes operators must understand before upgrading to Istio 1.3.
weight: 5
aliases:
    - /docs/setup/kubernetes/upgrade/notice/
---

This page describes changes you need to be aware of when upgrading from Istio 1.2 to 1.3. Here, we
detail cases where we intentionally broke backwards compatibility.

For an overview of new features introduced with Istio 1.3, please refer to the [1.3 release notes](/about/notes/1.3/).

## Trust Domain Validation

The server proxy will validate the trust domain of the client proxy and only accept the request if the
client proxy is in the same trust domain as the server proxy when:

  *  STRICT mutual TLS mode is used in Authentication Policy
  *  PERMISSIVE mutual TLS mode is used in Authentication Policy and the client proxy is sending mutual TLS traffic

In other words, the server proxy will reject the traffic if it's from a different trust domain when
mutual TLS is enabled in the mesh. This should be a no-op if you only have one trust domain in your mesh.

To opt-out the trust domain validation, render the helm template with `--set pilot.env.PILOT_SKIP_VALIDATE_TRUST_DOMAIN=true`
before upgrading to 1.3.

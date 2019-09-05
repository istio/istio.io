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

When mutual TLS is enabled on a proxy using authentication policy, the proxy will reject a request
from client if the trust domain extracted from the client certificate is not the same to the trust
domain extracted from the proxy's own certificate. This is called trust domain validation which is
new in Istio 1.3.

This should be a no-op if you only have one trust domain or if you are not using mutual TLS from
authentication policy.

To opt-out the trust domain validation, render the helm template with `--set pilot.env.PILOT_SKIP_VALIDATE_TRUST_DOMAIN=true`
before upgrading to 1.3.

For more information, see [issue 15631](https://github.com/istio/istio/issues/15631).

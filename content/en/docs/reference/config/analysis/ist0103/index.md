---
title: PodMissingProxy
layout: analysis-message
---

This message occurs when the sidecar is not present or does not contain a configuration element that Istio expects.

For example, when you enable auto-injection but do not restart your pods afterwards, causing the sidecar to be missing.

To resolve this problem, restart your pods and try again.

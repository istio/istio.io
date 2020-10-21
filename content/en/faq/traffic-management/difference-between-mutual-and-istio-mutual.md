---
title: What is the difference between MUTUAL and ISTIO_MUTUAL TLS modes?
weight: 30
---

Both of these `DestinationRule` settings will send mutual TLS traffic.
However, with `ISTIO_MUTUAL`, Istio certificates will automatically be used.
For `MUTUAL`, the key, certificate, and trusted CA must be configured.
This allows initiating mutual TLS with non-Istio applications.

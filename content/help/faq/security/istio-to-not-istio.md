---
title: Can Istio mutual TLS enabled services communicate with services without Istio?
weight: 20
---
Starting with Istio 0.8, a service with Istio mutual TLS enabled can talk to a service without Istio. Mutual TLS is enabled via [authentication policy](/docs/concepts/security/authn-policy/) and this only specifies the service behavior as a server, not client, which means a mutual TLS enabled service will still send http traffic (not mutual TLS) to others unless you explicitly specify it with [destination rule](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule).

However, unless a service without Istio can present a valid certificate, which is less likely to happen, a service without Istio cannot talk to a service with Istio mutual TLS enabled and this is the expected behavior of 'mutual TLS'.

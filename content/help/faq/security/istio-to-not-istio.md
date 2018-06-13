---
title: Can a service with Istio mutual TLS (mTLS) enabled talk to a service without Istio,
and what about the other way around?
weight: 20
---
Starting from 0.8 release, a service with Istio mTLS enabled can talk to a service without Istio. Mutual TLS is enabled via [authentication policy]({{home}}/docs/concepts/security/authn-policy.html) and this only specifies the service behavior as a server, not client, which means a mTLS enabled service will still send http traffic (not mTLS) to others unless you explicitly specify it with [destination rule]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#DestinationRule).

However, unless a service without Istio can present a valid cert, which is less likely to happen, a service without Istio cannot talk to a service with Istio mTLS enabled and this is the expected behavior of 'mTLS'.

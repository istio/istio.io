---
title: If mutual TLS is globally enable, can Istio services communicate with non-Istio services?
weight: 20
---
> Istio services are services that have Envoy sidecar.

If non-Istio services are on receiving end, you can selectively set the
[destination rule](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule) to disable (mutual) TLS on the outbound traffic to those services.
See [authentication policy](/docs/tasks/security/authn-policy/#request-from-istio-services-to-non-istio-services) for more details.

On the other hand, non-Istio services cannot talk to Istio services unless they can present a valid certificate, which is less likely to happen.
This is the expected behavior of *mutual TLS*.

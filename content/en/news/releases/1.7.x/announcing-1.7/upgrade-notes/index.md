---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.7.
weight: 20
---

When you upgrade from Istio 1.6.x to Istio 1.7.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.6.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.6.x.

## Require Kubernetes 1.16+

Kubernetes 1.16+ is now required for installation.

## Installation

- `istioctl manifest apply` is removed, please use `istioctl install` instead.
- Installation of telemetry addons by istioctl is deprecated, please use these [addons integration instructions](/docs/ops/integrations/).

## Gateways run as non-root

Gateways will now run without root permissions by default. As a result, they will no longer be able to bind to ports below 1024.
By default, we will bind to valid ports. However, if you are explicitly declaring ports on the gateway, you may need to modify your installation. For example, if you previously had the following configuration:

{{< text yaml >}}
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          ports:
            - port: 15021
              targetPort: 15021
              name: status-port
            - port: 80
              name: http2
            - port: 443
              name: https
{{< /text >}}

It should be changed to specify a valid `targetPort` that can be bound to:

{{< text yaml >}}
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          ports:
            - port: 15021
              targetPort: 15021
              name: status-port
            - port: 80
              name: http2
              targetPort: 8080
            - port: 443
              name: https
              targetPort: 8443
{{< /text >}}

Note: the `targetPort` only modifies which port the gateway binds to. Clients will still connect to the port defined by `port` (generally 80 and 443), so this change should be transparent.

If you need to run as root, this option can be enabled with `--set values.gateways.istio-ingressgateway.runAsRoot=true`.

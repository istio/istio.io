---
title: Configure an Egress Gateway with mutual TLS
description: Describes how to configure an Egress Gateway to perform mutual TLS to external services
weight: 45
keywords: [traffic-management,egress]
---

The [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example describes how to configure
Istio to direct the egress traffic through a dedicated service called _Egress Gateway_. This examples shows how to
configure an Egress Gateway to perform mutual TLS to external services.

## Before you begin

This examples assumes you deployed Istio with [mutual TLS Authentication](/docs/tasks/security/mutual-tls/)
enabled. Follow the steps in the [Before you begin](/docs/examples/advanced-egress/egress-gateway/#before-you-begin)
section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.

## Generate client and server certificates and keys

Generate the certificates and keys as described in the [Securing Gateways with HTTPS](docs/tasks/traffic-management/secure-ingress/#generate-client-and-server-certificates-and-keys).

## Cleanup

Perform the instructions in the [Cleanup](/docs/examples/advanced-egress/egress-gateway/#cleanup)
section of the [Configure an Egress Gateway](/docs/examples/advanced-egress/egress-gateway) example.

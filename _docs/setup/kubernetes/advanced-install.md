---
title: Advanced Install Options
overview: Instructions for customizing the Istio installation.

order: 20
draft: true
layout: docs
type: markdown
---

{% include home.html %}

This section provides options for piecemeal installation of Istio
components.

## Ingress Controller Only

It is possible to use Istio as an Ingress controller, leveraging advanced
L7 routing capabilities such as version-aware routing, header based
routing, gRPC/HTTP2 proxying, tracing, etc. Deploy Istio Pilot only and
disable other components. Do not deploy the Istio initializer.


## Ingress Controller with Telemetry & Policies

By deploying Istio Pilot and Mixer, the Ingress controller configuration
described above can be enhanced to provide in-depth telemetry and policy
enforcement capabilities such as rate limits, access controls, etc.

## Intelligent Routing & Telemetry

If you wish to take advantage of Istio's L7 traffic management
capabilities, in addition to obtaining in-depth telemetry and performing
distributed request tracing, deploy Istio Pilot and Mixer. In addition,
disable policy enforcement at the Mixer.

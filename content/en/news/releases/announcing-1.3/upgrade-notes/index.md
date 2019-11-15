---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.3.
weight: 20
aliases:
    - /docs/setup/kubernetes/upgrade/notice/
    - /docs/setup/upgrade/notice
---

This page describes changes you need to be aware of when upgrading from
Istio 1.2 to 1.3.  Here, we detail cases where we intentionally broke backwards
compatibility.  We also mention cases where backwards compatibility was
preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.2.

## Installation and upgrade

We simplified the configuration model for Mixer and removed support for
adapter-specific and template-specific Custom Resource Definitions (CRDs)
entirely in 1.3. Please move to the new configuration model.

We removed the Mixer CRDs from the system to simplify the configuration
model, improve Mixer's performance in Kubernetes deployments, and improve
reliability in various Kubernetes environments.

## Traffic management

Istio now captures all ports by default. If you don't specify container ports
to intentionally bypass Envoy, you must opt out of port capturing with the
`traffic.sidecar.istio.io/excludeInboundPorts` option.

Protocol sniffing is now enabled by default. Disable protocol sniffing with the
`--set pilot.enableProtocolSniffing=false` option when you upgrade to get the
previous behavior. To learn more see our [protocol selection page](/docs/ops/traffic-management/protocol-selection/).

To specify a hostname in multiple namespaces, you must select a single host using
a [`Sidecar` resource](/docs/reference/config/networking/sidecar/).

## Trust domain validation

Trust domain validation is new in Istio 1.3. If you only have one trust domain
or you don't enable mutual TLS through authentication policies, there is nothing
you must do.

To opt-out the trust domain validation, include the following flag in your Helm
template before upgrading to Istio 1.3:
`--set pilot.env.PILOT_SKIP_VALIDATE_TRUST_DOMAIN=true`

## Secret discovery service

In Istio 1.3, we are taking advantage of improvements in Kubernetes to issue
certificates for workload instances more securely.

Kubernetes 1.12 introduces `trustworthy` JWTs to solve these issues.
[Kubernetes 1.13](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.13.md)
introduced the ability to change the value of the `aud` field to a value other
than the API server. The `aud` field represents the audience in Kubernetes. To
better secure the mesh, Istio 1.3 only supports `trustworthy` JWTs and requires
the audience, the value of the `aud` field, to be `istio-ca` when you enable
SDS.

Before upgrading to Istio 1.3 with SDS enabled, see our blog post on
[trustworthy JWTs and SDS](/blog/2019/trustworthy-jwt-sds/).

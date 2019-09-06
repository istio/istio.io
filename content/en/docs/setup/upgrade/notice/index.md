---
title: 1.3 Upgrade Notice
description: Important changes to consider when upgrading to Istio 1.3.
weight: 5
aliases:
    - /docs/setup/kubernetes/upgrade/notice/
---

This page describes changes you need to be aware of when upgrading from
Istio 1.2 to 1.3.  Here, we detail cases where we intentionally broke backwards
compatibility.  We also mention cases where backwards compatibility was
preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.2.

For an overview of new features introduced with Istio 1.2, please refer
to the [1.3 release notes](/about/notes/1.3/).

## Installation and Upgrade

We simplified the configuration model for Mixer and removed support for
adapter-specific and template-specific Custom Resource Definitions (CRDs)
entirely in 1.3. Please move to the new configuration model.

We removed the Mixer CRDs from the system to simplify the configuration
model, improve Mixer's performance in Kubernetes deployments, and improve
reliability in various Kubernetes environments.

## Secret Service Discovery

In Istio 1.3, we are taking advantage of improvements in Kubernetes to issue
certificates for workload instances more securely.

Kubernetes 1.12 introduces `trustworthy` JWTs to solve these issues. However,
support for the `aud` field to have a different value than the API server
audience didn't become available until [Kubernetes 1.13](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.13.md).
To better secure the mesh, Istio 1.3 only supports `trustworthy` JWTs and
requires the value of the `aud` field to be `istio-ca` when you enable SDS.

Before upgrading your Istio deployment to 1.3 with SDS enabled, verify that you
use Kubernetes 1.13 or later.

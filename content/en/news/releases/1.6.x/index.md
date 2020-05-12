---
title: Upgrade Notes
description: Important Changes to consider when upgrading to Istio 1.6.
weight: 20
---

This page describes changes you need to be aware of when upgrading from Istio
1.5.x to Istio 1.6.x. Here, we detail cases where we intentionally broke backwards
compatibility. We also mention cases where backwards compatibility was preserved
but new behavior was introduced that would be surprising to someone familiar with
the use and operation of Istio 1.5.

# Removal of Helm Installation
In Istio 1.6, the legacy Helm installer has been removed. Please use either the
[istioctl]() installation method or the [operator]() installation method.


#TODO: Looking at the 1.5 docs, there were several feature gaps between telemetry v2 and mixer. Do these still exist?

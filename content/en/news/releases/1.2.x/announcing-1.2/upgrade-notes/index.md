---
title: Upgrade Notes
description: Important changes operators must understand before upgrading to Istio 1.2.
publishdate: 2019-06-18
release: 1.2
subtitle: Minor Release
linktitle: 1.2
weight: 20
---

This page describes changes you need to be aware of when upgrading from
Istio 1.1.x to 1.2.x.  Here, we detail cases where we intentionally broke backwards
compatibility.  We also mention cases where backwards compatibility was
preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.1.

## Installation and upgrade

{{< tip >}}
The configuration model for Mixer has been simplified. Support for
adapter-specific and template-specific Custom Resources has been
removed by default in 1.2 and will be removed entirely in 1.3.
Please move to the new configuration model.
{{< /tip >}}

Most Mixer CRDs were removed from the system to simplify the configuration
model, improve performance of Mixer when used with Kubernetes, and improve
reliability in a variety of Kubernetes environments.

The following CRDs remain:

| Custom Resource Definition name | Purpose |
| --- | --- |
| `adapter` | Specification of Istio extension declarations |
| `attributemanifest` | Specification of Istio extension declarations |
| `template` | Specification of Istio extension declarations |
| `handler` | Specification of extension invocations |
| `rule` | Specification of extension invocations |
| `instance` | Specification of extension invocations |

In the event you are using the removed mixer configuration schemas, set
the following Helm flags during upgrade of the main Helm chart:
`--set mixer.templates.useTemplateCRDs=true --set mixer.adapters.useAdapterCRDs=true`

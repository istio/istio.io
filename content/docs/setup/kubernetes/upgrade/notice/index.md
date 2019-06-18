---
title: 1.2 Upgrade Notice
description: Important changes operators must understand before upgrading to Istio 1.2.
weight: 5
---

This page describes changes you need to be aware of when upgrading from
Istio 1.1 to 1.2.  Here we detail cases where we intentionally broke backwards
compatibility.  We also mention cases where backwards compatibility was
preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.1.

For an overview of new features introduced with Istio 1.2, please refer to the [1.2 release notes](/about/notes/1.2/).

## Installation and Upgrade

{{< tip >}}
The vast array of Mixer plugins were deprecated in Istio 1.1.  Please move
to the new configuration model quickly, as the old configuration model has
been removed in Istio 1.2.0.
{{< /tip >}}

Most Mixer CRDs were removed from the system to simplify the configuration
model, improve performance of Mixer when used with Kubernetes, and improve
reliability in a variety of Kubernetes environments.

The following CRDs remain:

| Custom Resource Definition name | Purpose |
| --- | --- |
| `adapter`| Specification of Istio extension declarations |
| `attributemanifest` | Specification of Istio extension declarations |
| `template` | Specification of Istio extension declarations |
| `handler` | Specification of extension invocations |
| `rule` | Specification of extension invocations |
| `instance` | Specification of extension invocations |

In the event you are using the removed mixer configuration schemas, set
the following Helm flags during upgrade of the main Helm chart:

    `--set mixer.templates.useTemplateCRDs=true --set mixer.adapters.useAdapterCRDs=true`

## Security

{{< tip >}}
Istio 1.0's `RbacConfig` was deprecated in Istio 1.1.  It has been replaced
with a new custom resource `ClusterRbacConfig` in Istio 1.2.0.
{{< /tip >}}

- In Istio 1.2 the `RbacConfig` custom resource is replaced by the `ClusterRbacConfig`
  custom resource. Refer to [Migrating `RbacConfig` to `ClusterRbacConfig`](/docs/setup/kubernetes/upgrade/steps/#migrating-from-rbacconfig-to-clusterrbacconfig)
  for migration instructions if you're currently using `RbacConfig`.

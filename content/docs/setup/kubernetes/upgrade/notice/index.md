---
title: 1.2 Upgrade Notice
description: Important changes operators must understand before upgrading to Istio 1.2.
weight: 5
---

This page describes changes you need to be aware of when upgrading from Istio 1.1 to 1.2.  Here we detail
cases where we intentionally broke backwards compatibility.  We also mention cases where backwards
compatibility was preserved but new behavior was introduced that would be surprising to someone
familiar with the use and operation of Istio 1.1.

For an overview of new features introduced with Istio 1.2, please refer to the [1.2 release notes](/about/notes/1.2/).

## Installation

- Most mixer CRDs were removed from the system to consolidate the CRD definitions in one data model.
  In the event you are using a mixer plugin that has not transitioned to the new mixer data model,
  set the following Helm flags during upgrade of the main Helm chart.

    `--set mixer.templates.useTemplateCRDs=true --set mixer.adapters.useAdapterCRDs=true`

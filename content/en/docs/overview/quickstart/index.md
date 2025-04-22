---
title: "Quickstart"
description: Learn how to get started with a simple example installation.
weight: 50
keywords: [introduction]
owner: istio/wg-docs-maintainers-english
skip_seealso: true
test: n/a
---

Thanks for your interest in Istio!

Istio has two primary modes: **sidecar mode** and **ambient mode**.

* [Sidecar mode](/docs/overview/dataplane-modes/#sidecar-mode) is the traditional model of service mesh pioneered by Istio in 2017. In sidecar mode, a proxy is deployed along with every Kubernetes pod or other workload.
* [Ambient mode](/docs/overview/dataplane-modes/#ambient-mode) is the new and improved model, created to address the shortcomings of sidecar mode. In ambient mode, a secure tunnel is installed on each node, and you can opt in to the full feature set with proxies you install, (generally) per-namespace.

Most of the energy in the Istio community is going towards improvement of ambient mode, although sidecar mode remains fully supported. Any major new feature contributed to the project is expected to work in both modes.

In general, **we recommend that new users start with ambient mode**. It is faster, cheaper, and easier to manage. There are [advanced use cases](/docs/overview/dataplane-modes/#unsupported-features) that still require the use of sidecar mode, but closing these gaps is on our 2025 roadmap.

<div style="display: flex; justify-content: center; align-items: center; gap: 1rem;">
<a href="/docs/ambient/getting-started" class="btn btn--secondary" id="get-started-ambient">Get started with ambient mode</a><a href="/docs/setup/getting-started" class="btn btn--secondary" id="get-started-sidecar">Get started with sidecar mode</a>
</div>

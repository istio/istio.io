---
title: Kiali
description: Information on how to integrate with Kiali.
weight: 29
keywords: [integration,kiali]
test: no
---

[Kiali](https://kiali.io/) is an observability console for Istio with service mesh configuration and validation capabilities.
It helps you understand the structure and health of your service mesh by monitoring traffic flow to infer the topology and report errors.
Kiali provides detailed metrics and a basic [Grafana](/docs/ops/integrations/grafana) integration, which can be used for advanced queries.
Distributed tracing is provided by integration with [Jaeger](/docs/ops/integrations/jaeger).

## Configuration

### Option 1: Quick start

Istio provides a basic sample installation to quickly get Kiali up and running:

{{< text bash >}}
$ kubectl apply {{< github_tree >}}/samples/addons/kiali.yaml -n istio-system
{{< /text >}}

This will deploy Kiali into your cluster.

### Option 2: Customizable install

The Kiali project offers its own [customizable installation methods](https://kiali.io/documentation/latest/getting-started). We recommend production users follow these instructions to ensure they stay up to date with the latest versions and best practices.

## Usage

For more information about using Kiali, see the [Visualizing Your Mesh](/docs/tasks/observability/kiali/) task.

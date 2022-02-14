---
title: Kiali
description: Information on how to integrate with Kiali.
weight: 29
keywords: [integration,kiali]
owner: istio/wg-environments-maintainers
test: no
---

[Kiali](https://kiali.io/) is an observability console for Istio with service mesh configuration and validation capabilities.
It helps you understand the structure and health of your service mesh by monitoring traffic flow to infer the topology and report errors.
Kiali provides detailed metrics and a basic [Grafana](/docs/ops/integrations/grafana) integration, which can be used for advanced queries.
Distributed tracing is provided by integration with [Jaeger](/docs/ops/integrations/jaeger).

## Installation

### Option 1: Quick start

Istio provides a basic sample installation to quickly get Kiali up and running:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/kiali.yaml
{{< /text >}}

This will deploy Kiali into your cluster. This is intended for demonstration only, and is not tuned for performance or security.

{{< idea >}}
If you use this sample YAML and plan to publicly expose the resulting Kiali
installation, be sure to change the `signing_key` in Kiali's ConfigMap when using an
authentication strategy other than `anonymous`.
{{< /idea >}}

### Option 2: Customizable install

The Kiali project offers its own [quick start guide](https://kiali.io/docs/installation/quick-start) and [customizable installation methods](https://kiali.io/docs/installation/installation-guide). We recommend production users follow those instructions to ensure they stay up to date with the latest versions and best practices.

## Usage

For more information about using Kiali, see the [Visualizing Your Mesh](/docs/tasks/observability/kiali/) task.

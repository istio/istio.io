---
title: Jaeger
description: How to integrate with Jaeger.
weight: 28
keywords: [integration,jaeger,tracing]
owner: istio/wg-environments-maintainers
test: n/a
---

[Jaeger](https://www.jaegertracing.io/) is an open source end to end distributed tracing system,
allowing users to monitor and troubleshoot transactions in complex distributed systems.

## Installation

### Option 1: Quick start

Istio provides a basic sample installation to quickly get Jaeger up and running:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/jaeger.yaml
{{< /text >}}

This will deploy Jaeger into your cluster. This is intended for demonstration only,
and is not tuned for performance or security.

### Option 2: Customizable install

Consult the [Jaeger documentation](https://www.jaegertracing.io/) to get started.
No special changes are needed for Jaeger to work with Istio.

## Usage

For information on using Jaeger, please refer to the
[Jaeger task](/es/docs/tasks/observability/distributed-tracing/jaeger/).

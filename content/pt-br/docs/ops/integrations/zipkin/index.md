---
title: Zipkin
description: How to integrate with Zipkin.
weight: 32
keywords: [integration,zipkin,tracing]
owner: istio/wg-environments-maintainers
test: n/a
---

[Zipkin](https://zipkin.io/) is a distributed tracing system. It helps gather timing data needed to troubleshoot latency problems in service architectures. Features include both the collection and lookup of this data.

## Installation

### Option 1: Quick start

Istio provides a basic sample installation to quickly get Zipkin up and running:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/extras/zipkin.yaml
{{< /text >}}

This will deploy Zipkin into your cluster. This is intended for demonstration only, and is not tuned for performance or security.

### Option 2: Customizable install

Consult the [Zipkin documentation](https://zipkin.io/) to get started. No special changes are needed for Zipkin to work with Istio.

## Usage

For information on using Zipkin, please refer to the [Zipkin task](/docs/tasks/observability/distributed-tracing/zipkin/).

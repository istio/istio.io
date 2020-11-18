---
title: NamespaceMultipleInjectionLabels
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when a namespace specifies Istio sidecar auto-injection
using **both** the new and legacy style labels.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0123] (Namespace busted) The namespace has both new and legacy injection labels. Run 'kubectl label namespace busted istio.io/rev-' or 'kubectl label namespace busted istio-injection-'
{{< /text >}}

when your cluster has following namespace:

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: busted
  labels:
    istio-injection: enabled
    istio.io/rev: canary
{{< /text >}}

In this example, the namespace `busted` uses both old-style and new-style injection labels.

## How to resolve

- Remove the `istio-injection` label
- Remove the `istio.io/rev` label

---
title: ImageAutoWithoutInjectionError
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a `Pod` has an `istio-proxy` container with `image: auto`.

The `auto` image is a placeholder. The sidecar injector replaces it with the correct image when it
creates the pod. If a pod still has `image: auto`, injection did not occur. The pod cannot pull the
image `auto` and cannot start.

## An example

You will receive a message like this:

{{< text plain >}}
Error [IST0147] (Pod default/istio-ingressgateway-5bdb6f9c8b-xk2vz) Pod istio-ingressgateway-5bdb6f9c8b-xk2vz contains `image: auto` but does not match any Istio injection webhook selectors.
{{< /text >}}

## How to resolve

1. Enable injection for the pod. For example, add the `istio-injection=enabled` label to the
   namespace, or add the `sidecar.istio.io/inject: "true"` label to the pod. If you use revisions,
   use the `istio.io/rev` label with the correct revision.

1. Make sure that the injector webhook is installed and is running.

1. Recreate the pod. For a `Deployment`, use `kubectl rollout restart`.

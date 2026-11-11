---
title: ImageAutoWithoutInjectionWarning
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a `Deployment` has an `istio-proxy` container with `image: auto`, but no Istio
injection webhook selects the pods of the `Deployment`.

The `auto` image is a placeholder. The sidecar injector replaces it with the correct image. This is
the usual method to [install gateways](/docs/setup/additional-setup/gateway/). If injection does not
occur, the pods cannot pull the image `auto` and do not start.

## An example

Consider this `Deployment` in a namespace that does not have injection enabled:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingressgateway
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  template:
    metadata:
      labels:
        istio: ingressgateway
    spec:
      containers:
      - name: istio-proxy
        image: auto
{{< /text >}}

You will receive this message:

{{< text plain >}}
Warning [IST0146] (Deployment default/istio-ingressgateway) Deployment istio-ingressgateway contains `image: auto` but does not match any Istio injection webhook selectors.
{{< /text >}}

## How to resolve

Enable injection for the pods. For example, add the `istio-injection=enabled` label to the namespace,
or add the `sidecar.istio.io/inject: "true"` label to the pod template. If you use revisions, use the
`istio.io/rev` label with the correct revision.

---
title: DestinationRuleSubsetNotSelectPods
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a subset in a `DestinationRule` does not select any pods.

Requests that are routed to this subset fail with a `503` error and the `UH` (no healthy upstream)
response flag.

## An example

Consider this `DestinationRule`, when no `reviews` pod has the label `version: v4`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v4
    labels:
      version: v4
{{< /text >}}

You will receive this message:

{{< text plain >}}
Error [IST0173] (DestinationRule default/reviews) The Subset v4 defined in the DestinationRule does not select any pods. Which may lead to 503 UH (NoHealthyUpstream).
{{< /text >}}

## How to resolve

Do one of these:

- Change the labels of the subset so that they select the correct pods.
- Deploy the pods that the subset must select.
- Remove the subset if you do not use it.

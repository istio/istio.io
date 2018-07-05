---
title: Eureka - How do I unset the context changed by `istioctl` at the end?
weight: 70
---

Your `kubectl` is switched to use the Istio context at the end of the
`istio context-create` command.  You can use `kubectl config get-contexts`
to obtain the list of contexts and `kubectl config use-context {desired-context}`
to switch to use your desired context.

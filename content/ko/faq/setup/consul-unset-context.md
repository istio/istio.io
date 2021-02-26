---
title: Consul - How do I unset the context changed by kubectl at the end?
weight: 50
---

Your `kubectl` is switched to use the Istio context at the end of the `kubectl use-context istio` command.
You can use `kubectl config get-contexts` to obtain the list of contexts and
`kubectl config use-context {desired-context}` to switch to use your desired context.

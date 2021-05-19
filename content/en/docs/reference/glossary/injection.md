---
title: Injection
test: n/a
---

Injection, or sidecar injection, refers to the use of [mutating webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to modify pod specifications at creation time.

Injection can be used to add the Envoy sidecar configuration for mesh services or to configure the Envoy proxy of [gateways](/docs/reference/glossary/#gateway).

See [Installing the sidecar](/docs/setup/additional-setup/sidecar-injection) for more information.

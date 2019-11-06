---
title: Policies
description: Describes Istio's policy management functionality.
weight: 30
keywords: [policy,policies]
---

Istio lets you configure custom policies for your application to enforce rules at runtime such as:

- Rate limiting to dynamically limit the traffic to a service
- Denials, whitelists, and blacklists, to restrict access to services
- Header rewrites and redirects

Istio also lets you create your own [policy adapters](/docs/tasks/policy-enforcement/control-headers) to add, for example, your own custom authorization behavior.

You must [enable policy enforcement](/docs/tasks/policy-enforcement/enabling-policy) for your mesh to use this feature.

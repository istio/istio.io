---
title: Authorization Too Restrictive
description: Authorization is enabled and no requests make it through to the service.
weight: 60
aliases:
    - /help/ops/security/authorization-restrictive
---

When you first enable authorization for a service, all requests are denied by default. After you add one or more authorization policies, then
matching requests should flow through. If all requests continue to be denied, you can try the following:

1. Make sure there is no typo in your policy YAML file.

1. Avoid enabling authorization for Istio Control Planes Components, including Mixer, Pilot, Ingress. Istio authorization policy is designed for authorizing access to services in Istio Mesh. Enabling it for Istio Control Planes Components may cause unexpected behavior.

1. Make sure that your `ServiceRoleBinding` and referred `ServiceRole` objects are in the same namespace (by checking "metadata"/”namespace” line).

1. Make sure that your service role and service role binding policies don't use any HTTP only fields
for TCP services. Otherwise, Istio ignores the policies as if they didn't exist.

1. In Kubernetes environment, make sure all services in a `ServiceRole` object are in the same namespace as the
`ServiceRole` itself. For example, if a service in a `ServiceRole` object is `a.default.svc.cluster.local`, the `ServiceRole` must be in the
`default` namespace (`metadata/namespace` line should be `default`). For non-Kubernetes environments, all `ServiceRoles` and `ServiceRoleBindings`
for a mesh should be in the same namespace.

1. Visit [Debugging Authorization](/docs/ops/security/debugging-authorization/)
   to find out the exact cause.

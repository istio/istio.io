---
title: MTLSPolicyConflict
layout: analysis-message
---

This message occurs when a destination rule resource and a policy resource are
in conflict with regards to mutual TLS. The two resources are in conflict if they each
specify incompatible mutual TLS modes to be used; this conflict means traffic matching
the destination rule to the specified host will be rejected.

This message is deprecated and only produced on service meshes that are using alpha authentication policy.

## An example

Consider an Istio mesh with the following mesh policy:

{{< text yaml >}}
apiVersion: authentication.istio.io/v1alpha1
kind: MeshPolicy
metadata:
  name: default
spec:
  peers:
  - mtls: {}
{{< /text >}}

The effect of this policy resource is that all services have an authentication
policy requiring mutual TLS to be used. However, note that without a corresponding
destination rule requiring traffic to use mutual TLS, traffic will be sent to services
without using mutual TLS. This conflict means that traffic destined for services in
the mesh will ultimately fail.

In this example, you can fix the issue in one of two ways: you could downgrade
the mesh policy's mutual TLS requirements to accept plaintext traffic (which might include
removing the mesh policy entirely), or you can create a corresponding
destination rule that specifies to use mutual TLS for traffic within the mesh:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: mtls-for-cluster
spec:
  host: *.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
{{< /text >}}

## Which destination rules and policies are relevant to a service

To effectively resolve mutual TLS conflicts, it's helpful to understand how both
destination rules and policies affect traffic to a service. Consider an example
service named `my-service` in namespace `my-namespace`. To determine which
policy object is applied to `my-service`, the following resources are matched in
order:

1. A policy resource in namespace `my-namespace` that contains a `target`
   specifying `my-service`.
1. A policy resource named `default` in namespace `my-namespace` that does not
   contain a `target`. This policy implicitly applies to the entire namespace.
1. A mesh policy resource named `default`.

To determine which destination rules are applied to traffic sent to
`my-service`, we must first know which namespace the traffic originates from.
For the sake of this example, let's call that namespace `other-namespace`.
Destination rules are matched in the following order:

1. A destination rule in namespace `other-namespace` that specifies a host that
   matches `my-service.my-namespace.svc.cluster.local`. This may be an exact
   match or a wildcard match. Also note that the `exportTo` field, which
   controls the visibility of configuration resources, will effectively be
   ignored as resources within the same namespace as the source service are
   always visible.
1. A destination rule in namespace `my-namespace` that specifies a host that
   matches `my-service.my-namespace.svc.cluster.local`. This may be an exact
   match or a wildcard match. Note that the `exportTo` field must specify that
   this resource is public (e.g. it has the value `"*"` or is not specified) in
   order for a match to occur.
1. A destination rule in the "root namespace" (which is, by default,
   `istio-system`) that matches `my-service.my-namespace.svc.cluster.local`. The
   root namespace is controlled by the `rootNamespace` property in the
   [`MeshConfig` resource](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig).
   Note that the `exportTo` field must specify that this resource is public
   (e.g. it has the value `"*"` or is not specified) in order for a match to
   occur.

Finally, be aware that Istio doesn't apply any concept of inheritance when
following these rules. The first resources that matches the specified criteria
is used.

## How to resolve

Look at the output of the message. You should see something like:

{{< text plain >}}
Error [IST0113] (DestinationRule default-rule.istio-system) A DestinationRule
and Policy are in conflict with regards to mTLS for host
myhost.my-namespace.svc.cluster.local:8080. The DestinationRule
"istio-system/default-rule" specifies that mTLS must be true but the Policy
object "my-namespace/my-policy" specifies Plaintext.
{{< /text >}}

Contained in this message are the two resources that are in conflict:

* Policy resource `my-namespace/my-policy`, which is specifying 'Plaintext' as its
  supported mutual TLS mode.
* Destination rule resource `istio-system/default-rule`, which is requiring mutual TLS
  when sending traffic to host `myhost.my-namespace.svc.cluster.local:8080`

You can fix the conflict by doing one of the following:

* Modifying policy resource `my-namespace/my-policy` to require mutual TLS as an
  authentication mode. In general this is done by adding a `peers` attribute to
  the resource with a child of `mtls`. You can read more about how this is
  achieved on the [reference page for policy objects](/docs/reference/config/security/istio.authentication.v1alpha1/#Policy).
* Modifying destination rule `istio-system/default-rule` to not use mutual TLS by
  removing the `ISTIO_MUTUAL` traffic policy. Note that `default-rule` is in the
  `istio-system` namespace - by default, the `istio-system` namespace is
  considered the "root namespace" for configuration (although this can be overridden via
  the `rootNamespace` property in the [`MeshConfig` resource](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig).
  That means that this destination rule potentially affects all other services
  in the mesh.
* Add a new destination rule in the same namespace as the service (in this case,
  namespace `my-namespace`), and do not specify a traffic policy of
  `ISTIO_MUTUAL`. Because this rule is located in the same namespace as the
  service, it will override the global destination rule `istio-system/default-rule`.
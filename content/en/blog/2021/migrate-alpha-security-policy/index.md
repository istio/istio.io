---
title: Migrate the deprecated alpha security policy
description: A tutorial to help customers to migrate the deprecated alpha security policy to the beta version.
publishdate: 2021-02-01
attribution: Yangmin Zhu (Google)
keywords: [security,policy,migrate,alpha,beta,deprecate,peer,jwt,authorization]
---

Istio beta security policy (`PeerAuthentication`, `RequestAuthentication` and `AuthorizationPolicy`) has been released long
time ago and the alpha security policy (`MeshPolicy`, `Policy`, `ClusterRbacConfig`, `ServiceRole` and `ServiceRoleBinding`) has been
deprecated and no longer supported starting 1.6.

It is required to migrate the alpha security policy to the beta version before upgrading to Istio 1.6 and later.
This blog is a tutorial to help customers who are still using the alpha security policy in old Istio to migrate to beta
security policy and unblock the upgrade to Istio 1.6 and later.

## Major changes in `v1beta1` security policy

Please note there are non-backward compatible changes in the `v1beta1` policy. The major changes related to the migration
are listed below:

| Feature | `v1alpha1` Policy | `v1beta1` Policy |
|---------|------------------------|--------------------------------|
| API stability | **No** backward compatible | backward compatible **guaranteed** |
| mTLS related CRDs | `MeshPolicy` and `Policy` | `PeerAuthentication` |
| JWT related CRDs | `MeshPolicy` and `Policy` | `RequestAuthentication` and `AuthorizationPolicy` |
| Access Control related CRDs | `ClusterRbacConfig`, `ServiceRole` and `ServiceRoleBinding` | `AuthorizationPolicy` |
| Policy target | **service** name based | **workload** label based |
| Port number | **service** ports | **workload** ports |

The alpha JWT policy needs to be converted to both `RequestAuthentication` and `AuthorizationPolicy`. The JWT deny response
is also changed due to the use of `AuthorizationPolicy`. In alpha policy, the HTTP code 401 will be returned with the
body `Origin authentication failed`. In beta policy, the HTTP code 403 will be returned with the body `RBAC: access denied`.

Additionally, the [`triggerRule.regex` field](https://istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/#StringMatch)
in the alpha JWT policy is not supported by the `AuthorizationPolicy`.

## `v1alpha1` authentication policy migration

The typical flow of migrating to `v1beta1` policy is to start by checking all the `MeshPolicy` and `Policy` applied in the
cluster and convert each of them to the corresponding `v1beta1` version.

The `MeshPolicy` is mesh-level and there should be only 1 per-cluster, for each `MeshPolicy` and `Policy` applied in the cluster:

1. If the policy has service target, it is in service level. Find and take a note of the corresponding service definition.
   You will use the service definition to convert the service target to the corresponding workload selector.

1. If the policy has no service target, it is in mesh/namespace level. The corresponding workload selector is just empty.

1. For each service target and mesh/namespace level policy, create an `PeerAuthentication` if the `peers` was used in
   the `v1alpha1` policy. Populate the `selector` and `portLevelMtls` if it is a service level policy. Populate the
   `mtls` mode with either `PERMISSIVE` or `STRICT` depending on the `v1alpha1` policy mode.

1. For each service target and mesh/namespace level policy, create an `RequestAuthentication` and `AuthorizationPolicy`
   if the `origins` was used in the `v1alpha1` policy. Populate the `selector` if it is a service level policy.
   Populate the `RequestAuthentication` with the corresponding JWT issuer information and the `AuthorizationPolicy`
   to require [JWT validation](https://istio.io/v1.6/docs/tasks/security/authentication/authn-policy/#require-a-valid-token)
   or [path-based JWT validation](https://istio.io/v1.6/docs/tasks/security/authentication/authn-policy/#require-valid-tokens-per-path).

1. Repeat the process for the next authentication policy.

## `v1alpha1` authentication policy example

Assume you have the following `v1alpha1` policy for the `httpbin` service in the `foo` namespace:

{{< text yaml >}}
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: example
  namespace: "foo"
spec:
  targets:
  - name: httpbin
    ports:
    - number: 8000
  peers:
  - mtls: {}
  origins:
  - jwt:
      issuer: testing@example.com
      jwksUri: "https://www.example.com/jwks.json"
      triggerRules:
      - includedPaths:
        - prefix: "/admin/"
        excludedPaths:
        - exact: "/admin/status"
  principalBinding: USE_ORIGIN
{{< /text >}}

Migrate the above authentication policy to `v1beta1` in the following ways:

1. Assume the `httpbin` service in the `foo` namespace has the following workload selector:

    {{< text yaml >}}
    selector:
      app: httpbin
    ports:
    - name: http
      port: 8000
      targetPort: 80
    {{< /text >}}

1. Create the `PeerAuthentication` to migrate the mTLS part:

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: PeerAuthentication
    metadata:
      name: httpbin
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
    mtls:
      # Use PERMISSIVE by default for maximum backward compatibility
      mode: PERMISSIVE
    portLevelMtls:
      # This should be the workload port 80, not the service port 8000
      80:
        mode: STRICT
    {{< /text >}}

1. Create the `RequestAuthentication` and `AuthorizationPolicy` to migrate the JWT part:

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: RequestAuthentication
    metadata:
      name: example-httpbin
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: testing@example.com
        jwksUri: "https://www.example.com/jwks.json"
    ---
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: example-httpbin
      namespace: foo
    spec:
      # Use DENY action to explicitly deny requests without JWT token
      action: DENY
      selector:
        matchLabels:
          app: httpbin
      rules:
      - from:
        - source:
            # This makes sure requests without JWT token will be denied
            notRequestPrincipals: ["*"]
        to:
        - operation:
            # This should be the workload port 80, not the service port 8000
            ports: ["80"]
            # The path is converted from the trigger rule
            notPaths: ["/admin/status"]
            paths: ["/admin/*"]
    {{< /text >}}

1. Apply the `PeerAuthentication`, `RequestAuthentication` and `AuthorizationPolicy` and monitor the traffic to make
   sure it works as expected.

## the `v1alpha1` RBAC policy migration

The typical flow of migrating to `v1beta1` policy is to start by checking the `ClusterRbacConfig` to decide which
namespace or service is enabled with RBAC.

For each service enabled with RBAC:

1. Get the workload selector from the service definition.

1. Create a `v1beta1` policy with the workload selector.

1. Update the `v1beta1` policy for each `ServiceRole` and `ServiceRoleBinding` applied to the service.

1. Apply the `v1beta1` policy and monitor the traffic to make sure the policy is working as expected.

1. Repeat the process for the next service enabled with RBAC.

For each namespace enabled with RBAC:

1. Apply a `v1beta1` policy that denies all traffic to the given namespace.

## `v1alpha1` RBAC policy example

Assume you have the following `v1alpha1` RBAC policies for the `httpbin` service in the `foo` namespace:

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["foo"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: httpbin
  namespace: foo
spec:
  rules:
  - services: ["httpbin.foo.svc.cluster.local"]
    methods: ["GET"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: httpbin
  namespace: foo
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/sleep"
    roleRef:
      kind: ServiceRole
      name: "httpbin"
{{< /text >}}

Migrate the above RBAC policies to `v1beta1` in the following ways:

1. Assume the `httpbin` service in the `foo` namespace has the following workload selector:

    {{< text yaml >}}
    selector:
      app: httpbin
      version: v1
    {{< /text >}}

1. Create the `AuthorizationPolicy` with the following content:

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: httpbin
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
          version: v1
      action: ALLOW
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/sleep"]
        to:
        - operation:
            methods: ["GET"]
    {{< /text >}}

1. Create the following `AuthorizationPolicy` that denies all traffic to the `foo` namespace because the `foo` namespace
   was enabled with RBAC:

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: allow-nothing
      namespace: foo
    spec:
      {}
    {{< /text >}}

1. Apply the `AuthorizationPolicy` and monitor the traffic to make sure it works as expected.

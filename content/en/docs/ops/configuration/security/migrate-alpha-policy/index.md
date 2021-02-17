---
title: Migrate the deprecated alpha security policy
description: A tutorial to help customers migrate the deprecated alpha security policy to the beta version.
keywords: [security,policy,migrate,alpha,beta,deprecate,peer,jwt,authorization]
weight: 20
owner: istio/wg-security-maintainers
test: n/a
---

Istio beta security policy (`PeerAuthentication`, `RequestAuthentication` and `AuthorizationPolicy`) has been released
since release 1.5 and the alpha security policy (`MeshPolicy`, `Policy`, `ClusterRbacConfig`, `ServiceRole` and `ServiceRoleBinding`)
has been deprecated and no longer supported starting with release 1.6.

It is required to migrate the alpha security policy to the beta version before upgrading to Istio 1.6 and later.
This tutorial helps customers who are still using the alpha security policy in a `pre-1.6` version to migrate to
the beta security policy and unblock the upgrade to Istio 1.6 and later.

## Overview

The control plane should be upgraded first to bring in support of the `v1beta1` security policy.

It is recommended to first upgrade to Istio 1.5 as a transitive version because it supports both `v1alpha1` and `v1beta1`
security policies. You complete the security policy migration in Istio 1.5, remove the `v1alpha1` security policy and
then continue the upgrade to later Istio versions. Istio 1.5 is the only version that supports both `v1alpha1` and
`v1beta1` security policy. For a given workload, the `v1beta1` version will take precedence over the `v1alpha1` version.

Alternatively, if you want to do a skip-upgrade directly from Istio 1.4 to Istio 1.6 or later, you should use the
[canary upgrade](/docs/setup/upgrade/canary/) to install the new Istio version as a separate control plane, gradually
migrate your workloads to the new control plane completing the security policy migration at the same time.

{{< warning >}}
Skip-upgrade is not supported by Istio and there might be other issues in this process. Istio 1.6 does not support
the `v1alpha1` security policy, and if you do not migrate them to `v1beta1` version, you are essentially deleting all your
`v1alpha1` security policies.
{{< /warning >}}

In either case, it is recommended to migrate using namespace granularity: for each namespace, find all
`v1alpha1` policies that have an effect on the workloads in the namespace and migrate all the `v1alpha1` policies at the same time.
This allows a safer migration as you can apply the `v1beta1` policies one namespace at a time, make sure everything is working
as expected, and then move forward to the next namespace.

## Major Differences

Before starting the migration, read through the `v1beta1` [authentication](/docs/concepts/security/#authentication)
and [authorization](/docs/concepts/security/#authorization) documentation to understand the `v1beta1` policy.

You should examine all of your existing `v1alpha1` security policies, find out what fields are used and which policies
need migration, compare the findings with the major differences listed below and confirm there are no blocking issues
(e.g., using some alpha feature that is no longer supported in beta):

| Major Differences | `v1alpha1` | `v1beta1` |
|---------|------------------------|--------------------------------|
| API stability | not backward compatible | backward compatible |
| mTLS | `MeshPolicy` and `Policy` | `PeerAuthentication` |
| JWT | `MeshPolicy` and `Policy` | `RequestAuthentication` |
| Authorization | `ClusterRbacConfig`, `ServiceRole` and `ServiceRoleBinding` | `AuthorizationPolicy` |
| Policy target | service name based | workload selector based |
| Port number | service ports | workload ports |

Although `RequestAuthentication` in `v1beta1` security policy is similar to `v1alpha1` JWT policy, there is a notable
semantics change. The `v1alpha1` JWT policy needs to be migrated to two `v1beta1` resources: `RequestAuthentication` and
`AuthorizationPolicy`. This will change the JWT deny message due to the use of `AuthorizationPolicy`. In the alpha version,
the HTTP code 401 is returned with the body `Origin authentication failed`. In the beta version, the HTTP code 403 is
returned with the body `RBAC: access denied`.

The `v1alpha1` JWT policy [`triggerRule` field](https://istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/#Jwt-TriggerRule)
is replaced by the `AuthorizationPolicy` with the exception that the [`regex` field](https://istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/#StringMatch)
is no longer supported.

## Migration flow

This section describes details of how to migrate the `v1alpha1` security policy workload.

### Step 1: Find related policies

For each namespace, find all `v1alpha1` security policies that have an effect on workloads in the namespace. The result
could include:

- a single `MeshPolicy` that applies to all services in the mesh;
- a single namespace level `Policy` that applies to all workloads in the namespace;
- multiple service level `Policy` that applies to the selected services in the namespace;
- a single `ClusterRbacConfig` that enables the RBAC on the whole namespace or some services in the namespace;
- multiple namespace level `ServiceRole` and `ServiceRoleBinding` that applies to all services in the namespace;
- multiple service level `ServiceRole` and `ServiceRoleBinding` that applies to the selected services in the namespace;

### Step 2: Convert service name to workload selector

The `v1alpha1` policy selects targets using service name. You should refer to the corresponding service definition to decide
the workload selector that should be used in the `v1beta1` policy.

A single `v1alpha1` policy may include multiple services. It will need to be migrated to multiple `v1beta1` policies
because the `v1beta1` policy currently only supports at most one workload selector per policy.

Also note the `v1alpha1` policy uses service port but the `v1beta1` policy uses the workload port, this means the port number might be
different in the migrated `v1beta1` policy.

### Step 3: Migrate authentication policy

For each `v1alpha1` authentication policy, migrate with the following rules:

1. If the whole namespace is enabled with mTLS or JWT, create the `PeerAuthentication`, `RequestAuthentication` and
   `AuthorizationPolicy` without workload selector for the whole namespace. Fill out the policy based on the
   semantics of the corresponding `MeshPolicy` or `Policy` for the namespace;

1. If a workload is enabled with mTLS or JWT, create the `PeerAuthentication`, `RequestAuthentication` and
   `AuthorizationPolicy` with corresponding workload selector for the workload. Fill out the policy based on the
   semantics of the corresponding `MeshPolicy` or `Policy` for the workload;

1. For mTLS related configuration, use `STRICT` mode if the alpha policy is using `STRICT`, use `PERMISSIVE` in all other cases;

1. For JWT related configuration, refer [`End-user authentication` documentation](/docs/tasks/security/authentication/authn-policy/#end-user-authentication)
   to learn how to migrate to the `RequestAuthentication` and `AuthorizationPolicy`;

### Step 4: Migrate RBAC policy

For each `v1alpha1` RBAC policy, migrate with the following rules:

1. If the whole namespace is enabled with RBAC, create an `AuthorizationPolicy` without workload selector for the whole
   namespace. Add an empty rule so that it will deny all requests to the namespace by default;

1. If a workload is enabled with RBAC, create an `AuthorizationPolicy` with corresponding workload selector for the workload.
   Add rules based on the semantics of the corresponding `ServiceRole` and `ServiceRoleBinding` for the workload;

### Step 5: Verify migrated policy

1. Double check the migrated `v1beta1` policies, make sure there are no policies with duplicate names, the namespace
   is specified correctly and all `v1alpha1` policies for the given namespace are migrated;

1. Dry-run the `v1beta1` policy with the command `kubectl apply --dry-run=server -f beta-policy.yaml` to make sure it
   is valid;

1. Apply the `v1beta1` policy to the given namespace and closely monitor the effect. Make sure to test both allow and
   deny scenarios if JWT or authorization are used;

1. Migrate the next namespace, only remove the `v1alpha1` policy after completing migration for
   all namespaces successfully;

## Example

### `v1alpha1` policy

This section gives a full example showing the migration for namespace `foo`. Assume the namespace `foo` has the following
`v1alpha1` policies that affect the workloads in it:

{{< text yaml >}}
# A MeshPolicy that enables mTLS globally, including the whole foo namespace
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
---
# A Policy that enables mTLS permissive mode and enables JWT for the httpbin service on port 8000
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: httpbin
  namespace: foo
spec:
  targets:
  - name: httpbin
    ports:
    - number: 8000
  peers:
  - mtls:
      mode: PERMISSIVE
  origins:
  - jwt:
      issuer: testing@example.com
      jwksUri: https://www.example.com/jwks.json
      triggerRules:
      - includedPaths:
        - prefix: /admin/
        excludedPaths:
        - exact: /admin/status
  principalBinding: USE_ORIGIN
---
# A ClusterRbacConfig that enables RBAC globally, including the foo namespace
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON'
---
# A ServiceRole that enables RBAC for the httpbin service
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
# A ServiceRoleBinding for the above ServiceRole
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: httpbin
  namespace: foo
spec:
  subjects:
  - user: cluster.local/ns/foo/sa/sleep
    roleRef:
      kind: ServiceRole
      name: httpbin
{{< /text >}}

### `httpbin` service

The `httpbin` service has the following definition:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: foo
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
{{< /text >}}

This means the service name `httpbin` should be replaced by the workload selector `app: httpbin`, and the service port 8000
should be replaced by the workload port 80.

### `v1beta1` authentication policy

The migrated `v1beta1` policies for the `v1alpha1` authentication policies in `foo` namespace are listed below:

{{< text yaml >}}
# A PeerAuthentication that enables mTLS for the foo namespace, migrated from the MeshPolicy
# Alternatively the MeshPolicy could also be migrated to a PeerAuthentication at mesh level
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
# A PeerAuthentication that enables mTLS for the httpbin workload, migrated from the Policy
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: httpbin
  namespace: foo
spec:
  selector:
    matchLabels:
      app: httpbin
  # port level mtls set for the workload port 80 corresponding to the service port 8000
  portLevelMtls:
    80:
      mode: PERMISSIVE
--
# A RequestAuthentication that enables JWT for the httpbin workload, migrated from the Policy
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: httpbin
  namespace: foo
spec:
  selector:
    matchLabels:
      app: httpbin
  jwtRules:
  - issuer: testing@example.com
    jwksUri: https://www.example.com/jwks.json
---
# An AuthorizationPolicy that enforces to require JWT validation for the httpbin workload, migrated from the Policy
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-jwt
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
        # The path and notPath is converted from the trigger rule in the Policy
        paths: ["/admin/*"]
        notPaths: ["/admin/status"]
{{< /text >}}

### `v1beta1` authorization policy

The migrated `v1beta1` policies for the `v1alpha1` RBAC policies in `foo` namespace are listed below:

{{< text yaml >}}
# An AuthorizationPolicy that denies by default, migrated from the ClusterRbacConfig
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: default
  namespace: foo
spec:
  # An empty rule that allows nothing
  {}
---
# An AuthorizationPolicy that enforces to authorization for the httpbin workload, migrated from the ServiceRole and ServiceRoleBinding
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
        principals: ["cluster.local/ns/foo/sa/sleep"]
    to:
    - operation:
        methods: ["GET"]
{{< /text >}}

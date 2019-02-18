---
title: Authorization for groups and list claims
description: Tutorial on how to configure the groups-base authorization and configure the authorization of list-typed claims in Istio.
weight: 10
keywords: [security,authorization]
---

This tutorial walks you through examples to configure the groups-base
authorization and the authorization of list-typed claims in Istio.

## Before you begin

* Read the [authorization](/docs/concepts/security/#authorization) concept
and go through the guide on how to
[configure Istio authorization](/docs/tasks/security/role-based-access-control).

* Read the Istio
[authentication policy](/docs/concepts/security/#authentication-policies)
and the related
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication)
concepts.

* Create a Kubernetes cluster with Istio installed and mutual TLS enabled.
To fulfill this prerequisite you can follow the Kubernetes
[installation instructions](/docs/setup/kubernetes/quick-start/#installation-steps).

## Setup the required namespace and services

This tutorial runs in a new namespace called `rbac-groups-test-ns`,
with two services, `httpbin` and `sleep`, both running with an Envoy sidecar
proxy. The following command sets an environmental variable to store the
name of the namespace, creates the namespace, and starts the two services.
Before running the following command, you need to enter the directory
containing the Istio installation files.

1.  Set the value of the `NS` environmental variable to `rbac-listclaim-test-ns`:

    {{< text bash >}}
    $ export NS=rbac-groups-test-ns
    {{< /text >}}

1.  Make sure that the `NS` environmental variable points to a testing-only
namespace. Run the following command to delete all resources in the namespace
pointed by the `NS` environmental variable.

    {{< text bash >}}
    $ kubectl delete namespace $NS
    {{< /text >}}

1.  Create the namespace for this tutorial:

    {{< text bash >}}
    $ kubectl create ns $NS
    {{< /text >}}

1.  Create the `httpbin` and `sleep` services and deployments:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n $NS
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n $NS
    {{< /text >}}

1.  To verify that `httpbin` and `sleep` services are running and `sleep` is able to
    reach `httpbin`, run the following curl command:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
    {{< /text >}}

    When the command succeeds, it returns the HTTP code 200.

## Configure JSON Web Token (JWT) authentication with mutual TLS

The authentication policy you apply next enforces that a valid JWT is needed to
access the `httpbin` service.
The JSON Web Key Set (JWKS) endpoint defined in the policy must sign the JWT.
This tutorial uses the
[JWKS endpoint]({{< github_file >}}/security/tools/jwt/samples/jwks.json)
from the Istio code base and uses
[this sample JWT]({{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt).
The sample JWT contains a JWT claim with a `groups` claim key and a list of
strings, [`"group1"`, `"group2"`] as the claim value.
The JWT claim value could either be a string or a list of strings; both types
are supported.

1.  Apply an authentication policy to require both mutual TLS and
JWT authentication for `httpbin`.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "require-mtls-jwt"
    spec:
      targets:
      - name: httpbin
      peers:
      - mtls: {}
      origins:
      - jwt:
          issuer: "testing@secure.istio.io"
          jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
      principalBinding: USE_ORIGIN
    EOF
    {{< /text >}}

1.  Set the `TOKEN` environmental variable to contain a valid sample JWT.

    {{< text bash>}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s)
    {{< /text >}}

1.  Connect to the `httpbin` service:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    When a valid JWT is attached, it returns the HTTP code 200.

1.  Verify that the connection to the `httpbin` service fails when the JWT is not attached:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
    {{< /text >}}

    When no valid JWT is attached, it returns the HTTP code 401.

## Configure groups-based authorization

This section creates a policy to authorize the access to the `httpbin`
service if the requests are originated from specific groups.
As there may be some delays due to caching and other propagation overhead,
wait until the newly defined RBAC policy to take effect.

1.  Enable the Istio RBAC for the namespace:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["rbac-groups-test-ns"]
    EOF
    {{< /text >}}

1.  Once the RBAC policy takes effect, verify that Istio rejected the curl
connection to the `httpbin` service:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    Once the RBAC policy takes effect, the command returns the HTTP code 403.

1.  To give read access to the `httpbin` service, create the `httpbin-viewer`
service role:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: httpbin-viewer
      namespace: rbac-groups-test-ns
    spec:
      rules:
      - services: ["httpbin.rbac-groups-test-ns.svc.cluster.local"]
        methods: ["GET"]
    EOF
    {{< /text >}}

1.  To assign the `httpbin-viewer` role to users in `group1`, create the
`bind-httpbin-viewer` service role binding.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-httpbin-viewer
      namespace: rbac-groups-test-ns
    spec:
      subjects:
      - properties:
          request.auth.claims[groups]: "group1"
      roleRef:
        kind: ServiceRole
        name: "httpbin-viewer"
    EOF
    {{< /text >}}

    Alternatively, you can specify the `group` property under `subjects`.
    Both ways to specify the group are equivalent.
    Currently, Istio only supports matching against a list of strings in
    the JWT for the `request.auth.claims` property and the `group` property under
    `subjects`.

    To specify the `group` property under `subjects`, use the following command:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-httpbin-viewer
      namespace: rbac-groups-test-ns
    spec:
      subjects:
      - group: "group1"
      roleRef:
        kind: ServiceRole
        name: "httpbin-viewer"
    EOF
    {{< /text >}}

    Wait for the newly defined RBAC policy to take effect.

1.  After the RBAC policy takes effect, verify the connection to the `httpbin`
service succeeds:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    The HTTP header including a valid JWT with the `groups` claim
    value of [`"group1"`, `"group2"`] returns HTTP code 200
    since it contains `group1`.

## Configure the authorization of list-typed claims

Istio RBAC supports configuring the authorization of list-typed claims.
The example JWT contains a JWT claim with a `scope` claim key and
a list of strings, [`"scope1"`, `"scope2"`] as the claim value.
You may use the `gen-jwt`
[python script]({{<github_file>}}/security/tools/jwt/samples/gen-jwt.py)
to generate a JWT with other list-typed claims for testing purposes.
Follow the instructions in the `gen-jwt` script to use the `gen-jwt.py` file.

1.  To assign the `httpbin-viewer` role to a request with a JWT including a
list-typed `scope` claim with the value of `scope1`,
create a service role binding with name `bind-httpbin-viewer`:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-httpbin-viewer
      namespace: rbac-groups-test-ns
    spec:
      subjects:
      - properties:
          request.auth.claims[scope]: "scope1"
      roleRef:
        kind: ServiceRole
        name: "httpbin-viewer"
    EOF
    {{< /text >}}

    Wait for the newly defined RBAC policy to take effect.

1.  After the RBAC policy takes effect, verify that the connection to
the `httpbin` service succeeds:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    The HTTP header including a valid JWT with the `scope` claim
    value of [`"scope1"`, `"scope2"`] returns HTTP code 200
    since it contains `scope1`.

## Cleanup

After completing this tutorial, run the following command to delete all
resources created in the namespace.

{{< text bash >}}
$ kubectl delete namespace $NS
{{< /text >}}

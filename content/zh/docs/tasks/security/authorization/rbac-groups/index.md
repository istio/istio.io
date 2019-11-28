---
title: Authorization for groups and list claims
description: Tutorial on how to configure the groups-base authorization and configure the authorization of list-typed claims in Istio.
weight: 30
keywords: [security,authorization]
aliases:
    - /docs/tasks/security/rbac-groups/
---

This tutorial walks you through examples to configure the groups-base
authorization and the authorization of list-typed claims in Istio.

## Before you begin

* Read the [authorization](/docs/concepts/security/#authorization) concept
and go through the guide on how to
[configure Istio authorization](/docs/tasks/security/authorization/authz-http).

* Read the Istio
[authentication policy](/docs/concepts/security/#authentication-policies)
and the related
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication)
concepts.

* Follow the [Istio installation guide](/docs/setup/install/istioctl/)
to install Istio with mutual TLS enabled.

## Setup the required namespace and workloads

This tutorial runs in a new namespace called `authz-groups-test-ns`,
with two workloads, `httpbin` and `sleep`, both running with an Envoy sidecar
proxy. The following command sets an environmental variable to store the
name of the namespace, creates the namespace, and starts the two workloads.
Before running the following command, you need to enter the directory
containing the Istio installation files.

1.  Set the value of the `NS` environmental variable to `authz-groups-test-ns`:

    {{< text bash >}}
    $ export NS=authz-groups-test-ns
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

1.  Create the `httpbin` and `sleep` workloads and deployments:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n $NS
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n $NS
    {{< /text >}}

1.  To verify that `httpbin` and `sleep` workloads are running and `sleep` is able to
    reach `httpbin`, run the following curl command:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
    {{< /text >}}

    When the command succeeds, it returns the HTTP code 200.

## Configure JSON Web Token (JWT) authentication with mutual TLS

The authentication policy you apply next enforces that a valid JWT is needed to
access the `httpbin` workload.
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

1.  Apply a `DestinationRule` policy on `sleep` to use mutual TLS when
communicating with `httpbin`.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: use-mtls-on-sleep
    spec:
      host: httpbin.$NS.svc.cluster.local
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

1.  Set the `TOKEN` environmental variable to contain a valid sample JWT.

    {{< text bash >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s)
    {{< /text >}}

1.  Connect to the `httpbin` workload:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    When a valid JWT is attached, it returns the HTTP code 200.

1.  Verify that the connection to the `httpbin` workload fails when the JWT is not attached:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
    {{< /text >}}

    When no valid JWT is attached, it returns the HTTP code 401.

## Configure groups-based authorization

This section creates a policy to authorize the access to the `httpbin`
workload if the requests are originated from specific groups.
As there may be some delays due to caching and other propagation overhead,
wait until the newly defined authorization policy to take effect.

1. Run the following command to create a `deny-all` policy in the `default` namespace.
   The policy doesn't have a `selector` field, which applies the policy to every workload in the
   `$NS` namespace. The `spec:` field of the policy has the empty value `{}`.
   The empty value means that no traffic is permitted, effectively denying all requests.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: deny-all
    spec:
      {}
    EOF
    {{< /text >}}

1.  Once the policy takes effect, verify that Istio rejected the curl
connection to the `httpbin` workload:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    Once the policy takes effect, the command returns the HTTP code 403.

1.  To give read access to the `httpbin` workload, create the `httpbin-viewer`
policy that applies to workload with label `app: httpbin` and allows users in
`group1` to access it with `GET` method:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "httpbin-viewer"
    spec:
      selector:
        matchLabels:
          app: httpbin
      rules:
      - to:
        - operation:
            methods: ["GET"]
        when:
        - key: request.auth.claims[groups]
          values: ["group1"]
    EOF
    {{< /text >}}

    Wait for the newly defined policy to take effect.

1.  After the policy takes effect, verify the connection to the `httpbin`
workload succeeds:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    The HTTP header including a valid JWT with the `groups` claim
    value of [`"group1"`, `"group2"`] returns HTTP code 200
    since it contains `group1`.

## Configure the authorization of list-typed claims

Istio supports configuring the authorization of list-typed claims.
The example JWT contains a JWT claim with a `scope` claim key and
a list of strings, [`"scope1"`, `"scope2"`] as the claim value.
You may use the `gen-jwt`
[python script]({{<github_file>}}/security/tools/jwt/samples/gen-jwt.py)
to generate a JWT with other list-typed claims for testing purposes.
Follow the instructions in the `gen-jwt` script to use the `gen-jwt.py` file.

1.  To allow requests with a JWT including a list-typed `scope` claim with the value of `scope1`,
update the policy `httpbin-viewer` with the following command:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "httpbin-viewer"
    spec:
      selector:
        matchLabels:
          app: httpbin
      rules:
      - to:
        - operation:
            methods: ["GET"]
        when:
        - key: request.auth.claims[scope]
          values: ["scope1"]
    EOF
    {{< /text >}}

    Wait for the newly defined policy to take effect.

1.  After the policy takes effect, verify that the connection to
the `httpbin` workload succeeds:

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

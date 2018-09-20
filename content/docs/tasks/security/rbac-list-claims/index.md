---
title: Authorization for list-typed claims
description: Tutorial for configuring authorization for list-typed claims in Istio.
weight: 10
keywords: [security,authorization]
---

This task go through examples of authorization for list-typed claims in Istio.

## Before you begin

* Understand [authorization](/docs/concepts/security/#authorization) concepts and go through a guide for [configuring Istio authorization](/docs/tasks/security/role-based-access-control).

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Have a Kubernetes cluster with Istio installed, with mutual TLS enabled (e.g use `install/kubernetes/istio-demo-auth.yaml` as described in
[installation steps](/docs/setup/kubernetes/quick-start/#installation-steps)).

### Setup

This tutorial runs in a new namespace called `rbac-listclaim-test-ns`, with two services, `httpbin` and `sleep`, both running with an Envoy sidecar proxy. The following commands set an environmental variable to store the name of the namespace, creates the namespace, and starts the two services. Before running the following commands, you need to enter the directory containing the Istio installation files.

{{< text bash >}}
$ export NS=rbac-listclaim-test-ns
$ kubectl create ns $NS
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n $NS
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n $NS
{{< /text >}}

To verify that `httpbin` and `sleep` services are running and `sleep` is able to reach `httpbin`, the following curl command should succeed with HTTP code 200.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

In addition, verify that no authentication policies have been defined in the newly created namespace.

{{< text bash >}}
$ kubectl get policies.authentication.istio.io -n $NS
No resources found.
{{< /text >}}

## Configure authentication and authorization

### Configure JWT authentication with mutual TLS

Apply an authentication policy to require both mutual TLS and JWT authentication for `httpbin`:

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

With the above authentication policy, a valid JWT is needed to access the httpbin service.
The JWT must be signed by the JWKS endpoint defined in the above policy.
In this tutorial, the [JWKS endpoint]({{< github_file >}}/security/tools/jwt/samples/jwks.json) is
from the Istio code base and the JWT is from a [sample JWT]({{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt),
which contains a JWT claim with the claim key being "scope" and the claim value being a list of
strings [`"scope1"`, `"scope2"`]. To generate a JWT with other list-typed claims for testing purpose, you may use
the `gen-jwt` [python script]({{<github_file>}}/security/tools/jwt/samples/gen-jwt.py).

Set the environmental variable TOKEN to contain a valid sample JWT token:

{{< text bash>}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s)
{{< /text >}}

With the authentication policy set, curl connection to the httpbin service should succeed if the JWT token is attached:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
200
{{< /text >}}

curl connection to the httpbin service should fail if the JWT token is not attached:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

### Configure authorization for list-typed claims

This section will create a policy to authorize the access to the `httpbin` service if the request includes a JWT
with the list-typed claim defined in the authorization policy.

First, Istio RBAC should be enabled for the namespace by running the following command:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n $NS -f -
apiVersion: "rbac.istio.io/v1alpha1"
kind: RbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["rbac-listclaim-test-ns"]
EOF
{{< /text >}}

As there may be some delays due to caching and other propagation overhead, wait a moment for the newly
defined RBAC policy to become effective. Run the following command to verify that the curl connection
to the `httpbin` service is rejected after the RBAC policy has become effective.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
403
{{< /text >}}

Next, create a `ServiceRole`, called httpbin-viewer, that allows read access to the `httpbin` service.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n $NS -f -
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: httpbin-viewer
  namespace: rbac-listclaim-test-ns
spec:
  rules:
  - services: ["httpbin.rbac-listclaim-test-ns.svc.cluster.local"]
    methods: ["GET"]
EOF
{{< /text >}}

Create a `ServiceRoleBinding` that assigns the `httpbin-viewer` role to a request including a JWT
with the list-typed claim `scope` being `scope1`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n $NS -f -
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: bind-httpbin-viewer
  namespace: rbac-listclaim-test-ns
spec:
  subjects:
  - user: "*"
    properties:
      request.auth.claims[scope]: "scope1"
  roleRef:
    kind: ServiceRole
    name: "httpbin-viewer"
EOF
{{< /text >}}

Wait a moment for the newly defined RBAC policy to become effective. Run the following command to verify that
the curl connection to the httpbin service succeeds after the RBAC policy has become effective. The curl
connection to the httpbin service succeeds because its header includes a valid JWT with the `scope` claim
value [`"scope1"`, `"scope2"`] containing `scope1`.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
200
{{< /text >}}

## Cleanup

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n $NS
$ kubectl delete -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n $NS
$ kubectl delete Policy require-mtls-jwt -n $NS
$ kubectl delete RbacConfig default -n $NS
$ kubectl delete ServiceRole httpbin-viewer -n $NS
$ kubectl delete ServiceRoleBinding bind-httpbin-viewer -n $NS
$ kubectl delete ns $NS
{{< /text >}}

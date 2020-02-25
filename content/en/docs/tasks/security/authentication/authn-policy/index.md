---
title: Authentication Policy
description: Shows you how to use Istio authentication policy to setup mutual TLS and basic end-user authentication.
weight: 10
keywords: [security,authentication]
aliases:
    - /docs/tasks/security/istio-auth.html
    - /docs/tasks/security/authn-policy/
---

This task covers the primary activities you might need to perform when enabling, configuring, and using Istio authentication policies. Find out more about
the underlying concepts in the [authentication overview](/docs/concepts/security/#authentication).

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Install Istio on a Kubernetes cluster with global mutual TLS disabled (e.g, use the demo configuration profile, as described in
[installation steps](/docs/setup/getting-started), or set the `global.mtls.enabled` installation option to false).

### Setup

Our examples use two namespaces `foo` and `bar`, with two services, `httpbin` and `sleep`, both running with an Envoy sidecar. We also use second
instances of `httpbin` and `sleep` running without the sidecar  in the `legacy` namespace. If you’d like to use the same examples when trying the tasks,
run the following:

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
$ kubectl create ns legacy
$ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
$ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
{{< /text >}}

You can verify setup by sending an HTTP request with `curl` from any `sleep` pod in the namespace `foo`, `bar` or `legacy` to either `httpbin.foo`,
`httpbin.bar` or `httpbin.legacy`. All requests should succeed with HTTP code 200.

For example, here is a command to check `sleep.bar` to `httpbin.foo` reachability:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

This one-liner command conveniently iterates through all reachability combinations:

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 200
sleep.legacy to httpbin.bar: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

You should also verify that there is no peer authentication policy in the system, which you can do as follows:

{{< text bash >}}
$ kubectl get peerauthentication --all-namespaces
No resources found.
{{< /text >}}

Last but not least, verify that there are no destination rules that apply on the example services. You can do this by checking the `host:` value of
 existing destination rules and make sure they do not match. For example:

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
{{< /text >}}

{{< tip >}}
Depending on the version of Istio, you may see destination rules for hosts other then those shown. However, there should be none with hosts in the `foo`,
`bar` and `legacy` namespace, nor is the match-all wildcard `*`
{{< /tip >}}

## Auto mTLS

By default, Istio tracks the server workloads migrated to Istio sidecar, and configures client sidecar to send mutual TLS traffic to those workloads automatically, and send plain text traffic to workloads without sidecars.

As a result, all traffic between workloads with sidecar will be in mTLS, without you do anything. To demonstrate that, let's examine the response from request to `httpbin/header`. When mTLS is in used, `X-Forwarded-Client-Cert` header will be injected by proxy sidecar to the upstream request to backend. Thus, exisent of that header is an evidence that mTLS is used. For example:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl http://httpbin.foo:8000/headers -s | grep X-Forwarded-Client-Cert
"X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=<redacted>"
{{< /text >}}

On the contrary, if the server doesn't have sidecar, that header doesn't exist, implying request is in plaintext.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl http://httpbin.legacy:8000/headers -s | grep X-Forwarded-Client-Cert
{{< /text >}}

## Globally enabling Istio mutual TLS in STRICT mode

As showing in the last section, while Istio automatically upgrade all traffic to mTLS between services with sidecar, it still allows services to receive plaintext traffic. If you want to prevent non-mTLS for the whole mesh, you can set a mesh-wide peer authentication policy to set mTLS mode to `STRICT`. Mesh-wide peer authentication policy must have empty `selector`, and defined in the *root namespace* like. For example:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

{{< tip >}}
The example assumes `istio-system` is the root namespace. If you used a different value during your installation, replace `istio-system` with the value you used.
 {{< /tip >}}

This policy specifies that all workloads in the mesh will only accept encrypted requests using TLS. If you run the test command above, you will see all requests still succeed, except for those from client that doesn't have sidecar (`sleep.legacy`) to server with sidecar (`httpbin.foo` or `httpbin.bar`). This is expected, as the the workload without sidecar cannot use mTLS.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

### Cleanup part 1

Remove global authentication policy and destination rules added in the session:

{{< text bash >}}
$ kubectl delete peerauthentication -n istio-system default
{{< /text >}}

## Enable mutual TLS per namespace or workload

### Namespace-wide policy

If you only want to change mTLS for all workloads within a particular namespace, you can use a namespace-wide policy. The spec of the policy is the same as the mesh-wide policy, except it should be submitted to the namespace on whicy you want to applied. For example, to enable mTLS strict for namespace `foo`, you can do:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

As this policy is applied on services in namespace `foo` only, you should see only request from client-without-sidecar (`sleep.legacy`) to `httpbin.foo` start to fail.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

### Enable mutual TLS per workload

You can also set peer authentication policy for a specific workload by setting the `selector` to match to the desired workload (by labels). However, Istio cannot aggregate workload-level policies when programming the outbound mTLS to a service, you will also need to provide a DestinationRule to specify that.

For example, to set mTLS strict for `httpbin.bar`, you will need to set both peer authentication policy as well as destination rule like below:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
EOF
{{< /text >}}

And a destination rule:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
spec:
  host: "httpbin.bar.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

Again, run the probing command. As expected, request from `sleep.legacy` to `httpbin.bar` starts failing with the same reasons.

{{< text plain >}}
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

You can further refine the mTLS settings per port. Our demo `httpbin` doesn't have multiple ports. But imagine that it does, then the following policy requires mTLS on all ports, except port `80` .

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    80:
      mode: DISABLE
EOF
{{< /text >}}

As before, it should come with a destination rule:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
spec:
  host: httpbin.bar.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
    portLevelSettings:
    - port:
        number: 8000
      tls:
        mode: DISABLE
EOF
{{< /text >}}

{{< tip >}}
- Port value in peer authentication policy is the *container port*, whereas in destination rule, it is the *service port*
- Only port that is binded to some service can be used in port-level Mtls. It will be ignored otherwise.
{{< /tip >}}

### Policy precedence

To illustrate how a workload-specific policy takes precedence over namespace-wide policy, you can add a policy to disable mutual TLS for `httpbin.foo` as below.
Note that you've already created a namespace-wide policy that enables mutual TLS for all services in namespace `foo` and observe that requests from
`sleep.legacy` to `httpbin.foo` are failing (see above).

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "overwrite-example"
  namespace: "foo"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: DISABLE
EOF
{{< /text >}}

and destination rule:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "overwrite-example"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

Re-running the request from `sleep.legacy`, you should see a success return code again (200), confirming service-specific policy overrides the namespace-wide policy.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### Cleanup part 2

Remove policies and destination rules created in the above steps:

{{< text bash >}}
$ kubectl delete peerauthentication default overwrite-example -n foo
$ kubectl delete peerauthentication httpbin -n bar
$ kubectl delete destinationrules default overwrite-example -n foo
$ kubectl delete destinationrules httpbin -n bar
{{< /text >}}

## End-user authentication

To experiment with this feature, you need a valid JWT. The JWT must correspond to the JWKS endpoint you want to use for the demo. This tutorial use the test token [JWT test]({{< github_file >}}/security/tools/jwt/samples/demo.jwt) and
[JWKS endpoint]({{< github_file >}}/security/tools/jwt/samples/jwks.json) from the Istio code base.

Also, for convenience, expose `httpbin.foo` via `ingressgateway` (for more details, see the [ingress task](/docs/tasks/traffic-management/ingress/)).

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: foo
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
  namespace: foo
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - route:
    - destination:
        port:
          number: 8000
        host: httpbin.foo.svc.cluster.local
EOF
{{< /text >}}

Get ingress IP

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

And run a test query

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

Now, add a policy that requires end-user JWT for `ingressgateway`.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "RequestAuthentication"
metadata:
  name: "jwt-example"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
EOF
{{< /text >}}

{{< tip >}}
- The policy need to be submitted in the same namespace as the workload it selects (`ingressgateway`). In this case, it is `istio-system`.
{{< /tip >}}

The policy above means if a token is provided in the Authorization header (implicitly default location), then it will be validated using the public key set at "{{< github_file >}}/security/tools/jwt/samples/jwks.json". Request will be rejected if the bearing token is invalid. Howerver, request without token is still accepted. To verify this behavior, retry the request without token, with bad token and with a valid token as followed:


{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

{{< text bash >}}
$ curl --header "Authorization: Bearer deadbeef" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

{{< text bash >}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

To observe other aspects of JWT validation, use the script [`gen-jwt.py`]({{< github_tree >}}/security/tools/jwt/samples/gen-jwt.py) to
generate new tokens to test with different issuer, audiences, expiry date, etc. The script can be downloaded from the Istio repository:

{{< text bash >}}
$ wget {{< github_file >}}/security/tools/jwt/samples/gen-jwt.py
$ chmod +x gen-jwt.py
{{< /text >}}

You also need the `key.pem` file:

{{< text bash >}}
$ wget {{< github_file >}}/security/tools/jwt/samples/key.pem
{{< /text >}}

{{< tip >}}
Download the [jwcrypto](https://pypi.org/project/jwcrypto) library,
if you haven't installed it on your system.
{{< /tip >}}

For example, the command below creates a token that
expires in 5 seconds. As you see, Istio authenticates requests using that token successfully at first but rejects them after 5 seconds:

{{< text bash >}}
$ TOKEN=$(./gen-jwt.py ./key.pem --expire 5)
$ for i in `seq 1 10`; do curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"; sleep 1; done
200
200
200
200
200
401
401
401
401
401
{{< /text >}}

You can also add a JWT policy to an ingress gateway (e.g., service `istio-ingressgateway.istio-system.svc.cluster.local`).
This is often used to define a JWT policy for all services bound to the gateway, instead of for individual services.

### Enforce valid token must be presented.

To reject request without valid token, you will need to add an authorization rule to `deny` request without `requestPrincipal` as below. Request principal is available only when a valid JWT token is provided, so the rule is equivalent to deny requests without valid token.

{{< text bash >}}
kubectl apply -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: "frontend-ingress"
  namespace: istio-system
  labels:
    demo.istio.io: security
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
{{< /text >}}

Retry request without token, you should see it now fail with error code 403.

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
403
{{< /text >}}

### Enforce valid token per-path

You can also refine the requirement per host, path, method etc with authorization. For example, you can change the authorization policy in the last section to only require JWT on `/headers`. After applying this authorization rule, request to `$INGRESS_HOST/headers` will fail with 403 code. But for all other path, e.g `$INGRESS_HOST/ip`, it should succeed. Please see other [tasks with authorization]() to learn more about other ways to refine access control with authoriation policy.

{{< text bash >}}
kubectl apply -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: "frontend-ingress"
  namespace: istio-system
  labels:
    demo.istio.io: security
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
{{< /text >}}

### Cleanup part 3

1. Remove authentication policy:

    {{< text bash >}}
    $ kubectl -n istio-system delete requestauthentication jwt-example
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, you can remove all resources simply by deleting test namespaces.

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    {{< /text >}}

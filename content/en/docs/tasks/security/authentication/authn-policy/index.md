---
title: Authentication Policy
description: Shows you how to use Istio authentication policy to set up mutual TLS and basic end-user authentication.
weight: 10
keywords: [security,authentication]
aliases:
    - /docs/tasks/security/istio-auth.html
    - /docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
---

This task covers the primary activities you might need to perform when enabling, configuring, and using Istio authentication policies. Find out more about
the underlying concepts in the [authentication overview](/docs/concepts/security/#authentication).

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Install Istio on a Kubernetes cluster with the `default` configuration profile, as described in
[installation steps](/docs/setup/getting-started).

{{< text bash >}}
$ istioctl install --set profile=default
{{< /text >}}

### Setup

Our examples use two namespaces `foo` and `bar`, with two services, `httpbin` and `sleep`, both running with an Envoy proxy. We also use second
instances of `httpbin` and `sleep` running without the sidecar in the `legacy` namespace. If you’d like to use the same examples when trying the tasks,
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
$ kubectl exec "$(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name})" -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

This one-liner command conveniently iterates through all reachability combinations:

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl -s "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

Verify there is no peer authentication policy in the system with the following command:

{{< text bash >}}
$ kubectl get peerauthentication --all-namespaces
No resources found
{{< /text >}}

Last but not least, verify that there are no destination rules that apply on the example services. You can do this by checking the `host:` value of
existing destination rules and make sure they do not match. For example:

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"

{{< /text >}}

{{< tip >}}
Depending on the version of Istio, you may see destination rules for hosts other than those shown. However, there should be none with hosts in the `foo`,
`bar` and `legacy` namespace, nor is the match-all wildcard `*`.
{{< /tip >}}

## Auto mutual TLS

By default, Istio tracks the server workloads migrated to Istio proxies, and configures client proxies to send mutual TLS traffic to those workloads automatically, and to send plain text traffic to workloads without sidecars.

Thus, all traffic between workloads with proxies uses mutual TLS, without you doing
anything. For example, take the response from a request to `httpbin/header`.
When using mutual TLS, the proxy injects the `X-Forwarded-Client-Cert` header to the
upstream request to the backend. That header's presence is evidence that mutual TLS is
used. For example:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl -s http://httpbin.foo:8000/headers -s | grep X-Forwarded-Client-Cert | sed 's/Hash=[a-z0-9]*;/Hash=<redacted>;/'
    "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=<redacted>;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/sleep"
{{< /text >}}

When the server doesn't have sidecar, the `X-Forwarded-Client-Cert` header is not there, which implies requests are in plain text.

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.legacy:8000/headers -s | grep X-Forwarded-Client-Cert

{{< /text >}}

## Globally enabling Istio mutual TLS in STRICT mode

While Istio automatically upgrades all traffic between the proxies and the workloads to mutual TLS,
workloads can still receive plain text traffic. To prevent non-mutual TLS traffic for the whole mesh,
set a mesh-wide peer authentication policy with the mutual TLS mode set to `STRICT`.
The mesh-wide peer authentication policy should not have a `selector` and must be applied in the **root namespace**, for example:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

{{< tip >}}
The example assumes `istio-system` is the root namespace. If you used a different value during installation, replace `istio-system` with the value you used.
 {{< /tip >}}

This peer authentication policy configures workloads to only accept requests encrypted with TLS.
Since it doesn't specify a value for the `selector` field, the policy applies to all workloads in the mesh.

Run the test command again:

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

You see requests still succeed, except for those from the client that doesn't have proxy, `sleep.legacy`, to the server with a proxy, `httpbin.foo` or `httpbin.bar`. This is expected because mutual TLS is now strictly required, but the workload without sidecar cannot comply.

### Cleanup part 1

Remove global authentication policy added in the session:

{{< text bash >}}
$ kubectl delete peerauthentication -n istio-system default
{{< /text >}}

## Enable mutual TLS per namespace or workload

### Namespace-wide policy

To change mutual TLS for all workloads within a particular namespace, use a namespace-wide policy. The specification of the policy is the same as for a mesh-wide policy, but you specify the namespace it applies to under `metadata`. For example, the following peer authentication policy enables strict mutual TLS for the `foo` namespace:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

As this policy is applied on workloads in namespace `foo` only, you should see only request from client-without-sidecar (`sleep.legacy`) to `httpbin.foo` start to fail.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

To set a peer authentication policy for a specific workload, you must configure the `selector` section and specify the labels that match the desired workload. For example, the following peer authentication policy enables strict mutual TLS for the `httpbin.bar` workload:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
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

Again, run the probing command. As expected, request from `sleep.legacy` to `httpbin.bar` starts failing with the same reasons.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

{{< text plain >}}
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

To refine the mutual TLS settings per port, you must configure the `portLevelMtls` section. For example, the following peer authentication policy requires mutual TLS on all ports, except port `8080`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
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
    8080:
      mode: DISABLE
EOF
{{< /text >}}

1. The port value in the peer authentication policy is the container's port.
1. You can only use `portLevelMtls` if the port is bound to a service. Istio ignores it otherwise.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

### Policy precedence

A workload-specific peer authentication policy takes precedence over a namespace-wide policy. You can test this behavior if you add a policy to disable mutual TLS for the `httpbin.foo` workload, for example.
Note that you've already created a namespace-wide policy that enables mutual TLS for all services in namespace `foo` and observe that requests from
`sleep.legacy` to `httpbin.foo` are failing (see above).

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
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

Re-running the request from `sleep.legacy`, you should see a success return code again (200), confirming service-specific policy overrides the namespace-wide policy.

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name})" -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### Cleanup part 2

Remove policies created in the above steps:

{{< text bash >}}
$ kubectl delete peerauthentication default overwrite-example -n foo
$ kubectl delete peerauthentication httpbin -n bar
{{< /text >}}

## End-user authentication

To experiment with this feature, you need a valid JWT. The JWT must correspond to the JWKS endpoint you want to use for the demo. This tutorial uses the test token [JWT test]({{< github_file >}}/security/tools/jwt/samples/demo.jwt) and
[JWKS endpoint]({{< github_file >}}/security/tools/jwt/samples/jwks.json) from the Istio code base.

Also, for convenience, expose `httpbin.foo` via an ingress gateway (for more details, see the [ingress task](/docs/tasks/traffic-management/ingress/)).

{{< boilerplate gateway-api-support >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Configure the gateway:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
{{< /text >}}

Follow the instructions in
[Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
to define the `INGRESS_PORT` and `INGRESS_HOST` environment variables.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Create the gateway:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@ -n foo
$ kubectl wait --for=condition=programmed gtw -n foo httpbin-gateway
{{< /text >}}

Set the `INGRESS_PORT` and `INGRESS_HOST` environment variables:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Run a test query through the gateway:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

Now, add a request authentication policy that requires end-user JWT for the ingress gateway.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Apply the policy in the namespace of the workload it selects, the ingress gateway in this case.

If you provide a token in the authorization header, its implicitly default location, Istio validates the token using the [public key set]({{< github_file >}}/security/tools/jwt/samples/jwks.json), and rejects requests if the bearer token is invalid. However, requests without tokens are accepted. To observe this behavior, retry the request without a token, with a bad token, and with a valid token:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

{{< text bash >}}
$ curl --header "Authorization: Bearer deadbeef" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

{{< text bash >}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

To observe other aspects of JWT validation, use the script [`gen-jwt.py`]({{< github_tree >}}/security/tools/jwt/samples/gen-jwt.py) to
generate new tokens to test with different issuer, audiences, expiry date, etc. The script can be downloaded from the Istio repository:

{{< text bash >}}
$ wget --no-verbose {{< github_file >}}/security/tools/jwt/samples/gen-jwt.py
{{< /text >}}

You also need the `key.pem` file:

{{< text bash >}}
$ wget --no-verbose {{< github_file >}}/security/tools/jwt/samples/key.pem
{{< /text >}}

{{< tip >}}
Download the [jwcrypto](https://pypi.org/project/jwcrypto) library,
if you haven't installed it on your system.
{{< /tip >}}

The JWT authentication has 60 seconds clock skew, this means the JWT token will become valid 60 seconds earlier than
its configured `nbf` and remain valid 60 seconds after its configured `exp`.

For example, the command below creates a token that
expires in 5 seconds. As you see, Istio authenticates requests using that token successfully at first but rejects them after 65 seconds:

{{< text bash >}}
$ TOKEN=$(python3 ./gen-jwt.py ./key.pem --expire 5)
$ for i in $(seq 1 10); do curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"; sleep 10; done
200
200
200
200
200
200
200
401
401
401
{{< /text >}}

You can also add a JWT policy to an ingress gateway (e.g., service `istio-ingressgateway.istio-system.svc.cluster.local`).
This is often used to define a JWT policy for all services bound to the gateway, instead of for individual services.

### Require a valid token

To reject requests without valid tokens, add an authorization policy with a rule specifying a `DENY` action for requests without request principals, shown as `notRequestPrincipals: ["*"]` in the following example. Request principals are available only when valid JWT tokens are provided. The rule therefore denies requests without valid tokens.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Retry the request without a token. The request now fails with error code `403`:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
403
{{< /text >}}

### Require valid tokens per-path

To refine authorization with a token requirement per host, path, or method, change the authorization policy to only require JWT on `/headers`. When this authorization rule takes effect, requests to `$INGRESS_HOST:$INGRESS_PORT/headers` fail with the error code `403`. Requests to all other paths succeed, for example `$INGRESS_HOST:$INGRESS_PORT/ip`.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
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

{{< /tab >}}

{{< /tabset >}}

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
403
{{< /text >}}

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/ip" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### Cleanup part 3

1. Remove authentication policy:

    {{< text bash >}}
    $ kubectl -n istio-system delete requestauthentication jwt-example
    {{< /text >}}

1. Remove authorization policy:

    {{< text bash >}}
    $ kubectl -n istio-system delete authorizationpolicy frontend-ingress
    {{< /text >}}

1. Remove the token generator script and key file:

    {{< text bash >}}
    $ rm -f ./gen-jwt.py ./key.pem
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, you can remove all resources simply by deleting test namespaces.

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    {{< /text >}}

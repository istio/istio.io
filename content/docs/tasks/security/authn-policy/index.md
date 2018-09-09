---
title: Authentication Policy
description: Shows you how to use Istio authentication policy to setup mutual TLS and basic end-user authentication.
weight: 10
keywords: [security,authentication]
aliases:
    - /docs/tasks/security/istio-auth.html
---

This task covers the primary activities you might need to perform when enabling, configuring, and using Istio authentication policies. Find out more about
the underlying concepts in the [authentication overview](/docs/concepts/security/#authentication).

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/#authentication-policies) and related
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use `install/kubernetes/istio.yaml` as described in
[installation steps](/docs/setup/kubernetes/quick-start/#installation-steps), or set `global.mtls.enabled` to false using
[Helm](/docs/setup/kubernetes/helm-install/)).

### Setup

Our examples use two namespaces `foo` and `bar`, with two services, `httpbin` and `sleep`, both running with an Envoy sidecar proxy. We also use second
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
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

You should also verify that there are no existing authentication policies in the system, which you can do as follows:

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
No resources found.
{{< /text >}}

{{< text bash >}}
$ kubectl get meshpolicies.authentication.istio.io
No resources found.
{{< /text >}}

Last but not least, verify that there are no destination rules that apply on the example services. You can do this by checking the `host:` value of
 existing destination rules and make sure they do not match. For example:

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
    host: istio-policy.istio-system.svc.cluster.local
    host: istio-telemetry.istio-system.svc.cluster.local
{{< /text >}}

> Depending on the version of Istio, you may see destination rules for hosts other then those shown. However, there should be none with hosts in the `foo`,
`bar` and `legacy` namespace, nor is the match-all wildcard `*`

## Globally enabling Istio mutual TLS

To set a mesh-wide authentication policy that enables mutual TLS, submit *mesh authentication policy* like below:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

This policy specifies that all workloads in the mesh will only accept encrypted requests using TLS. As you can see, this authentication policy has the kind:
 `MeshPolicy`. The name of the policy must be `default`, and it contains no `targets` specification (as it is intended to apply to all services in the mesh).

At this point, only the receiving side is configured to use mutual TLS. If you run the `curl` command between *Istio services* (i.e those with sidecars), all
 requests will fail with a 503 error code as the client side is still using plain-text.

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 503
sleep.foo to httpbin.bar: 503
sleep.bar to httpbin.foo: 503
sleep.bar to httpbin.bar: 503
{{< /text >}}

To configure the client side, you need to set [destination rules](/docs/concepts/traffic-management/#rule-destinations) to use mutual TLS. It's possible to use
multiple destination rules, one for each applicable service (or namespace). However, it's more convenient to use a rule with the `*` wildcard to match all
services so that it is on par with the mesh-wide authentication policy.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "default"
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

>
* Host value `*.local` to limit matches only to services in cluster, as opposed to external services. Also note, there is no restriction on the name or
namespace for destination rule.
* With `ISTIO_MUTUAL` TLS mode, Istio will set the path for key and certificates (e.g client certificate, private key and CA certificates) according to
its internal implementation.

Don’t forget that destination rules are also used for non-auth reasons such as setting up canarying, but the same order of precedence applies. So if a service
requires a specific destination rule for any reason - for example, for a configuration load balancer -  the rule must contain a similar TLS block with
`ISTIO_MUTUAL` mode, as otherwise it will override the mesh- or namespace-wide TLS settings and disable TLS.

Re-running the testing command as above, you will see all requests between Istio-services are now completed successfully:

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
{{< /text >}}

### Request from non-Istio services to Istio services

The non-Istio service, e.g `sleep.legacy` doesn't have a sidecar, so it cannot initiate the required TLS connection to Istio services. As a result,
requests from `sleep.legacy` to `httpbin.foo` or `httpbin.bar` will fail:

{{< text bash >}}
$ for from in "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

> Due to the way Envoy rejects plain-text requests, you will see `curl` exit code 56 (failure with receiving network data) in this case.

This works as intended, and unfortunately, there is no solution for this without reducing authentication requirements for these services.

### Request from Istio services to non-Istio services

Try to send requests to `httpbin.legacy` from `sleep.foo` (or `sleep.bar`). You will see requests fail as Istio configures clients as instructed in our
destination rule to use mutual TLS, but `httpbin.legacy` does not have a sidecar so it's unable to handle it.

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.legacy: 503
sleep.bar to httpbin.legacy: 503
{{< /text >}}

To fix this issue, we can add a destination rule to overwrite the TLS setting for `httpbin.legacy`. For example:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: "httpbin-legacy"
spec:
 host: "httpbin.legacy.svc.cluster.local"
 trafficPolicy:
   tls:
     mode: DISABLE
EOF
{{< /text >}}

### Request from Istio services to Kubernetes API server

The Kubernetes API server doesn't have a sidecar, thus request from Istio services such as `sleep.foo` will fail due to the same problem as when sending
requests to any non-Istio service.

{{< text bash >}}
$ TOKEN=$(kubectl describe secret $(kubectl get secrets | grep default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t')
kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- $ curl https://kubernetes.default/api --header "Authorization: Bearer $TOKEN" --insecure -s -o /dev/null -w "%{http_code}\n"
000
command terminated with exit code 35
{{< /text >}}

Again, we can correct this by overriding the destination rule for the API server (`kubernetes.default`)

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: "api-server"
spec:
 host: "kubernetes.default.svc.cluster.local"
 trafficPolicy:
   tls:
     mode: DISABLE
EOF
{{< /text >}}

> If you install Istio with [default mutual TLS option](/docs/setup/kubernetes/quick-start/#option-2-install-istio-with-default-mutual-tls-authentication),
this rule, together with the global authentication policy and destination rule above will be injected to the system during installation process.

Re-run the testing command above to confirm that it returns 200 after the rule is added:

{{< text bash >}}
$ TOKEN=$(kubectl describe secret $(kubectl get secrets | grep default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t')
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl https://kubernetes.default/api --header "Authorization: Bearer $TOKEN" --insecure -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### Cleanup part 1

Remove global authentication policy and destination rules added in the session:

{{< text yaml >}}
$ kubectl delete meshpolicy default
$ kubectl delete destinationrules default httpbin-legacy api-server
{{< /text >}}

## Enable mutual TLS per namespace or service

In addition to specifying an authentication policy for your entire mesh, Istio also lets you specify policies for particular namespaces or services. A
namespace-wide policy takes precedence over the mesh-wide policy, while a service-specific policy has higher precedence still.

### Namespace-wide policy

The example below shows the policy to enable mutual TLS for all services in namespace `foo`. As you can see, it uses kind: "Policy” rather than "MeshPolicy”,
and specifies a namespace, in this case, `foo`. If you don’t specify a namespace value the policy will apply to the default namespace.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "default"
  namespace: "foo"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

> Similar to *mesh-wide policy*, namespace-wide policy must be named `default`, and doesn't restrict any specific service (no `targets` section)

Add corresponding destination rule:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "foo"
spec:
  host: "*.foo.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

> Host `*.foo.svc.cluster.local` limits the matches to services in `foo` namespace only.

As these policy and destination rule are applied on services in namespace `foo` only, you should see only request from client-without-sidecar (`sleep.legacy`) to `httpbin.foo` start to fail.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
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

### Service-specific policy

You can also set authentication policy and destination rule for a specific service. Run this command to set another policy only for `httpbin.bar` service.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls: {}
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

>
* In this example, we do **not** specify namespace in metadata but put it in the command line (`-n bar`), which has an identical effect.
* There is no restriction on the authentication policy and destination rule name. This example uses the name of the service itself for simplicity.

Again, run the probing command. As expected, request from `sleep.legacy` to `httpbin.bar` starts failing with the same reasons.

{{< text plain >}}
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

If we have more services in namespace `bar`, we should see traffic to them won't be affected. Instead of adding more services to demonstrate this behavior,
we edit the policy slightly to apply on a specific port:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
    ports:
    - number: 1234
  peers:
  - mtls: {}
EOF
{{< /text >}}

And a corresponding change to the destination rule:

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
      mode: DISABLE
    portLevelSettings:
    - port:
        number: 1234
      tls:
        mode: ISTIO_MUTUAL
EOF
{{< /text >}}

This new policy will apply only to the `httpbin` service on port `1234`. As a result, mutual TLS is disabled (again) on port `8000` and requests from
`sleep.legacy` will resume working.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### Policy precedence

To illustrate how a service-specific policy takes precedence over namespace-wide policy, you can add a policy to disable mutual TLS for `httpbin.foo` as below.
Note that you've already created a namespace-wide policy that enables mutual TLS for all services in namespace `foo` and observe that requests from
`sleep.legacy` to `httpbin.foo` are failing (see above).

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "overwrite-example"
spec:
  targets:
  - name: httpbin
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
$ kubectl delete policy default overwrite-example -n foo
$ kubectl delete policy httpbin -n bar
$ kubectl delete destinationrules default overwrite-example -n foo
$ kubectl delete destinationrules httpbin -n bar
{{< /text >}}

## End-user authentication

To experiment with this feature, you need a valid JWT. The JWT must correspond to the JWKS endpoint you want to use for the demo. In
this tutorial, we use this [JWT test]({{< github_file >}}/security/tools/jwt/samples/demo.jwt) and this
[JWKS endpoint]({{< github_file >}}/security/tools/jwt/samples/jwks.json) from the Istio code base.

Also, for convenience, expose `httpbin.foo` via `ingressgateway` (for more details, see the [ingress task](/docs/tasks/traffic-management/ingress/)).

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
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
$ cat <<EOF | kubectl apply -f -
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

Now, add a policy that requires end-user JWT for `httpbin.foo`. The next command assumes there is no service-specific policy for `httpbin.foo` (which should
be the case if you run [cleanup](#cleanup-part-2) as described). You can run `kubectl get policies.authentication.istio.io -n foo` to confirm.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "jwt-example"
spec:
  targets:
  - name: httpbin
  origins:
  - jwt:
      issuer: "testing@secure.istio.io"
      jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

The same curl command from before will return with 401 error code, as a result of server is expecting JWT but none was provided:

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

Attaching the valid token generated above returns success:

{{< text bash>}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

To observe other aspects of JWT validation, use the script [`gen-jwt.py`]({{< github_tree >}}/security/tools/jwt/samples/gen-jwt.py) to
generate new tokens to test with different issuer, audiences, expiry date, etc. For example, the command below creates a token that
expires in 5 seconds. As you see, Istio authenticates requests using that token successfully at first but rejects them after 5 seconds:

{{< text bash >}}
$ TOKEN=$(@security/tools/jwt/samples/gen-jwt.py@ @security/tools/jwt/samples/key.pem@ --expire 5)
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

### End-user authentication with mutual TLS

End-user authentication and mutual TLS can be used together. Modify the policy above to define both mutual TLS and end-user JWT authentication:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "jwt-example"
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

> Use `istio create` if the `jwt-example` policy hasn't been submitted.

And add a destination rule:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
  namespace: "foo"
spec:
  host: "httpbin.foo.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

> If you already enable mutual TLS mesh-wide or namespace-wide, the host `httpbin.foo` is already covered by the other destination rule.
Therefore, you do not need adding this destination rule. On the other hand, you still need to add the `mtls` stanza to the authentication policy as the service-specific policy will override the mesh-wide (or namespace-wide) policy completely.

After these changes, traffic from Istio services, including ingress gateway, to `httpbin.foo` will use mutual TLS. The test command above will still work. Requests from Istio services directly to `httpbin.foo` also work, given the correct token:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
200
{{< /text >}}

However, requests from non-Istio services, which use plain-text will fail:

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
401
{{< /text >}}

### Cleanup part 3

1. Remove authentication policy:

    {{< text bash >}}
    $ kubectl delete policy jwt-example
    {{< /text >}}

1. Remove destination rule:

    {{< text bash >}}
    $ kubectl delete policy httpbin
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, you can remove all resources simply by deleting test namespaces.

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    {{< /text >}}

---
title: Basic Authentication Policy
description: Shows you how to use Istio authentication policy to setup mutual TLS and basic end-user authentication.
weight: 10
keywords: [security,authentication]
aliases:
    - /docs/tasks/security/istio-auth.html
---

Through this task, you will learn how to:

* Use authentication policy to setup mutual TLS.

* Use authentication policy to do end-user authentication.

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/#anatomy-of-an-authentication-policy) and related [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use `install/kubernetes/istio.yaml` as described in [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/kubernetes/helm-install/)).

* For demo, create two namespaces `foo` and `bar`, and deploy [httpbin]({{< github_tree >}}/samples/httpbin) and [sleep]({{< github_tree >}}/samples/sleep) with sidecar on both of them. Also, run another httpbin and sleep app without sidecar (to keep it separate, run them in `legacy` namespace). In a regular system, a service can be both *server* (receiving traffic) for some services, and *client* for some others. For simplicity, in this demo, we only use `sleep` apps as clients, and `httpbin` as servers.

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

* Verifying setup by sending an HTTP request (using curl command) from any clients (i.e `sleep.foo`, `sleep.bar` and `sleep.legacy`) to any server (`httpbin.foo`, `httpbin.bar` or `httpbin.legacy`). All requests should success with HTTP code 200.

    For example, here is a command to check `sleep.bar` to `httpbin.foo` reachability:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    Conveniently, this one-liner command iterates through all combinations:

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

    > If you have `curl` installed on istio-proxy container, you can also verify that it can reach `httpbin` services in from proxy:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c istio-proxy -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

* Last but not least, verify that there are no authentication policy:

    {{< text bash >}}
    $ kubectl get meshpolicies.authentication.istio.io
    No resources found.
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get policies.authentication.istio.io --all-namespaces
    No resources found.
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrules.networking.istio.io --all-namespaces
    {{< /text >}}

    > You may see some policies and/or destination rules added by Istio installation, depends on installation mode. However, there should be none for `foo`, `bar` and `legacy` namespaces.

## Enable mutual TLS for all services in the mesh

To enable mutual TLS for all services in the mesh, you can submit *mesh authentication policy* and destination rule as below:

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

* Mesh-wide authentication policy name must be `default`; any policy with other name will be rejected and ignored. Also note that the CRD kind is `MeshPolicy`, which is different than the namespace-wide or service-specific policy kind (`Policy`)
* On the other hand, the destination rule can have any name, and in any namespace. For consistency, we use also name it `default` and keep in `default` namespace in this demo.
* Host value `*.local` in destination rule matches only services in the mesh, which have `local` suffix.
* With `ISTIO_MUTUAL` TLS mode, Istio will set the path for key and certificates (e.g `clientCertificate`, `privateKey` and `caCertificates`) according to its internal implementation.
* If you want to define a destination rule for a specific service, the TLS settings must be copied over to the new rule.

These authentication policy and destination rule effectively configures sidecars of all services to receive and send request in mutual TLS mode, respectively. However, it cannot be applied on services that don't have sidecar, i.e `httpbin.legacy` and `sleep.legacy` in this setup. If you run the same testing command as above, you should see requests from `sleep.legacy` to `httpbin.foo` and `httpbin.bar` start to fail, as the result of enabling mutual TLS on server, but `sleep.legacy` doesn't have a sidecar to support it. Similarly, requests from `sleep.foo` (or `sleep.bar`) to `httpbin.legacy` also fail.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 503
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 503
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

> The HTTP return code is not yet consistent. If request is sent in mutual TLS mode and server accept HTTP only, error code is 503. On the contrary, if request is sent in plain-text to server that use mutual TLS, the error code is  000 (with `curl` exit code 56, "failure with receiving network data").

To fix the connection from client-with-sidecar to server-without-sidecar, you can add destination rule specific for those server to overwrite TLS setting.

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
  namespace: "legacy"
spec:
  host: "httpbin.legacy.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

Retry sending requests to `httpbin.legacy`, all should work

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

> This approach can also be used to configure Kubernetes' API server, when mutual TLS is enabled globally. Following is an example configuration.

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "api-server"
  namespace: "default"
spec:
  host: "kubernetes.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

For the second issue, connection from client-without-sidecar to server-with-sidecar (in mutual TLS mode), the only option is to drop mutual TLS to `PERMISSIVE` mode, which allows server to accept traffic in either HTTP or (mutual) TLS. This, obviously, will reduce security level, and is recommended to use during migration only. To do so, you can change the *mesh policy* (adding `mode: PERMISSIVE` under `mtls` block). A more conservative (and recommended) way is creating new policy only for the specific service(s) needed. The example below illustrates the latter:

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
  namespace: "foo"
spec:
  targets:
  - name: "httpbin"
  peers:
  - mtls:
      mode: PERMISSIVE
EOF
{{< /text >}}

Request from `sleep.legacy` to `httpbin.foo` should succeed, while to `httpbin.bar` still fail.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
000
{{< /text >}}

Before move on the next section, let's remove authentication policies and destination rules created in this section

{{< text bash >}}
$ kubectl delete meshpolicy.authentication.istio.io default
$ kubectl delete policy.authentication.istio.io -n foo --all
$ kubectl delete destinationrules.networking.istio.io default
$ kubectl delete destinationrules.networking.istio.io -n legacy --all
{{< /text >}}

## Enable mutual TLS for all services in a namespace

Instead of enabling mutual TLS globally, you can do it per namespace. The process is similar, except the policy is in namespace-scope (kind `Policy`)

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
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
$ cat <<EOF | istioctl create -f -
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

## Enable mutual TLS for single service `httpbin.bar`

You can also set authentication policy and destination rule for a specific service. Run this command to set another policy only for `httpbin.bar` service.

{{< text bash >}}
$ cat <<EOF | istioctl create -n bar -f -
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
$ cat <<EOF | istioctl create -n bar -f -
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

> In this example, we do **not** specify namespace in metadata but put it in the command line (`-n bar`). They should work the same.
> There is no restriction on the authentication policy and destination rule name. The example use the name of the service itself for simplicity.

Again, run the probing command. As expected, request from `sleep.legacy` to `httpbin.bar` starts failing with the same reasons.

{{< text plain >}}
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

If we have more services in namespace `bar`, we should see traffic to them won't be affected. Instead of adding more services to demonstrate this behavior, we edit the policy slightly to apply on a specific port:

{{< text bash >}}
$ cat <<EOF | istioctl replace -n bar -f -
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
  - mtls:
EOF
{{< /text >}}

And a corresponding change to the destination rule:

{{< text bash >}}
$ cat <<EOF | istioctl replace -n bar -f -
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

This new policy will apply only to the `httpbin` service on port `1234`. As a result, mutual TLS is disabled (again) on port `8000` and requests from `sleep.legacy` will resume working.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

## Having both namespace-level and service-level policies

Assuming we already added the namespace-level policy that enables mutual TLS for all services in namespace `foo` and observe that request from `sleep.legacy` to `httpbin.foo` are failing (see above). Now add another policy that disables mutual TLS (peers section is empty) specifically for the `httpbin` service:

{{< text bash >}}
$ cat <<EOF | istioctl create -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-3"
spec:
  targets:
  - name: httpbin
EOF
{{< /text >}}

and destination rule:

{{< text bash >}}
$ cat <<EOF | istioctl create -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "example-3"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

Re-run the request from `sleep.legacy`, we should see a success return code again (200), confirming service-level policy overrules the namespace-level policy.

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

## Setup end-user authentication

You will need a valid JWT (corresponding to the JWKS endpoint you want to use for the demo). Please follow the instructions [here]({{< github_tree >}}/security/tools/jwt) to create one. You can also use your own JWT/JWKS endpoint for the demo. Once you have that, export to some environment variables.

{{< text bash >}}
$ export SVC_ACCOUNT="example@my-project.iam.gserviceaccount.com"
$ export JWKS=https://www.googleapis.com/service_accounts/v1/jwk/${SVC_ACCOUNT}
$ export TOKEN=<YOUR-TOKEN>
{{< /text >}}

Also, for convenience, expose `httpbin.foo` via ingress (for more details, see [ingress task](/docs/tasks/traffic-management/ingress/)).

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: httpbin-ingress
  namespace: foo
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  rules:
  - http:
      paths:
      - path: /headers
        backend:
          serviceName: httpbin
          servicePort: 8000
EOF
{{< /text >}}

Get ingress IP

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get ing -n foo -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
{{< /text >}}

And run a test query

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

Now, let's add a policy that requires end-user JWT for `httpbin.foo`. The next command assumes policy with name "httpbin" already exists (which should be if you follow previous sections). You can run `kubectl get policies.authentication.istio.io -n foo` to confirm, and use `istio create` (instead of `istio replace`) if resource is not found. Also note in this policy, peer authentication (mutual TLS) is also set, though it can be removed without affecting origin authentication settings.

{{< text bash >}}
$ cat <<EOF | istioctl replace -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-3"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
  origins:
  - jwt:
      issuer: $SVC_ACCOUNT
      jwksUri: $JWKS
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

The same curl command from before will return with 401 error code, as a result of server is expecting JWT but none was provided:

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

Attaching the valid token generated above returns success:

{{< text bash >}}
$ curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

You may want to try to modify token or policy (e.g change issuer, audiences, expiry date etc) to observe other aspects of JWT validation.

## Cleanup

Remove all resources.

{{< text bash >}}
$ kubectl delete ns foo bar legacy
{{< /text >}}

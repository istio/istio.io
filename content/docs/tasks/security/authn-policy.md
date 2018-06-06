---
title: Basic Authentication Policy
description: Shows you how to use Istio authentication policy to setup mutual TLS and basic end-user authentication.
weight: 10
aliases:
    - /docs/tasks/security/istio-auth.html
---

Through this task, you will learn how to:

* Use authentication policy to setup mutual TLS.

* Use authentication policy to do end-user authentication.

## Before you begin

* Understand Istio [authentication policy](/docs/concepts/security/authn-policy/) and related [mutual TLS authentication](/docs/concepts/security/mutual-tls/) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (e.g use `install/kubernetes/istio-demo.yaml` as described in [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/kubernetes/helm-install/)).

*   For demo, create two namespaces `foo` and `bar`, and deploy [httpbin](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/httpbin) and [sleep](https://github.com/istio/istio/tree/master/samples/sleep) with sidecar on both of them. Also, run another sleep app without sidecar (to keep it separate, run it in `legacy` namespace)

    ```command
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
    ```

*   Verifying setup by sending an http request (using curl command) from any sleep pod (among those in namespace `foo`, `bar` or `legacy`) to either `httpbin.foo` or `httpbin.bar`. All requests should success with HTTP code 200.

    For example, here is a command to check `sleep.bar` to `httpbin.foo` reachability:

    ```command
    $ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    ```

    Conveniently, this one-liner command iterates through all combinations:

    ```command
    $ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
    sleep.foo to httpbin.foo: 200
    sleep.foo to httpbin.bar: 200
    sleep.bar to httpbin.foo: 200
    sleep.bar to httpbin.bar: 200
    sleep.legacy to httpbin.foo: 200
    sleep.legacy to httpbin.bar: 200
    ```

*   Also verify that there are no authentication policy in the system

    ```command
    $ kubectl get policies.authentication.istio.io --all-namespaces
    No resources found.
    ```

## Enable mutual TLS for all services in a namespace

Run this command to set namespace-level policy for namespace `foo`.

```bash
cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "foo"
spec:
  peers:
  - mtls:
EOF
```

And verify the policy was added:

```command
$ kubectl get policies.authentication.istio.io -n foo
NAME          AGE
enable-mtls   1m
```

Add this destination rule to configure client side to use mutual TLS:

```bash
cat <<EOF | istioctl create -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "example-1"
  namespace: "foo"
spec:
  host: "*.foo.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```

> Note:
* This rule is based on the assumption that there is no other destination rule in the system. If it's not the case, you need to modify traffic policy in existing rules accordingly.
* `*.foo.svc.cluster.local` matches all services in namespace `foo`.
* With `ISTIO_MUTUAL` TLS mode, Istio will set the path for key and certificates (e.g `clientCertificate`, `privateKey` and `caCertificates`) according to its internal implementation.

Run the same testing command as above. You should see requests from `sleep.legacy` to `httpbin.foo` start to fail, as the result of enabling mutual TLS for `httpbin.foo` but `sleep.legacy` doesn't have a sidecar to support it. On the other hand, for clients with sidecar (`sleep.foo` and `sleep.bar`), Istio automatically configures them to using mutual TLS where talking to `http.foo`, so they continue to work. Also, requests to `httpbin.bar` are not affected as the policy is only effective on the `foo` namespace.

```command
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
```

> If destination rule above is not created, all requests to `httpbin.foo` will fail as client side are not configured correctly to switch to use mutual TLS.

## Enable mutual TLS for single service `httpbin.bar`

Run this command to set another policy only for `httpbin.bar` service. Note in this example, we do **not** specify namespace in metadata but put it in the command line (`-n bar`). They should work the same.

```bash
cat <<EOF | istioctl create -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-2"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
EOF
```

And a destination rule:

```bash
cat <<EOF | istioctl create -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "example-2"
spec:
  host: "httpbin.bar.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
```

Again, run the probing command. As expected, request from `sleep.legacy` to `httpbin.bar` starts failing with the same reasons.

```plain
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
```

If we have more services in namespace `bar`, we should see traffic to them won't be affected. Instead of adding more services to demonstrate this behavior, we edit the policy slightly:

```bash
cat <<EOF | istioctl replace -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-2"
spec:
  targets:
  - name: httpbin
    ports:
    - number: 1234
  peers:
  - mtls:
EOF
```

And a corresponding change to the destination rule:

```bash
cat <<EOF | istioctl replace -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "example-2"
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
```

This new policy will apply only to the `httpbin` service on port `1234`. As a result, mutual TLS is disabled (again) on port `8000` and requests from `sleep.legacy` will resume working.

```command
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
```

## Having both namespace-level and service-level policies

Assuming we already added the namespace-level policy that enables mutual TLS for all services in namespace `foo` and observe that request from `sleep.legacy` to `httpbin.foo` are failing (see above). Now add another policy that disables mutual TLS (peers section is empty) specifically for the `httpbin` service:

```bash
cat <<EOF | istioctl create -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-3"
spec:
  targets:
  - name: httpbin
EOF
```

and destination rule:

```bash
cat <<EOF | istioctl create -n foo -f -
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
```

Re-run the request from `sleep.legacy`, we should see a success return code again (200), confirming service-level policy overrules the namespace-level policy.

```command
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
```

## Setup end-user authentication

You will need a valid JWT (corresponding to the JWKS endpoint you want to use for the demo). Please follow the instructions [here](https://github.com/istio/istio/blob/{{<branch_name>}}/security/tools/jwt) to create one. You can also use your own JWT/JWKS endpoint for the demo. Once you have that, export to some environment variables.

```command
$ export SVC_ACCOUNT="example@my-project.iam.gserviceaccount.com"
$ export JWKS=https://www.googleapis.com/service_accounts/v1/jwk/${SVC_ACCOUNT}
$ export TOKEN=<YOUR-TOKEN>
```

Also, for convenience, expose `httpbin.foo` via ingress (for more details, see [ingress task](/docs/tasks/traffic-management/ingress/)).

```bash
cat <<EOF | kubectl apply -f -
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
```

Get ingress IP
```command
export INGRESS_HOST=$(kubectl get ing -n foo -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
```

And run a test query

```command
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
```

Now, let's add a policy that requires end-user JWT for `httpbin.foo`. The next command assumes policy with name "httpbin" already exists (which should be if you follow previous sections). You can run `kubectl get policies.authentication.istio.io -n foo` to confirm, and use `istio create` (instead of `istio replace`) if resource is not found. Also note in this policy, peer authentication (mutual TLS) is also set, though it can be removed without affecting origin authentication settings.

```bash
cat <<EOF | istioctl replace -n foo -f -
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
```

The same curl command from before will return with 401 error code, as a result of server is expecting JWT but none was provided:

```command
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
401
```

Attaching the valid token generated above returns success:

```command
$ curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
```

You may want to try to modify token or policy (e.g change issuer, audiences, expiry date etc) to observe other aspects of JWT validation.

## What's next

* Learn more about verifying mutual TLS setup [testing Istio mutual TLS authentication](/docs/tasks/security/mutual-tls/)

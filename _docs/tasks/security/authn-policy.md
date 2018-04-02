---
title: Basic Istio authentication policy
overview: This task shows you how to use Istio authentication policy to setup mutual TLS and simple end-user authentication.

order: 10

layout: docs
type: markdown
---
{% include home.html %}

Through this task, you will learn how to:

* Using authentication policy to setup mutual TLS.

* Using authentication policy to end-user authentication.


## Before you begin

* Understand Isio [authentication policy]({{home}}/docs/concepts/security/authn-policy.html) and related [mutual TLS authentication]({{home}}/docs/concepts/security/mutual-tls.html) concepts.

* Know how to verify mTLS setup (recommend to walk through [testing Istio mutual TLS authentication]({{home}}/docs/tasks/security/mutual-tls.html))

* Have a Kubernetes cluster with Istio installed (either with or without mTLS, but preferred without as the tasks will show the way to enable mTLS with policy)

* For demo, create two namespaces 'foo' and 'bar', and deploy [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) and [sleep](https://github.com/istio/istio/tree/master/samples/sleep) with sidecar on both of them. Also, run another sleep without sidecar (to keep it separate, run it in 'legacy' namespace)

```
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject --debug -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject --debug -f samples/sleep/sleep.yaml) -n foo

kubectl create ns bar
kubectl apply -f <(istioctl kube-inject --debug -f samples/httpbin/httpbin.yaml) -n bar
kubectl apply -f <(istioctl kube-inject --debug -f samples/sleep/sleep.yaml) -n bar

kubectl create ns legacy
kubectl apply -f samples/sleep/sleep.yaml -n legacy

```

* Verifying setup. This probing command send an http request from each of (sleep.foo, sleep.bar, sleep.legacy) to each of (httpbin.foo, httpbin.bar). If Istio was installed without mTLS, all request should return with success code (200) (on the contrary, if Istio was install with mTLS, requests from sleep.legacy should fail).

```
for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
```

```
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.legacy to httpbin.foo: 200
sleep.legacy to httpbin.bar: 200
```

* Also verify that there are no authencation policy in the system

```
kubectl get policies.authentication.istio.io -n foo

kubectl get policies.authentication.istio.io -n bar
```

```
No resources found.
```

## Enable mTLS for all services in namespace "foo".

Run this command to set namespace-level policy for namespace foo.

```
cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "enable-mtls"
  namespace: "foo"
spec:
  peers:
  - mtls:
EOF  
```

And verify policy is added:
```
kubectl get policies.authentication.istio.io -n foo
```

```
NAME          AGE
enable-mtls   1m
```

Run the same probing command above. We should see request from sleep.legacy to httpbin.foo start to fail, as the result of mTLS is enabled for httpbin.foo but sleep.legacy doesn't have sidecar to support it. On the other hand, for clients with sidecar (sleep.foo and sleep.bar), Istio automatically config them to using mTLS where requesting http.foo, so they continue to work. Also, requests to "bar" namespace are not affected as policy is for "foo" namespace only.

```
for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
```

```
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
```

## Enable mTLS for single service httpbin.bar.

Run this command to set another policy for only for "httpbin" service on namespace "bar". Note in this example, we don't specify namespace in metadata but as part of the commandline (-n bar). They should work the same.

```
cat <<EOF | istioctl create -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "enable-mtls"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
EOF  
```

Again, run the probing command. As expected, request from sleep.legacy to httpbin.bar starts failing.

```
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
```

If we have other services namespace bar, we should see traffic to them won't be affected. Instead of adding more services to demonstrate this behavior, we edit the policy sligthtly:

```
cat <<EOF | istioctl replace -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "enable-mtls"
spec:
  targets:
  - name: httpbin
    ports:
    - number: 1234
  peers:
  - mtls:
EOF
```

This new policy will apply only to httpbin on port 1234. As the result, mTLS is disabled (again) on port 8000 and request from sleep.legacy will success

```
kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
```

```
200
```

## Having both namespace-level and service-level policy.

Assuming we already add the namespace-level policy that enable mTLS for all services in namespace foo and observe that request from sleep.legacy to httpbin.foo are failing (see above). Now add another policy for httpbin service directly. This poicy doesn't define any method for peer authentication, which equivalent to disable mTLS.

```
cat <<EOF | istioctl create -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
EOF
```

Re-run request from sleep.legacy, we should see success return code again (200), confirming service-level policy is overrule the namespace-level policy.

```
kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
```

```
200
```


## Setup end-user Authentication

You will need a valid JWT (corresponding to the JWKS endpoint you want to use for the demo). Please follow the instruction [here](https://github.com/istio/istio/tree/master/security/tools/jwt) to create one. You can also use your own JWT/JWKS endpoint for the demo. Once you have that, let's export to some enviroment variables.


```
export JWKS=https://www.googleapis.com/service_accounts/v1/jwk/<YOUR-SVC-ACCOUNT>
export TOKEN=<YOUR-TOKEN>
```

Also, for convenience, let expose httpbin.foo via ingress (for more details, see [ingress task]({{home}}/docs/tasks/traffic-management/ingress.html)).

```
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
```
export INGRESS_HOST=$(kubectl get ing -n foo -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
```

And run test query
```
curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
```

```
{
  "headers": {
    "Accept": "*/*",
    "Content-Length": "0",
    "Host": "35.230.123.105",
    "User-Agent": "curl/7.58.0",
    "X-B3-Sampled": "1",
    "X-B3-Spanid": "d729acfa46c072ba",
    "X-B3-Traceid": "d729acfa46c072ba",
    "X-Envoy-Internal": "true",
    "X-Ot-Span-Context": "d729acfa46c072ba;d729acfa46c072ba;0000000000000000",
    "X-Request-Id": "8f232322-7c73-9470-8481-5ab64233adf9"
  }
}
```

Now, let's add a policy that require end-user JWT for httpbin.foo. If you follow previous section, the 'httpbin' authentication policy might areadly exist (run `kubectl get policies.authentication.istio.io -n foo` to confirm). To avoid create conflicting policies for the same service, we run istio replace for the same policy name (httpbin). Note in the example policy below, peer authentication (mTLS) is kept, but it can be removed independently from origin authencation settings.

```
cat <<EOF | istioctl replace -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls:
  origins:
  - jwt:
      issuer: "https://www.googleapis.com"
      jwksUri: $JWKS
  principalBinding: USE_ORIGIN
EOF  
```

The same curl command before will return with 401 error code now:
```
curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
```
```
401
```

But will success (200) if token is attached to query.
```
curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
```


You may want to try to modify the policy (e.g change issuer, add audiences etc) to observe other authentication result.
